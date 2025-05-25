#!/bin/sh

set -e

mkdir -p data

echo
echo Compiling programs
make mkdata histogram benchmarks -j

echo
echo Generating data
futhark script -b ./mkdata 'keys 1000000i64' > data/1000000_i64.keys
futhark script -b ./mkdata 'vals 1000000i64' > data/1000000_i32.vals

echo
echo Benchmarking Futhark
futhark bench --skip-compilation --backend=cuda benchmarks.fut --json futhark.json

echo
echo Benchmarking CUDA
./histogram data/1000000_i64.keys data/1000000_i32.vals
