;
; Fmv Source SFX Class methods
;
; by lintbe/AntiheroSoftware <jfdusar@gmail.com>
;

            .setcpu     "65816"
            .feature	c_comments

            .include    "snes.inc"
            .include    "fmvClass.inc"
            .include    "fmvClassMacros.inc"

            .import     FmvBuffer

            .export     FmvSourceSfx

.SEGMENT "RODATA"

FmvSourceSfx:
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
    .byte $01   ; palSkip set to true
    .byte $00   ; palOffset
    .word 32    ; palSize
    .byte $01   ; mapSkip set to true
    .word $0600 ; mapSize

.SEGMENT "BSS"

SRAM_Address: 
    .res 2

SRAM_Offset:
    .res 2

SCMR_Mirror:
    .res 1

.SEGMENT "CODE"

.A8
.I16

.scope FmvSfxHelper

.export getSCMRegister
.export setSCMRegister

.proc getSCMRegister
    lda SCMR_Mirror
    rts
.endproc

.proc setSCMRegister
    sta SCMR_Mirror
    sta $303A
    rts
.endproc

.endscope

.scope FmvSourceInternal

.proc init
    ldy #$0000
    sty SRAM_Address
    sty SRAM_Offset
    rts
.endproc

; Y <- the size in word to transfer 
.proc getTileSize
    ldy #$6000
    rts
.endproc

; Set start address for Dma transfer
; -> Y : Size of the transfer
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

    pha

    rep #$20                                        ; set A to 16 bit
    .a16
    
    tya
    clc
    adc SRAM_Offset
    sta SRAM_Offset                                 ; Update SRAM_Offset with transfer size

    clc
    adc SRAM_Address                                ; Calculate final destination address
    sta DMA_ABUS0L                                  ; Set in DMA

    sep #$20                                        ; set A to 8 bit
    .a8

    lda #$70
    sta DMA_ABUS0B                                  ; Set DMA bank
    
    pla
    rts
.endproc

.proc procDmaStreamTileFull

    m_getVramTileRemainingSize loadX 
    phy

    ; Stream Tile data from source
    setVMAINC $80
    m_getVramTileAddress
    sty PPU_VMADDL
    setDMAParam $09
    setDMABBus $18

    ; Set DMA A Bus from FMV source
    ldy #$0000
    sty DMA_ABUS0L
    lda #$70
    sta DMA_ABUS0B

    lda 1,s
    sta DMA_SIZE0L
    lda 2,s
    sta DMA_SIZE0H

    jsr procDmaStartTransfer

    ply

    rts
.endproc

.proc procDmaStreamTileBig
    pha

    rep #$20                                        ; set A to 16 bit
    .a16
    
    tya
    clc
    adc SRAM_Offset
    sta SRAM_Offset                                 ; Update SRAM_Offset with transfer size

    clc
    adc SRAM_Address                                ; Calculate final destination address
    sta DMA_ABUS0L                                  ; Set in DMA

    sep #$20                                        ; set A to 8 bit
    .a8

    lda #$70
    sta DMA_ABUS0B                                  ; Set DMA bank

    ; Stream Tile data from source
    setVMAINC $80
    m_getVramTileAddress
    sty PPU_VMADDL
    setDMAParam $09
    setDMABBus $18

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
    sty DMA_SIZE0L
    phy

    jsr procDmaStartTransfer

    ; --- Update remainning size with adjusted value (get Y register back from stack)
    ply
    m_updateVramTileRemainingSize loadX 

skipDma:
    
    pla
    rts
    rts
.endproc

.proc procDmaStreamTileSmall
    pha

    rep #$20                                        ; set A to 16 bit
    .a16
    
    tya
    clc
    adc SRAM_Offset
    sta SRAM_Offset                                 ; Update SRAM_Offset with transfer size

    clc
    adc SRAM_Address                                ; Calculate final destination address
    sta DMA_ABUS0L                                  ; Set in DMA

    sep #$20                                        ; set A to 8 bit
    .a8

    lda #$70
    sta DMA_ABUS0B                                  ; Set DMA bank

        ; Stream remaining Tile data from source
    setVMAINC $80
    m_getVramTileAddress
    sty PPU_VMADDL
    setDMAParam $09
    setDMABBus $18

    m_getVramTileRemainingSize loadX 
    cpy #$0000
    ; Skip DMA if size is 0
    beq skipDma
    sty DMA_SIZE0L

    jsr procDmaStartTransfer

skipDma:
    
    pla
    rts
.endproc

.proc procDmaStreamMap
    rts
.endproc

.proc procDmaStreamPalette
    rts
.endproc

.proc procDmaStartTransfer
    ; Remove access to SRAM for Sfx/Gsu
    jsr FmvSfxHelper::getSCMRegister
    and #%11101111
    jsr FmvSfxHelper::setSCMRegister

    ; Start DMA channel 0
    lda #%00000001
    sta $420B

    ; Give access to SRAM for Sfx/Gsu
    jsr FmvSfxHelper::getSCMRegister
    ora #%00010000
    jsr FmvSfxHelper::setSCMRegister

    rts
.endproc

.proc procPlayVideo
    rts
.endproc

.proc procPauseVideo
    rts
.endproc

.proc procStopVideo
    rts
.endproc

.endscope