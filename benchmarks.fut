import "lib/github.com/diku-dk/sorts/radix_sort"
import "lib/github.com/diku-dk/containers/hashmap"
import "lib/github.com/diku-dk/containers/arraymap"
import "lib/github.com/diku-dk/containers/eytzinger"
import "lib/github.com/diku-dk/containers/key"
import "lib/github.com/diku-dk/containers/opt"
import "lib/github.com/diku-dk/cpprandom/random"

module engine = xorshift128plus

module two_level_hashmap = mk_two_level_hashmap i64key engine
type~ two_level 't = two_level_hashmap.map () [] [] t

entry bench_two_level_construct [n] (keys: [n]i64) (vals: [n]i32) : two_level i32 =
  two_level_hashmap.from_array_nodup () (zip keys vals)

entry bench_two_level_lookup [n] (hm: two_level i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (two_level_hashmap.lookup () x hm)) keys

module linear_hashmap = mk_linear_hashmap i64key engine
type~ linear 't = linear_hashmap.map [] t

entry bench_linear_construct [n] (keys: [n]i64) (vals: [n]i32) : linear i32 =
  linear_hashmap.from_array () (zip keys vals)

entry bench_linear_lookup [n] (hm: linear i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (linear_hashmap.lookup () x hm)) keys

module binary_search = mk_arraymap i64key
type~ sorted_array 't = binary_search.map [] t

entry bench_sorted_array_construct [n] (keys: [n]i64) (vals: [n]i32) : sorted_array i32 =
  binary_search.from_array_nodup () (zip keys vals)

entry bench_sorted_array_lookup [n] (hm: sorted_array i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (binary_search.lookup () x hm)) keys

module eytzinger = mk_eytzinger i64key
type~ eytzinger_tree 't = eytzinger.map [] t

entry bench_eytzinger_tree_construct [n] (keys: [n]i64) (vals: [n]i32) : eytzinger_tree i32 =
  eytzinger.from_array_nodup () (zip keys vals)

entry bench_eytzinger_tree_lookup [n] (hm: eytzinger_tree i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (eytzinger.lookup () x hm)) keys

-- ==
-- entry: bench_two_level_construct bench_linear_construct bench_sorted_array_construct bench_eytzinger_tree_construct
-- "n=1000000"
-- script input { ($loaddata "data/1000000_i64.keys", $loaddata "data/1000000_i32.vals") }
-- "n=10000000"
-- script input { ($loaddata "data/10000000_i64.keys", $loaddata "data/10000000_i32.vals") }

-- ==
-- entry: bench_two_level_lookup
-- "n=1000000"
-- script input { (bench_two_level_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_two_level_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_linear_lookup
-- "n=1000000"
-- script input { (bench_linear_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_linear_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_sorted_array_lookup
-- "n=1000000"
-- script input { (bench_sorted_array_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_sorted_array_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_eytzinger_tree_lookup
-- "n=1000000"
-- script input { (bench_eytzinger_tree_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_eytzinger_tree_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }
