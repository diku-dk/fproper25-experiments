import "lib/github.com/diku-dk/sorts/radix_sort"
import "lib/github.com/diku-dk/containers/hashmap"
import "lib/github.com/diku-dk/containers/key"
import "lib/github.com/diku-dk/containers/opt"
import "lib/github.com/diku-dk/cpprandom/random"

module engine = xorshift128plus

module two_level_hashmap = mk_two_level_hashmap i64key engine
type~ two_level 't = two_level_hashmap.map () [] [] t

entry bench_two_level_construct [n] (keys: [n]i64) (vals: [n]i32) : two_level i32 =
  two_level_hashmap.unsafe_from_array () (zip keys vals)

entry bench_two_level_lookup [n] (hm: two_level i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (two_level_hashmap.lookup () x hm)) keys

module linear_hashmap = mk_linear_hashmap i64key engine
type~ linear 't = linear_hashmap.map [] t

entry bench_linear_construct [n] (keys: [n]i64) (vals: [n]i32) : linear i32 =
  linear_hashmap.from_array () (zip keys vals)

entry bench_linear_lookup [n] (hm: linear i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (linear_hashmap.lookup () x hm)) keys

-- ==
-- entry: bench_two_level_construct bench_linear_construct
-- "n=100000"
-- script input { ($loaddata "data/1000000_i64.keys", $loaddata "data/1000000_i32.vals") }
-- "n=1000000"
-- script input { ($loaddata "data/10000000_i64.keys", $loaddata "data/10000000_i32.vals") }

-- ==
-- entry: bench_two_level_lookup
-- "n=100000"
-- script input { (bench_two_level_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_two_level_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_linear_lookup
-- "n=100000"
-- script input { (bench_linear_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_linear_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }
