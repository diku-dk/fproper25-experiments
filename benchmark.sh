#!/bin/sh

Ns="1000000 10000000 100000000"

set -e

echo
echo Compiling programs
make mkdata histogram benchmarks -j

echo
echo Generating data
make -j $(for N in $Ns; do echo data/${N}_i64.keys data/${N}_i32.vals; done)

echo
echo Benchmarking Futhark
futhark bench --skip-compilation --backend=cuda benchmarks.fut --json futhark.json

echo
echo Benchmarking CUDA

for N in $Ns; do
    ./histogram data/${N}_i64.keys data/${N}_i32.vals
done
