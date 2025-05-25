
#include <cuco/static_map.cuh>

#include <thrust/device_vector.h>
#include <thrust/equal.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/transform_iterator.h>
#include <thrust/sequence.h>
#include <thrust/transform.h>

#include <cmath>
#include <cstddef>
#include <iostream>
#include <limits>

#include "data.hpp"
#include "timing.hpp"

int main(int argc, char** argv) {
  using Key   = int64_t;
  using Value = int;

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
    cuco::empty_value{empty_value_sentinel}
  };

  thrust::device_vector<Key> insert_keys(num_keys);
  thrust::sequence(keys.begin(), keys.end(), 0);
  thrust::device_vector<Value> insert_values(num_keys);
  thrust::sequence(vals.begin(), vals.end(), 0);
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
    return 1;
  }
}
