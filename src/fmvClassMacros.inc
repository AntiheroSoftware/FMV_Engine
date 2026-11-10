.ifndef __FMV_CLASS_MACROS_INC
__FMV_CLASS_MACROS_INC = 1

.A8
.I16

;***************************************************
;*** WARNING : All functions below assume that 
;*** DP register is set at FmvClass object 
;*** address
;***************************************************

.macro m_setCurrentFrameToX 
    ldx FmvClass::currentFramePtr 
.endmacro

;*** <- A contains current frame HDMA status
.macro m_getHdmaStatus loadX, keepX 
.ifnblank keepX
    phx
.endif
.ifnblank loadX
    m_setCurrentFrameToX
.endif
    lda FmvFrameClass::hdmaStreamStatus,x
.ifnblank keepX
    plx
.endif
.endmacro

;*** <- A contains current frame DMA status
.macro m_getDmaStatus loadX, keepX 
.ifnblank keepX
    phx
.endif
.ifnblank loadX
    m_setCurrentFrameToX
.endif 
    lda FmvFrameClass::dmaStreamStatus,x
.ifnblank keepX
    plx
.endif
.endmacro

;*** <- Y contains VRAM tile address
.macro m_getVramTileAddress loadX, keepX 
.ifnblank keepX
    phx
.endif
.ifnblank loadX
    m_setCurrentFrameToX
.endif 
    ldy FmvFrameClass::vramTileAddress,x
.ifnblank keepX
    plx
.endif
.endmacro

;*** <- Y contains VRAM tile remaining size 
.macro m_getVramTileRemainingSize loadX, keepX 
.ifnblank keepX
    phx
.endif
.ifnblank loadX
    m_setCurrentFrameToX
.endif 
    ldy FmvFrameClass::vramTileRemainingSize,x
.ifnblank keepX
    plx
.endif
.endmacro

;*** <-> A contains current frame HDMA status
.macro m_setHdmaStatus loadX, keepX 
.ifnblank keepX
    phx
.endif
.ifnblank loadX
    m_setCurrentFrameToX
.endif  
    sta FmvFrameClass::hdmaStreamStatus,x
.ifnblank keepX
    plx
.endif
.endmacro

;*** <-> A contains current frame DMA status
.macro m_setDmaStatus loadX, keepX 
.ifnblank keepX
    phx
.endif
.ifnblank loadX
    m_setCurrentFrameToX
.endif 
    sta FmvFrameClass::dmaStreamStatus,x
.ifnblank keepX
    plx
.endif
.endmacro

;*** -> Y contains VRAM tile remaining size 
.macro m_setVramTileRemainingSize loadX, keepX 
.ifnblank keepX
    phx
.endif
.ifnblank loadX
    m_setCurrentFrameToX
.endif 
    sty FmvFrameClass::vramTileRemainingSize,x
.ifnblank keepX
    plx
.endif
.endmacro

;*** -> Y contains last processed size
;*** <- Y contains current frame VRAM tile remaining size 
.macro m_updateVramTileRemainingSize loadX, keepX 
    rep #$20                                        ; set A to 16 bit
    .a16

    pha
    phy             ; Push last processed size in bytes

    tya             ; Calculate size in VRAM 
    lsr
    pha             ; Push size in VRAM

.ifnblank keepX
    phx
.endif
.ifnblank loadX
    m_setCurrentFrameToX
.endif 
    ; Update vramTileRemainingSize
    lda FmvFrameClass::vramTileRemainingSize,x
    sec
    sbc 3,s
    sta FmvFrameClass::vramTileRemainingSize,x
    ; Update vramTileAddress
    lda FmvFrameClass::vramTileAddress,x
    clc 
    adc 1,s
    sta FmvFrameClass::vramTileAddress,x
.ifnblank keepX
    plx
.endif

    pla             ; Pull from stack (VRAM size)
    pla             ; Pull from stack (Byte size)
    pla

    sep #$20                                        ; set A to 8 bit
    .a8
.endmacro

.endif