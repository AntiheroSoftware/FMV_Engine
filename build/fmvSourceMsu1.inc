.include "fmvClass.inc"

.ifndef __FMV_SOURCE_MSU1_INC
__FMV_SOURCE_MSU1_INC = 1

.include "fmvSource.inc"
.import FmvSourceMsu1_startMSU1Address

; Check static map defines
.ifdef STATIC_MAP_BANK
    .error "STATIC_MAP_BANK cannot be defined when using Source Msu1"
.endif

.ifdef STATIC_MAP_ADDRESS
    .error "STATIC_MAP_ADDRESS cannot be defined when using Source Msu1"
.endif 

setThis_DP FmvObject

.ifndef STATIC_MAP_SIZE
    ; get default map size from source
    ldx #.loword(FmvSourceMsu1)
    ldy a:FmvSource::mapSize,x
    sty FmvClass::mapSize
.else
    ; set custom map Size
    ldx #STATIC_MAP_SIZE
    stx FmvClass::mapSize
.endif

; Set sourceObjectPtr with source
ldx #.loword(FmvSourceMsu1)
stx FmvClass::sourceObjectPtr 

; Set start address for Msu1 to 0000 0000
ldx #$0000
stx FmvSourceMsu1_startMSU1Address
stx FmvSourceMsu1_startMSU1Address+2

unsetThis_DP 

.import FmvSourceMsu1

.endif