#!/bin/sh

Ns="100000 1000000 10000000"

set -e

echo
echo Compiling programs
make mkdata intmap_cuco intmap strmap_cuco strmap -j

echo
echo Generating data
make -j $(for N in $Ns; do echo data/${N}_i64.keys data/${N}_i32.vals data/${N}_words.txt; done)

echo
echo Benchmarking Futhark Integer Map
futhark bench --skip-compilation --backend=cuda intmap.fut --json intmap.json

echo
echo Benchmarking CUDA Integer Map

for N in $Ns; do
    ./intmap_cuco data/${N}_i64.keys data/${N}_i32.vals
done

echo
echo Benchmarking Futhark String Map
futhark bench --skip-compilation --backend=cuda strmap.fut --json strmap.json

echo
echo Benchmarking CUDA String Map

for N in $Ns; do
    ./strmap_cuco data/${N}_words.txt data/${N}_i32.vals
done
