
#include <cuco/static_map.cuh>

#include <thrust/device_vector.h>
#include <thrust/equal.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/transform_iterator.h>
#include <thrust/sequence.h>
#include <thrust/transform.h>

#include <cooperative_groups.h>

#include <cmath>
#include <cstddef>
#include <iostream>
#include <limits>
#include <fstream>
#include <sstream>

#include "data.hpp"
#include "timing.hpp"

struct __attribute__((packed)) tuple {
  int32_t start_index;
  int32_t length;

  constexpr __host__ __device__ tuple() : start_index(-1), length(-1) {}
  constexpr __host__ __device__ tuple(int32_t start, int32_t len) : start_index(start), length(len) {}
};

// Key which specifies the starting index and the length of a string
using Key   = tuple;
using Value = int;

// Function which takes a string where every line is a key and returns the keys
// based on the starting index and length of the string.
thrust::device_vector<Key> readFileToDeviceVector(const std::string& string) {
  std::istringstream stream(string);
  std::string line;

  thrust::device_vector<Key> keys;
  int32_t start_index = 0;

  while (std::getline(stream, line)) {
    if (line.empty()) continue;
    int32_t length = line.size();
    keys.push_back(Key(start_index, length));
    start_index += length + 1;
  }

  return keys;
}

// Function that reads a file and returns its contents as a char pointer.
std::string readFile(const char* filename) {
  std::ifstream file(filename, std::ios::binary);
  if (!file) {
    throw std::runtime_error("Failed to open file: " + std::string(filename));
  }
  std::ostringstream oss;
  oss << file.rdbuf();
  return oss.str();
}

struct hash_key {
  const char* string_keys;
  __host__ __device__ hash_key(const char* keys) : string_keys(keys) {}

  __host__ __device__ std::uint32_t operator()(Key const& key) const noexcept {
    int64_t start_index = key.start_index;
    int64_t length = key.length;
    std::uint32_t hash = 2166136261;

    for (int64_t i = 0; i < length; ++i) {
      char c = string_keys[start_index + i];
      hash = (hash * 16777619) ^ static_cast<std::uint32_t>(c);
    }
    return hash;
  }
};

struct equal_key {
  const char* string_keys;
  __host__ __device__ equal_key(const char* keys) : string_keys(keys) {}

  __device__ bool operator()(Key const& a, Key const& b) const {
    if (a.length != b.length) {
      return false;
    }
    
    bool result = true;
    for (int32_t i = 0; i < a.length; ++i) {
      result &= string_keys[a.start_index + i] == string_keys[b.start_index + i]; 
    }
    return result;
  }
};

template <typename MapRef, typename InputIterator, typename OutputIterator>
__global__ void scalar_find(MapRef set, InputIterator keys, std::size_t n, OutputIterator found) {
  int64_t i = blockDim.x * blockIdx.x + threadIdx.x;

  if (i < n) {
    auto [j, val] = *set.find(*(keys + i));
    found[i] = val;
  }
}

template <typename MapRef, typename InputIterator, typename OutputIterator>
__global__ void scalar_contains(MapRef set, InputIterator keys, std::size_t n, OutputIterator found) {
  int64_t i = blockDim.x * blockIdx.x + threadIdx.x;

  if (i < n) {
    bool b = set.contains(*(keys + i));
    found[i] = b;
  }
}

int main(int argc, char** argv) {
  if (argc != 3) {
    std::cerr << "Usage: " << argv[0] << " KEYS VALUES" << std::endl;
    return 1;
  }

  const char *keys_fname = argv[1];
  const char *vals_fname = argv[2];

  std::string string_keys = readFile(keys_fname);
  auto keys = readFileToDeviceVector(string_keys);
  auto keys_shape = keys.size();
  auto [vals, vals_shape] = read_futhark_array<int32_t,1>(vals_fname);

  char* d_string_keys;
  cudaMalloc(&d_string_keys, string_keys.size() + 1);
  cudaMemcpy(d_string_keys, string_keys.data(), string_keys.size() + 1, cudaMemcpyHostToDevice);

  if (keys_shape != vals_shape[0]) {
    throw std::runtime_error("Mismatch in number of keys and values");
  }

  Key constexpr empty_key_sentinel     = tuple();
  Value constexpr empty_value_sentinel = -1;

  std::size_t num_keys = keys.size();

  std::cout << "n=" << num_keys << std::endl;

  auto constexpr load_factor = 0.5;
  std::size_t const capacity = std::ceil(num_keys / load_factor);

  auto map = cuco::static_map{
    capacity,
    cuco::empty_key{empty_key_sentinel},
    cuco::empty_value{empty_value_sentinel},
    equal_key{d_string_keys},
    cuco::linear_probing<1, hash_key>{hash_key{d_string_keys}}
  };
  
  thrust::device_vector<Key> insert_keys(keys.begin(), keys.end());
  thrust::device_vector<Value> insert_values(vals.begin(), vals.end());
  auto pairs = thrust::make_transform_iterator
  (thrust::counting_iterator<std::size_t>{0},
  cuda::proclaim_return_type<cuco::pair<Key, Value>>
  ([keys = insert_keys.begin(), values = insert_values.begin()] __device__(auto i) {
    return cuco::pair<Key, Value>{keys[i], values[i]};
  }));
  
  int insertAvgTime = measureAverageExecutionTime
  (2.0,
  [&]() {
    map.clear();
    map.insert(pairs, pairs + num_keys);
    cudaDeviceSynchronize();
  });
  
  std::cout << "    construct: " << insertAvgTime << "μs" << std::endl;

    {
    thrust::device_vector<Value> found_values(num_keys);

    int lookupAvgTime = measureAverageExecutionTime
      (2.0,
       [&]() {
         map.find(insert_keys.begin(), insert_keys.end(), found_values.begin());
         cudaDeviceSynchronize();
       });

    std::cout << "       lookup: " << lookupAvgTime << "μs" << std::endl;

    bool const all_values_match =
      thrust::equal(found_values.begin(), found_values.end(), insert_values.begin());

    if (!all_values_match) {
      std::cerr << "Did not find all values." << std::endl;
      return 1;
    }
  }

  {
    thrust::device_vector<Value> found_values(num_keys);

    const size_t BLOCK_SIZE = 256;
    size_t grid_size = (num_keys + BLOCK_SIZE - 1) / BLOCK_SIZE;

    int scalarLookupAvgTime = measureAverageExecutionTime
      (2.0,
       [&]() {
         scalar_find<<<grid_size,BLOCK_SIZE>>>(map.ref(cuco::find), insert_keys.begin(), num_keys, found_values.begin());
         cudaDeviceSynchronize();
       });

    std::cout << "scalar lookup: " << scalarLookupAvgTime << "μs" << std::endl;

    bool const all_values_match =
      thrust::equal(found_values.begin(), found_values.end(), insert_values.begin());

    if (!all_values_match) {
      std::cerr << "Did not find all values." << std::endl;
      return 1;
    }
  }

  {
    thrust::device_vector<bool> exists(num_keys);

    int lookupAvgTime = measureAverageExecutionTime
      (2.0,
       [&]() {
         map.contains(insert_keys.begin(), insert_keys.end(), exists.begin());
         cudaDeviceSynchronize();
       });

    std::cout << "       member: " << lookupAvgTime << "μs" << std::endl;

    bool const all_values_match =
      thrust::reduce(exists.begin(), exists.end(), true, thrust::logical_and<bool>());

    if (!all_values_match) {
      std::cerr << "Did not find all values." << std::endl;
      return 1;
    }
  }

  {
    thrust::device_vector<bool> exists(num_keys);

    const size_t BLOCK_SIZE = 256;
    size_t grid_size = (num_keys + BLOCK_SIZE - 1) / BLOCK_SIZE;

    int scalarLookupAvgTime = measureAverageExecutionTime
      (2.0,
       [&]() {
         scalar_contains<<<grid_size,BLOCK_SIZE>>>(map.ref(cuco::contains), insert_keys.begin(), num_keys, exists.begin());
         cudaDeviceSynchronize();
       });

    std::cout << "scalar member: " << scalarLookupAvgTime << "μs" << std::endl;

    bool const all_values_match =
      thrust::reduce(exists.begin(), exists.end(), true, thrust::logical_and<bool>());

    if (!all_values_match) {
      std::cerr << "Did not find all values." << std::endl;
      return 1;
    }
  }

  cudaFree(d_string_keys);
}
