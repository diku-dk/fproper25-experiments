NVCC=nvcc
CFLAGS=-O3 -IcuCollections/include --gpu-architecture=sm_80 --expt-extended-lambda
FUTHARK=futhark

all: host_bulk_example inttables

mkdata: mkdata.fut
	$(FUTHARK) c --server $<

benchmarks: benchmarks.fut
	$(FUTHARK) cuda --server $<

data/%_i64.keys: mkdata
	@mkdir -p data
	futhark script -b ./mkdata "keys $*i64" > data/$*_i64.keys

data/%_i32.vals: mkdata
	@mkdir -p data
	futhark script -b ./mkdata "vals $*i64" > data/$*_i32.vals

%: %.cu data.hpp
	$(NVCC) $< $(CFLAGS) -o $@
