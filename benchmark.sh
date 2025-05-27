#!/bin/sh

Ns="1000000 10000000"

set -e

echo
echo Compiling programs
make mkdata intmap_cuco intmap -j

echo
echo Generating data
make -j $(for N in $Ns; do echo data/${N}_i64.keys data/${N}_i32.vals; done)

echo
echo Benchmarking Futhark
futhark bench --skip-compilation --backend=cuda intmap.fut --json futhark.json

echo
echo Benchmarking CUDA

for N in $Ns; do
    ./intmap_cuco data/${N}_i64.keys data/${N}_i32.vals
done
