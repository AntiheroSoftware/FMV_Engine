.include "fmvClass.inc"

.ifndef __FMV_SOURCE_SFX_INC
__FMV_SOURCE_SFX_INC = 1

.include "fmvSource.inc"

; Check that static map is defined
.ifndef STATIC_MAP_BANK
    .error .sprintf("STATIC_MAP_BANK need to be declared in used fmvSourceSfx")
.else 
    lda #STATIC_MAP_BANK
    sta FmvClass::mapBank
.endif

.ifndef STATIC_MAP_ADDRESS
    .error .sprintf("STATIC_MAP_ADDRESS need to be declared in used fmvSourceSfx")
.else
    ldx #STATIC_MAP_ADDRESS
    stx FmvClass::mapAddress
.endif 

.ifndef STATIC_MAP_SIZE
    .error .sprintf("STATIC_MAP_SIZE need to be declared in used fmvSourceSfx")
.else
    ldx #STATIC_MAP_SIZE
    stx FmvClass::mapSize
.endif

; Set sourceObjectPtr with source
setThis_DP FmvObject
ldx #.loword(FmvSourceSfx)
stx FmvClass::sourceObjectPtr 
unsetThis_DP 

.import FmvSourceSfx
.scope FmvSfxHelper
    .import getSCMRegister
    .import setSCMRegister
.endscope

.endif