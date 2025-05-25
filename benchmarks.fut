import "lib/github.com/diku-dk/sorts/radix_sort"
import "lib/github.com/diku-dk/containers/hashmap"
import "lib/github.com/diku-dk/containers/key"
import "lib/github.com/diku-dk/cpprandom/random"

module engine = xorshift128plus
module hashmap = mk_hashmap i64key engine

entry bench_construct [n] (keys: [n]i64) (vals: [n]i32) : hashmap.map [] i32 =
  hashmap.from_array () (zip keys vals)

entry bench_lookup [n] (hm: hashmap.map [] i32) (keys: [n]i64) =
  map (\x -> hashmap.lookup () x hm) keys

-- ==
-- entry: bench_construct
-- "n=100000"
-- script input { ($loaddata "data/1000000_i64.keys", $loaddata "data/1000000_i32.vals") }
-- "n=1000000"
-- script input { ($loaddata "data/10000000_i64.keys", $loaddata "data/10000000_i32.vals") }
-- "n=10000000"
-- script input { ($loaddata "data/100000000_i64.keys", $loaddata "data/100000000_i32.vals") }

-- ==
-- entry: bench_lookup
-- "n=100000"
-- script input { (bench_construct ($loaddata "data/1000000_i64.keys") ($loaddata "data/1000000_i32.vals"),
--                 ($loaddata "data/1000000_i64.keys"))
--              }
-- "n=1000000"
-- script input { (bench_construct ($loaddata "data/10000000_i64.keys") ($loaddata "data/10000000_i32.vals"),
--                 ($loaddata "data/10000000_i64.keys"))
--              }
-- "n=10000000"
-- script input { (bench_construct ($loaddata "data/100000000_i64.keys") ($loaddata "data/100000000_i32.vals"),
--                 ($loaddata "data/100000000_i64.keys"))
--              }
