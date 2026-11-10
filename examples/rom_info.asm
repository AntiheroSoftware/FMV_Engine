.segment "ROMINFO_OVERWRITE"

MAKER_CODE:         .byte   "FF"
GAME_CODE:          .byte   "FVME"
FIXED_VALUE0:       .byte   $00, $00, $00, $00, $00, $00, $00
EXPANSION_RAM_SIZE: .byte   $00
SPECIAL_VERSION:    .byte   $00
CARTRIDGE_TYPE_SUB: .byte   $00

GAME_TITLE:         .byte   "FMV ENGINE MSU1 TEST "
                            ;012345678901234567890;
MAP_MODE:           .byte   $30
CHIPSET:    	    .byte   $00
ROM_SIZE:           .byte   $08
RAM_SIZE:           .byte   $00
DESTINATION_CODE:   .byte   $00
FIXED_VALUE1:	    .byte   $33
MASK_ROM_VERSION:   .byte   $00
COMPLEMENT_CHECK:   .byte   $00, $00
CHEKSUM:            .byte   $00, $00