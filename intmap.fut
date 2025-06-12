import "lib/github.com/diku-dk/sorts/radix_sort"
import "lib/github.com/diku-dk/containers/hashmap"
import "lib/github.com/diku-dk/containers/arraymap"
import "lib/github.com/diku-dk/containers/eytzinger"
import "lib/github.com/diku-dk/containers/key"
import "lib/github.com/diku-dk/containers/opt"
import "lib/github.com/diku-dk/cpprandom/random"

module engine = xorshift128plus

module two_level_hashmap = mk_hashmap i64key engine
type~ two_level 't = ?[n].two_level_hashmap.map [n] t

entry bench_two_level_construct [n] (keys: [n]i64) (vals: [n]i32) : two_level i32 =
  two_level_hashmap.from_array_nodup () (zip keys vals)

entry bench_two_level_lookup [n] (hm: two_level i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (two_level_hashmap.lookup () x hm)) keys

entry bench_two_level_member [n] (hm: two_level i32) (keys: [n]i64) =
  map (\x -> two_level_hashmap.member () x hm) keys

module engine_u32 = minstd_rand

module two_level_hashmap_u32 = mk_hashmap_u32 i64key_u32 engine_u32
type~ two_level_u32 't = ?[n].two_level_hashmap_u32.map [n] t

entry bench_two_level_u32_construct [n] (keys: [n]i64) (vals: [n]i32) : two_level_u32 i32 =
  two_level_hashmap_u32.from_array_nodup () (zip keys vals)

entry bench_two_level_u32_lookup [n] (hm: two_level_u32 i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (two_level_hashmap_u32.lookup () x hm)) keys

entry bench_two_level_u32_member [n] (hm: two_level_u32 i32) (keys: [n]i64) =
  map (\x -> two_level_hashmap_u32.member () x hm) keys

module linear_hashmap = mk_linear_hashmap i64key engine
type~ linear 't = linear_hashmap.map [] t

entry bench_linear_construct [n] (keys: [n]i64) (vals: [n]i32) : linear i32 =
  linear_hashmap.from_array () (zip keys vals)

entry bench_linear_lookup [n] (hm: linear i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (linear_hashmap.lookup () x hm)) keys

entry bench_linear_member [n] (hm: linear i32) (keys: [n]i64) =
  map (\x -> linear_hashmap.member () x hm) keys

module binary_search = mk_arraymap i64key
type~ sorted_array 't = binary_search.map [] t

entry bench_binary_search_construct [n] (keys: [n]i64) (vals: [n]i32) : sorted_array i32 =
  binary_search.from_array_nodup () (zip keys vals)

entry bench_binary_search_lookup [n] (hm: sorted_array i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (binary_search.lookup () x hm)) keys

entry bench_binary_search_member [n] (hm: sorted_array i32) (keys: [n]i64) =
  map (\x -> binary_search.member () x hm) keys

module eytzinger = mk_eytzinger i64key
type~ eytzinger_tree 't = eytzinger.map [] t

entry bench_eytzinger_construct [n] (keys: [n]i64) (vals: [n]i32) : eytzinger_tree i32 =
  eytzinger.from_array_nodup () (zip keys vals)

entry bench_eytzinger_lookup [n] (hm: eytzinger_tree i32) (keys: [n]i64) =
  map (\x -> from_opt (-1) (eytzinger.lookup () x hm)) keys

entry bench_eytzinger_member [n] (hm: eytzinger_tree i32) (keys: [n]i64) =
  map (\x -> eytzinger.member () x hm) keys

-- ==
-- entry: bench_two_level_construct bench_two_level_u32_construct bench_linear_construct bench_binary_search_construct bench_eytzinger_construct
-- "n=100000"
-- script input { ($loaddata "data/100000_i64.keys", $loaddata "data/100000_i32.vals") }
-- "n=1000000"
-- script input { ($loaddata "data/1000000_i64.keys", $loaddata "data/1000000_i32.vals") }
-- "n=10000000"
-- script input { ($loaddata "data/10000000_i64.keys", $loaddata "data/10000000_i32.vals") }

-- ==
-- entry: bench_two_level_lookup
-- "n=100000"
-- script input { (bench_two_level_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_two_level_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_two_level_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_two_level_u32_lookup
-- "n=100000"
-- script input { (bench_two_level_u32_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_two_level_u32_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_two_level_u32_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_linear_lookup
-- "n=100000"
-- script input { (bench_linear_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_linear_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_linear_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_binary_search_lookup
-- "n=100000"
-- script input { (bench_binary_search_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_binary_search_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_binary_search_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_eytzinger_lookup
-- "n=100000"
-- script input { (bench_eytzinger_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_eytzinger_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_eytzinger_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_two_level_member
-- "n=100000"
-- script input { (bench_two_level_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_two_level_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_two_level_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_two_level_u32_member
-- "n=100000"
-- script input { (bench_two_level_u32_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_two_level_u32_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_two_level_u32_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_linear_member
-- "n=100000"
-- script input { (bench_linear_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_linear_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_linear_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_binary_search_member
-- "n=100000"
-- script input { (bench_binary_search_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_binary_search_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_binary_search_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }

-- ==
-- entry: bench_eytzinger_member
-- "n=100000"
-- script input { (bench_eytzinger_construct ($loaddata "data/100000_i64.keys") ($loaddata "data/100000_i32.vals"),
--                 ($loaddata "data/100000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_eytzinger_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_eytzinger_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }
