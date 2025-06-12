#!/usr/bin/env python3
#
# Reads intmap.json and strmap.json and produces LaTeX table rows.

import json

intmap=json.load(open('intmap.json'))

strmap=json.load(open('strmap.json'))

def mean(x):
    return sum(x) / len(x)


workload="n=10000000"

def numbahs(f, impl):
    j = intmap if f == 'intmap' else strmap
    return (mean(j[f"{f}.fut:bench_{impl}_construct"]["datasets"][workload]["runtimes"])/1000,
            mean(j[f"{f}.fut:bench_{impl}_lookup"]["datasets"][workload]["runtimes"])/1000,
            mean(j[f"{f}.fut:bench_{impl}_member"]["datasets"][workload]["runtimes"])/1000)

iconstruct,ilookup,imember = numbahs('intmap', 'two_level_u32')
sconstruct,slookup,smember = numbahs('strmap', 'two_level')
print(f'Futhark (hash tables) & {iconstruct:.1f} & {ilookup:.1f} & {imember:.1f}',
      f'& {sconstruct:.1f} & {slookup:.1f} & {smember:.1f} \\\\')

iconstruct,ilookup,imember = numbahs('intmap', 'binary_search')
sconstruct,slookup,smember = numbahs('strmap', 'binary_search')
print(f'Futhark (binary search) & {iconstruct:.1f} & {ilookup:.1f} & {imember:.1f}',
      f'& {sconstruct:.1f} & {slookup:.1f} & {smember:.1f} \\\\')

iconstruct,ilookup,imember = numbahs('intmap', 'eytzinger')
sconstruct,slookup,smember = numbahs('strmap', 'eytzinger')
print(f'Futhark (Eytzinger) & {iconstruct:.1f} & {ilookup:.1f} & {imember:.1f}',
      f'& {sconstruct:.1f} & {slookup:.1f} & {smember:.1f} \\\\')
