CC?=cc
NVCC=nvcc
CFLAGS=-O3 -IcuCollections/include --gpu-architecture=sm_80 --expt-extended-lambda
FUTHARK=futhark

.PHONY: clean

all: host_bulk_example intmap_cuco random_words strmap_cuco

mkdata: mkdata.fut
	$(FUTHARK) c --server $<

%: %.fut
	$(FUTHARK) cuda --server $<

random_words: random_words.c
	$(CC) -o $@ $^ -Wall -O

data/%_i64.keys: mkdata
	@mkdir -p data
	futhark script -b ./mkdata "keys $*i64" > data/$*_i64.keys

data/%_i32.vals: mkdata
	@mkdir -p data
	futhark script -b ./mkdata "vals $*i64" > data/$*_i32.vals

data/%_words.txt: random_words
	@mkdir -p data
	./random_words $* 5 25 > $@

%: %.cu data.hpp timing.hpp
	$(NVCC) $< $(CFLAGS) -o $@

clean:
	rm -r data \
              host_bulk_example \
	      intmap_cuco \
	      random_words \
	      strmap_cuco \
	      strmap \
	      intmap \
	      strmap.c \
	      intmap.c \
	      intmap.json \
	      strmap.json 2>/dev/null || exit 0
