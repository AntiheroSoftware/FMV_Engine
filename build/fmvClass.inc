.import getVideoStatus

.ifndef __FMV_CLASS_INC
__FMV_CLASS_INC = 1

BG1_TILE_ADDR = $0000 ; SIZE = $3000
BG1_MAP_ADDR  = $6000 ; SIZE = $400
 
HDMA_STREAM_MAX_LENGTH = $0C00
DMA_STREAM_MAX_LENGTH = $2800

FRAME_ODD_TILE_VRAM_ADDRESS = $0000
FRAME_EVEN_TILE_VRAM_ADDRESS = $3000
FRAME_MAP_VRAM_ADDRESS = $6000

.scope FmvVideoStatus
    PLAYING     = $00
    STARTING    = $01
    STOPPED     = $02
    STOPPING    = $03
.endscope

.struct FmvFrameClass
    vramTileAddress             .word
    vramTileRemainingSize       .word
    hdmaStreamStatus            .byte
    dmaStreamStatus             .byte
.endstruct

.struct FmvClass
    currentFramePtr             .word
    frameOdd                    .tag FmvFrameClass
    frameEven                   .tag FmvFrameClass
    palBank                     .byte
    palAddress                  .word
    palSize                     .word                   ; Size of palette to stream
    palOffset                   .byte                   ; Where to put Fmv palettes
    mapBank                     .byte
    mapAddress                  .word
    mapSize                     .word
    sourceObjectPtr             .word                   ; RAM address of the source object
    fpsValue                    .byte
    frameCounter                .byte
    frameToSkip                 .byte
    videoStatus                 .byte
.endstruct

.macro setThis_DP FmvObject
    rep #$20                                        ; set A to 16 bit
    .a16
    
    ; save current direct page
    tdc
    pha

    ; set direct page to FmvObject address 
    lda #(.HIBYTE(FmvObject) << 8)
    tcd

    sep #$20                                        ; set A to 8 bit
    .a8
.endmacro

.macro unsetThis_DP 
    rep #$20                                        ; set A to 16 bit
    .a16
    
    ; restore initial direct page
    pla
    tcd

    sep #$20                                        ; set A to 8 bit
    .a8
.endmacro

.endif