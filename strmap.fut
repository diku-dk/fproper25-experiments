import "lib/github.com/diku-dk/segmented/segmented"
import "lib/github.com/diku-dk/containers/hashmap"
import "lib/github.com/diku-dk/containers/arraymap"
import "lib/github.com/diku-dk/containers/array"
import "lib/github.com/diku-dk/containers/eytzinger"
import "lib/github.com/diku-dk/containers/key"
import "lib/github.com/diku-dk/containers/opt"
import "lib/github.com/diku-dk/containers/slice"
import "lib/github.com/diku-dk/cpprandom/random"

module engine = xorshift128plus
def seed = engine.rng_from_seed [1]

type char = u8
type~ str = []char

module strkey = mk_slice_key u8key (mk_encoder u8)
module strarray = mk_array_key strkey engine

module two_level_hashmap = mk_hashmap strkey engine
type~ two_level 't = two_level_hashmap.map [] t

def is_space (x: char) = x == '\n' || x == ' '
def isnt_space x = !(is_space x)

def (&&&) f g x = (f x, g x)

def words [n] (s: [n]char) =
  segmented_scan (+) 0 (map is_space s) (map (isnt_space >-> i64.bool) s)
  |> (id &&& rotate 1)
  |> uncurry zip
  |> zip (indices s)
  |> filter (\(i, (x, y)) -> (i == n - 1 && x > 0) || x > y)
  |> map (\(i, (x, _)) -> slice.mk (i - x + 1) x)

entry words_from_str (s: str) : []strkey.key = words s

entry bench_two_level_construct [n] (s: str) (keys: [n]strkey.key) (vals: [n]i32) : two_level i32 =
  two_level_hashmap.from_array_nodup s (zip keys vals)

entry bench_two_level_lookup [n] (s: str) (hm: two_level i32) (keys: [n]strkey.key) =
  map (\x -> from_opt (-1) (two_level_hashmap.lookup s x hm)) keys

entry bench_two_level_member [n] (s: str) (hm: two_level i32) (keys: [n]strkey.key) =
  map (\x -> two_level_hashmap.member s x hm) keys

module sorted_array = mk_arraymap strkey
type~ sorted_array 't = sorted_array.map [] t

entry bench_binary_search_construct [n] (s: str) (keys: [n]strkey.key) (vals: [n]i32) : sorted_array i32 =
  sorted_array.from_array_nodup s (zip keys vals)

entry bench_binary_search_lookup [n] (s: str) (hm: sorted_array i32) (keys: [n]strkey.key) =
  map (\x -> from_opt (-1) (sorted_array.lookup s x hm)) keys

entry bench_binary_search_member [n] (s: str) (hm: sorted_array i32) (keys: [n]strkey.key) =
  map (\x -> sorted_array.member s x hm) keys

module eytzinger = mk_eytzinger strkey
type~ eytzinger_tree 't = eytzinger.map [] t

entry bench_eytzinger_construct [n] (s: str) (keys: [n]strkey.key) (vals: [n]i32) : eytzinger_tree i32 =
  eytzinger.from_array_nodup s (zip keys vals)

entry bench_eytzinger_lookup [n] (s: str) (hm: eytzinger_tree i32) (keys: [n]strkey.key) =
  map (\x -> from_opt (-1) (eytzinger.lookup s x hm)) keys

entry bench_eytzinger_member [n] (s: str) (hm: eytzinger_tree i32) (keys: [n]strkey.key) =
  map (\x -> eytzinger.member s x hm) keys

-- ==
-- entry: bench_two_level_construct bench_binary_search_construct bench_eytzinger_construct
-- "n=100000"
-- script input { let s = $loadbytes "data/100000_words.txt"
--                in (s, words_from_str s, $loaddata "data/100000_i32.vals") }
-- "n=1000000"
-- script input { let s = $loadbytes "data/1000000_words.txt"
--                in (s, words_from_str s, $loaddata "data/1000000_i32.vals") }
-- "n=10000000"
-- script input { let s = $loadbytes "data/10000000_words.txt"
--                in (s, words_from_str s, $loaddata "data/10000000_i32.vals") }

-- ==
-- entry: bench_two_level_lookup
--
-- "n=100000"
-- script input { let s = $loadbytes "data/100000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/100000_i32.vals"
--                let hm = bench_two_level_construct s keys vals
--                in (s, hm, keys) }
-- output @ data/100000_i32.vals
--
-- "n=1000000"
-- script input { let s = $loadbytes "data/1000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/1000000_i32.vals"
--                let hm = bench_two_level_construct s keys vals
--                in (s, hm, keys) }
-- output @ data/1000000_i32.vals
--
-- "n=10000000"
-- script input { let s = $loadbytes "data/10000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/10000000_i32.vals"
--                let hm = bench_two_level_construct s keys vals
--                in (s, hm, keys) }
-- output @ data/10000000_i32.vals

-- ==
-- entry: bench_binary_search_lookup
--
-- "n=100000"
-- script input { let s = $loadbytes "data/100000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/100000_i32.vals"
--                let hm = bench_binary_search_construct s keys vals
--                in (s, hm, keys) }
-- output @ data/100000_i32.vals
--
-- "n=1000000"
-- script input { let s = $loadbytes "data/1000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/1000000_i32.vals"
--                let hm = bench_binary_search_construct s keys vals
--                in (s, hm, keys) }
-- output @ data/1000000_i32.vals
--
-- "n=10000000"
-- script input { let s = $loadbytes "data/10000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/10000000_i32.vals"
--                let hm = bench_binary_search_construct s keys vals
--                in (s, hm, keys) }
-- output @ data/10000000_i32.vals

-- ==
-- entry: bench_eytzinger_lookup
--
-- "n=100000"
-- script input { let s = $loadbytes "data/100000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/100000_i32.vals"
--                let hm = bench_eytzinger_construct s keys vals
--                in (s, hm, keys) }
-- output @ data/100000_i32.vals
--
-- "n=1000000"
-- script input { let s = $loadbytes "data/1000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/1000000_i32.vals"
--                let hm = bench_eytzinger_construct s keys vals
--                in (s, hm, keys) }
-- output @ data/1000000_i32.vals
--
-- "n=10000000"
-- script input { let s = $loadbytes "data/10000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/10000000_i32.vals"
--                let hm = bench_eytzinger_construct s keys vals
--                in (s, hm, keys) }
-- output @ data/10000000_i32.vals

-- ==
-- entry: bench_two_level_member
--
-- "n=100000"
-- script input { let s = $loadbytes "data/100000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/100000_i32.vals"
--                let hm = bench_two_level_construct s keys vals
--                in (s, hm, keys) }
--
-- "n=1000000"
-- script input { let s = $loadbytes "data/1000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/1000000_i32.vals"
--                let hm = bench_two_level_construct s keys vals
--                in (s, hm, keys) }
--
-- "n=10000000"
-- script input { let s = $loadbytes "data/10000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/10000000_i32.vals"
--                let hm = bench_two_level_construct s keys vals
--                in (s, hm, keys) }

-- ==
-- entry: bench_binary_search_member
--
-- "n=100000"
-- script input { let s = $loadbytes "data/100000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/100000_i32.vals"
--                let hm = bench_binary_search_construct s keys vals
--                in (s, hm, keys) }
--
-- "n=1000000"
-- script input { let s = $loadbytes "data/1000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/1000000_i32.vals"
--                let hm = bench_binary_search_construct s keys vals
--                in (s, hm, keys) }
--
-- "n=10000000"
-- script input { let s = $loadbytes "data/10000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/10000000_i32.vals"
--                let hm = bench_binary_search_construct s keys vals
--                in (s, hm, keys) }

-- ==
-- entry: bench_eytzinger_member
--
-- "n=100000"
-- script input { let s = $loadbytes "data/100000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/100000_i32.vals"
--                let hm = bench_eytzinger_construct s keys vals
--                in (s, hm, keys) }
--
-- "n=1000000"
-- script input { let s = $loadbytes "data/1000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/1000000_i32.vals"
--                let hm = bench_eytzinger_construct s keys vals
--                in (s, hm, keys) }
--
-- "n=10000000"
-- script input { let s = $loadbytes "data/10000000_words.txt"
--                let keys = words_from_str s
--                let vals = $loaddata "data/10000000_i32.vals"
--                let hm = bench_eytzinger_construct s keys vals
--                in (s, hm, keys) }
