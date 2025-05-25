-- Data generation program. Invoke with 'futhark script'.

entry keys (n: i64) : [n]i64 =
  iota n

entry vals (n: i64) : [n]i32 =
  iota n |> map i32.i64
