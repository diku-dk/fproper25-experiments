-- Data generation program. Invoke with 'futhark script'.

import "lib/github.com/diku-dk/cpprandom/shuffle"
import "lib/github.com/diku-dk/cpprandom/random"

module shuffle = mk_shuffle u64 xorshift128plus

def fry xs = (shuffle.shuffle (xorshift128plus.rng_from_seed [123]) xs).1

entry keys (n: i64) : [n]i64 = iota n |> fry

entry vals (n: i64) : [n]i32 = iota n |> map i32.i64 |> fry
