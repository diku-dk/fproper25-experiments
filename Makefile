NVCC=nvcc
CFLAGS=-O3 -IcuCollections/include --gpu-architecture=sm_80 --expt-extended-lambda
FUTHARK=futhark

all: host_bulk_example histogram

mkdata: mkdata.fut
	$(FUTHARK) c --server $<

benchmarks: benchmarks.fut
	$(FUTHARK) cuda --server $<


%: %.cu data.hpp
	$(NVCC) $< $(CFLAGS) -o $@
