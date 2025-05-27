
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

#include "data.hpp"
#include "timing.hpp"

using Key   = int64_t;
using Value = int;


template <typename MapRef, typename InputIterator, typename OutputIterator>
__global__ void scalar_find(MapRef set, InputIterator keys, std::size_t n, OutputIterator found) {
  int64_t i = blockDim.x * blockIdx.x + threadIdx.x;

  if (i < n) {
    auto [j, val] = *set.find(*(keys + i));
    found[i] = val;
  }
}

int main(int argc, char** argv) {
  if (argc != 3) {
    std::cerr << "Usage: " << argv[0] << " KEYS VALUES" << std::endl;
    return 1;
  }

  const char *keys_fname = argv[1];
  const char *vals_fname = argv[2];

  auto [keys, keys_shape] = read_futhark_array<int64_t,1>(keys_fname);
  auto [vals, vals_shape] = read_futhark_array<int32_t,1>(vals_fname);


  if (keys_shape[0] != vals_shape[0]) {
    throw std::runtime_error("Mismatch in number of keys and values");
  }

  Key constexpr empty_key_sentinel     = -1;
  Value constexpr empty_value_sentinel = -1;

  std::size_t num_keys = keys.size();

  std::cout << "n=" << num_keys << std::endl;

  auto constexpr load_factor = 0.5;
  std::size_t const capacity = std::ceil(num_keys / load_factor);

  auto map = cuco::static_map{
    capacity,
    cuco::empty_key{empty_key_sentinel},
    cuco::empty_value{empty_value_sentinel},
    cuda::std::equal_to<Key>(),
    cuco::linear_probing<1,cuco::default_hash_function<Key>>()
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
}
