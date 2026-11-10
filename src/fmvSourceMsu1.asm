;
; Fmv Source MSU1 Class methods
;
; by lintbe/AntiheroSoftware <jfdusar@gmail.com>
;

.include "msu1.inc"

            .setcpu     "65816"
            .feature	c_comments

            .include    "snes.inc"
            .include    "msu1.inc"
            .include    "fmvSource.inc"
            .include    "fmvClass.inc"
            .include    "fmvClassMacros.inc"

            .import     FmvBuffer

            .export     FmvSourceMsu1
            .export     FmvSourceMsu1_startMSU1Address

FMV_SOURCE_DMA_ABUS_L   = $2001
FMV_SOURCE_DMA_ABUS_B   = $00

.SEGMENT "RODATA"

FmvSourceMsu1:
    .word .loword(FmvSourceInternal::init)
    .word .loword(FmvSourceInternal::getTileSize)
    .word .loword(FmvSourceInternal::procDmaStreamBufferPrepare)
    .word .loword(FmvSourceInternal::procDmaStreamTileFull)
    .word .loword(FmvSourceInternal::procDmaStreamTileBig)
    .word .loword(FmvSourceInternal::procDmaStreamTileSmall)
    .word .loword(FmvSourceInternal::procDmaStreamMap)
    .word .loword(FmvSourceInternal::procDmaStreamPalette)
    .word .loword(FmvSourceInternal::procDmaStartTransfer)
    .word .loword(FmvSourceInternal::procPlayVideo)
    .word .loword(FmvSourceInternal::procPauseVideo)
    .word .loword(FmvSourceInternal::procStopVideo)
    .byte $00   ; palSkip set to false
    .byte $00   ; palOffset
    .word 8*32  ; palSize
    .byte $00   ; mapSkip set to false
    .word $0600 ; mapSize

.segment "BSS"

FmvSourceMsu1_startMSU1Address:
    .res 4

.SEGMENT "CODE"

.A8
.I16

.scope FmvSourceInternal

.proc init
    ldx #$0000
    ldy #$0000
    jsr Msu1Seek
    rts
.endproc

; Y <- the size in word to transfer 
.proc getTileSize
    phx

    ; read Tile size
    jsr Msu1ReadWord

    plx
    rts
.endproc

.proc procDmaStreamBufferPrepare

    ; Use DMA channel 0 for filling WRAM
    ; DMA to WRAM FMV Buffer
    ldy #.LOWORD(FmvBuffer)
    sty $2181 
    lda #.BANKBYTE(FmvBuffer)
    sta $2183

    ; Set DMA Param 
    ; TODO describe param
    lda #$08
    sta $4300

    ; Set DMA B Bus
    lda #$80
    sta $4301

    ; Set DMA Size
    ; --- Check if size need to be adjusted
    m_getVramTileRemainingSize loadX 
    cpy #HDMA_STREAM_MAX_LENGTH
    ; Branch if remaining size is more or equal to DMA_STREAM_MAX_LENGTH
    bcc updateRemainingSize
    ldy #HDMA_STREAM_MAX_LENGTH
updateRemainingSize:
    sty $4305

    ldy #FMV_SOURCE_DMA_ABUS_L
    sty $4302
    lda #FMV_SOURCE_DMA_ABUS_B
    sta $4304

    rts
.endproc

.proc procDmaStreamTileFull

    m_getVramTileRemainingSize loadX
    phy

    ; Stream Tile data from source
    lda #$80
    sta $2115
    m_getVramTileAddress
    sty $2116
    
    lda #$09
    sta $4300
    
    lda #$18
    sta $4301

    ; Set DMA A Bus from FMV source
    ldy #FMV_SOURCE_DMA_ABUS_L
    sty $4302
    lda #FMV_SOURCE_DMA_ABUS_B
    sta $4304

    lda 1,s
    sta $4305
    lda 2,s
    sta $4306

    jsr procDmaStartTransfer

    ply

    rts
.endproc

.proc procDmaStreamTileBig
    
    ; --- Check if size need to be adjusted
    m_getVramTileRemainingSize loadX 
    cpy #$0000
    ; Skip DMA if size is 0
    beq skipDma

    cpy #DMA_STREAM_MAX_LENGTH
    ; Branch if remaining size is more or equal to DMA_STREAM_MAX_LENGTH
    bcc setTransferSize
    ldy #DMA_STREAM_MAX_LENGTH
    
setTransferSize:
    sty $4305
    phy

    ; Stream Tile data from source
    lda #$80
    sta $2115
    m_getVramTileAddress loadX 
    sty $2116
    
    lda #$09
    sta $4300
    
    lda #$18
    sta $4301

    ; Set DMA A Bus from FMV source
    ldy #FMV_SOURCE_DMA_ABUS_L
    sty $4302
    lda #FMV_SOURCE_DMA_ABUS_B
    sta $4304

    jsr procDmaStartTransfer

    ; --- Update remainning size with adjusted value (get Y register back from stack)
    ply
    m_updateVramTileRemainingSize loadX 

skipDma:
    rts
.endproc

.proc procDmaStreamTileSmall

    m_getVramTileRemainingSize loadX 
    cpy #$0000
    ; Skip DMA if size is 0
    beq skipDma
    sty $4305

    ; Stream remaining Tile data from source
    lda #$80
    sta $2115
    m_getVramTileAddress loadX
    sty $2116
    
    lda #$09
    sta $4300
    
    lda #$18
    sta $4301

    ; Set DMA A Bus from FMV source
    ldy #FMV_SOURCE_DMA_ABUS_L
    sty $4302
    lda #FMV_SOURCE_DMA_ABUS_B
    sta $4304

    jsr procDmaStartTransfer

skipDma:
    
    rts
.endproc

.proc procDmaStreamMap
    ldx FmvClass::mapSize
    beq skipMap
    stx $4305

    ; Stream Map data from source
    lda #$80
    sta $2115
    
    lda	#<FRAME_MAP_VRAM_ADDRESS
    sta	$2116
    lda	#>FRAME_MAP_VRAM_ADDRESS
    sta	$2117
    
    lda #$09
    sta $4300
    
    lda #$18
    sta $4301
    
    ; Set DMA A Bus from FMV source
    ldy #FMV_SOURCE_DMA_ABUS_L
    sty $4302
    lda #FMV_SOURCE_DMA_ABUS_B
    sta $4304
    
    jsr procDmaStartTransfer

skipMap:  
    rts
.endproc

.proc procDmaStreamPalette
    ldx FmvClass::sourceObjectPtr
    ldy FmvClass::palSize           ; check that size isn't zero
    beq skipPal
    
    sty $4305

    ; Stream Palette data from source
    lda FmvClass::palOffset
    sta $2121
    
    lda #$08
    sta $4300
    
    lda #$22
    sta $4301

    ldy #FMV_SOURCE_DMA_ABUS_L
    sty $4302
    lda #FMV_SOURCE_DMA_ABUS_B
    sta $4304

    jsr procDmaStartTransfer

skipPal:
    rts
.endproc

.proc procDmaStartTransfer
    lda #%00000001
    sta $420B
    rts
.endproc

.proc procPlayVideo
    phx
    phy 

    ldx FmvSourceMsu1_startMSU1Address
    ldy FmvSourceMsu1_startMSU1Address+2
    jsr Msu1Seek

    ply
    plx
    rts
.endproc

.proc procPauseVideo
    phx
    phy 

    ; WARNING Reading the MSU_ADDRESS is not possible
    ; TMP fixed with setting 0 like STOP
    
    ;ldx MSU_ADRESS
    ;stx FmvSourceMsu1_startMSU1Address
    ;ldx MSU_ADRESS+2
    ;stx FmvSourceMsu1_startMSU1Address+2

    ldx #$0000
    stx FmvSourceMsu1_startMSU1Address
    stx FmvSourceMsu1_startMSU1Address+2
    
    ply
    plx
    rts
.endproc

.proc procStopVideo
    phx
    phy 

    ldx #$0000
    stx FmvSourceMsu1_startMSU1Address
    stx FmvSourceMsu1_startMSU1Address+2
    
    ply
    plx
    rts
.endproc

.endscope