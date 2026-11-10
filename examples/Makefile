SFC_LIB_HOME=/project/cc65-sfclib
SFC_LIB_PATH=$(SFC_LIB_HOME)/bin
SFC_CFG_PATH=$(SFC_LIB_HOME)/cfg
SFC_INC_PATH=$(SFC_LIB_HOME)/include

ROM_NAME = fmv_engine_ntsc_30_256x192
OBJ = ./$(ROM_NAME).o ./rom_info.o

%.o: %.asm
	ca65 -I $(SFC_INC_PATH) -I /project/build -t none -g $<

all: clean rom

rom: $(OBJ)
	ld65 -vm --dbgfile ./$(ROM_NAME).dbg -m ./$(ROM_NAME).map -o ./$(ROM_NAME).sfc -C /project/cc65-sfclib/cfg/snes-fast-lorom256.cfg $^ /project/build/sfc_fmv_engine.lib $(SFC_LIB_PATH)/sfc.lib

.PHONY: clean

clean:
	rm -rf *.dbg
	rm -rf *.map
	rm -rf *.o
	rm -rf *.sfc