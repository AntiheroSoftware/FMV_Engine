SFC_LIB_HOME=/project/cc65-sfclib
SFC_LIB_PATH=$(SFC_LIB_HOME)/bin
SFC_CFG_PATH=$(SFC_LIB_HOME)/cfg
SFC_INC_PATH=$(SFC_LIB_HOME)/include

LIB_OBJ = src/msu1.o src/fmvClass.o src/fmvSourceMsu1.o src/fmvSourceSfx.o

%.o: %.asm
	ca65 -I $(SFC_INC_PATH) -I /project/src -t none -g $<

all: clean lib examples

lib: $(LIB_OBJ)
	ar65 a /project/build/sfc_fmv_engine.lib $^
	cp src/fmv.inc /project/build/.
	cp src/fmvClass.inc /project/build/.
	cp src/fmvSource.inc /project/build/.
	cp src/fmvSourceMsu1.inc /project/build/.

.PHONY: examples

examples:
	@$(MAKE) -C examples all

.PHONY: clean

clean:
	rm -rf src/*.o
	rm -rf build/*
	rm -rf examples/*.o
	rm -rf examples/*.sfc