;
; Fmv Class methods
;
; by lintbe/AntiheroSoftware <jfdusar@gmail.com>
;

.include "fmvClass.inc"
.include "fmvClass.inc"

            .setcpu     "65816"
            .feature	c_comments

            .include    "snes.inc"
            .include    "snes-pad.inc"
            .include    "fmvClass.inc"
            .include    "fmvClassMacros.inc"
            .include    "fmvSource.inc"

            .export     FmvObject
            .export     FmvInit
            .export     FmvIrqHandler
            .export     FmvBuffer

            .export     irqTableVCountValues
            .export     verticalAlignOffset

            .export     __IRQ_FmvHdmaStream
            .export     __IRQ_FmvDmaStream
            .export     __IRQ_FmvNextFrame

.segment "BSS" 

.align $100
FmvObject:
    .tag FmvClass

; 3kb buffer for streaming from source
; before being streamed itself to VRAM by HDMA
FmvBuffer:
    .res $0C00

irqTableIndex: 
    .res 2

irqTableVCountValues:
    .res 6

verticalAlignOffset:
    .res 2

VBlankFlag:
    .res 1

.segment "RODATA"

IRQ_TABLE_SIZE = 3

irqTableFunctions: 
    .word .LOWORD(__IRQ_FmvDmaStream)
    .word .LOWORD(__IRQ_FmvNextFrame)
    .word .LOWORD(__IRQ_FmvHdmaStream)

;*** Enable forced V-Blank
FmvHdmaList_1:
  .repeat 192, repeatIndex
    .byte $01
    .byte $80
  .endrepeat
  .byte $00

;*** Set VRAM address
FmvHdmaList_2_Odd_part_1:
  .repeat 192, repeatIndex
    .byte $01
    .word FRAME_ODD_TILE_VRAM_ADDRESS + (repeatIndex * $08)
  .endrepeat
  .byte $00

FmvHdmaList_2_Odd_part_2:
  .repeat 192, repeatIndex
    .byte $01
    .word FRAME_ODD_TILE_VRAM_ADDRESS + (HDMA_STREAM_MAX_LENGTH / 2) + (DMA_STREAM_MAX_LENGTH / 2) + (repeatIndex * $08)
  .endrepeat
  .byte $00

FmvHdmaList_2_Even_part_1:
  .repeat 192, repeatIndex
    .byte $01
    .word FRAME_EVEN_TILE_VRAM_ADDRESS + (repeatIndex * $08)
  .endrepeat
  .byte $00

FmvHdmaList_2_Even_part_2:
  .repeat 192, repeatIndex
    .byte $01
    .word FRAME_EVEN_TILE_VRAM_ADDRESS + (HDMA_STREAM_MAX_LENGTH / 2) + (DMA_STREAM_MAX_LENGTH / 2) + (repeatIndex * $08)
  .endrepeat
  .byte $00

FmvHdmaList_3:
  .repeat 192, repeatIndex
    .byte $01
    .word .LOWORD(FmvBuffer) + (repeatIndex * 4 * 4)
  .endrepeat
  .byte $00
FmvHdmaList_4:
  .repeat 192, repeatIndex
    .byte $01
    .word .LOWORD(FmvBuffer) + (repeatIndex * 4 * 4) + 4
  .endrepeat
  .byte $00
FmvHdmaList_5:
  .repeat 192, repeatIndex
    .byte $01
    .word .LOWORD(FmvBuffer) + (repeatIndex * 4 * 4) + 8
  .endrepeat
  .byte $00
FmvHdmaList_6:
  .repeat 192, repeatIndex
    .byte $01
    .word .LOWORD(FmvBuffer) + (repeatIndex * 4 * 4) + 12
  .endrepeat
  .byte $00

;*** Disable forced V-Blank
FmvHdmaList_7:
  .repeat 191, repeatIndex
    .byte $01
    .byte $0F
  .endrepeat
  .byte $00

.segment "CODE"

.A8
.I16

.scope FmvHelper

.export getVideoStatus
.proc getVideoStatus
    phx 

    setThis_DP FmvObject
    lda FmvClass::videoStatus
    tax
    unsetThis_DP 
    txa

    plx
    rts
.endproc

.export waitVBlank
.proc waitVBlank
wait:
    lda VBlankFlag
    beq wait
    rts
.endproc

.export discardVBlank
.proc discardVBlank 
    stz VBlankFlag
    rts
.endproc

.export     playVideo
.export     pauseVideo
.export     stopVideo

.endscope

.proc FmvInit
    pha
    phx
    phy

    setThis_DP FmvObject

    ; --- Screen init section
    setINIDSP $80   				; Enable forced VBlank during DMA transfer

    lda #$01                        ; Enable fast rom
    sta $420d

    setBG1SC BG1_MAP_ADDR, $00
    setBG12NBA BG1_TILE_ADDR, $00

    lda #$01                        ; set BG mode 2
    sta $2105 

    lda #$01                        ; BG1 enable
    sta $212c

    lda #$00                        ; no sub screen
    sta $212d

    ; --- Set BG1 X offset to 0
    lda #$00
    sta $210D
    stz $210D

    ; --- Set BG1 Y offset (fmv) 
    lda verticalAlignOffset
    sta $210E
    lda verticalAlignOffset+1
    sta $210E

    ; --- Actual init code
    ; Init Frame odd
    ldx #FRAME_ODD_TILE_VRAM_ADDRESS
    stx FmvClass::frameOdd + FmvFrameClass::vramTileAddress
    ldx #$0000
    stx FmvClass::frameOdd + FmvFrameClass::vramTileRemainingSize
    lda #$00
    sta FmvClass::frameOdd + FmvFrameClass::hdmaStreamStatus
    sta FmvClass::frameOdd + FmvFrameClass::dmaStreamStatus

    ; Init Frame even
    ldx #FRAME_EVEN_TILE_VRAM_ADDRESS
    stx FmvClass::frameEven + FmvFrameClass::vramTileAddress
    ldx #$0000
    stx FmvClass::frameEven + FmvFrameClass::vramTileRemainingSize
    lda #$00
    sta FmvClass::frameEven + FmvFrameClass::hdmaStreamStatus
    sta FmvClass::frameEven + FmvFrameClass::dmaStreamStatus

    ; Set currentFramePtr to frameOdd
    ldx #.LOWORD(FmvClass::frameOdd)
    stx FmvClass::currentFramePtr

    ; --- Set palSize and PalOffset
    ldx FmvClass::sourceObjectPtr
    ldy a:FmvSource::palSize,x
    sty FmvClass::palSize

    ldx FmvClass::sourceObjectPtr
    lda a:FmvSource::palOffset,x
    sta FmvClass::palOffset

    ; --- Set sourceObjectPtr
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::init,x)
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::getTileSize,x)

    ; --- Set tileSize in remainingTileSize
    ldx FmvClass::currentFramePtr  
    sty FmvFrameClass::vramTileRemainingSize,x

    stz FmvClass::frameCounter 
    stz FmvClass::frameToSkip 

    jsr _DmaStreamTileFull
    jsr _DmaStreamMap
    jsr _DmaStreamPalette

    jsr _HdmaStreamPrepare
    jsr _DmaStreamBufferPrepare

    ; --- force status when executing next frame code
    lda #$02
    m_setHdmaStatus
    m_setDmaStatus

    ; Set video status to PLAYING by default
    lda #FmvVideoStatus::PLAYING
    sta FmvClass::videoStatus

    unsetThis_DP 

    jsr waitForVBlank
    jsr _FmvIrqHandlerInit

    ply
    plx
    pla
    rts
.endproc

.proc _FmvIrqHandlerInit
    pha
    phx
    phy

    lda #$00
    sta VBlankFlag

    ; Start HDMA list with second item (index 1 * 2)
    ldx #$0002
    stx irqTableIndex
    ldy irqTableVCountValues,x
    sty $4209

    ; Set V-Timing
    ldy #$0000
    sty $4207

    lda #%00110001
    sta CPU_NMITIMEN

    ply
    plx
    pla
    rts
.endproc

.proc FmvIrqHandler
    pha
    phx
    phy

    lda $4211

    ldx irqTableIndex 
    jsr (irqTableFunctions,x)

    inx
    inx
    cpx #(IRQ_TABLE_SIZE * 2)
    bne continue
    ldx #$0000
    continue:
    stx irqTableIndex

    ldy irqTableVCountValues,x
    sty $4209

    ply
    plx
    pla
    rts
.endproc

; DONE
.proc _HdmaStreamStart
    pha 

    lda a:verticalAlignOffset
    beq hdmaExtraConfigSkip

    ; Reset HDMA for starting on random scanline
    lda #$01
    
    sta $431A
    ldx $4312
    stx $4318
    
    sta $432A
    ldx $4322
    stx $4328
    
    sta $433A
    ldx $4332
    stx $4338
    
    sta $434A
    ldx $4342
    stx $4348

    sta $435A
    ldx $4352
    stx $4358

    sta $436A
    ldx $4362
    stx $4368

    sta $437A
    ldx $4372
    stx $4378

hdmaExtraConfigSkip:
    lda #%11111110                                  ; HDMA Channel all but not 0              
    sta $420C

    m_getVramTileRemainingSize loadX
    cpy #$0000
    beq skipDma
    
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::procDmaStartTransfer,x)

    ; --- Check if size need to be adjusted
    m_getVramTileRemainingSize loadX
    cpy #HDMA_STREAM_MAX_LENGTH
    ; Branch if remaining size is more or equal to DMA_STREAM_MAX_LENGTH
    bcc updateRemainingSize
    ldy #HDMA_STREAM_MAX_LENGTH
updateRemainingSize:
    m_updateVramTileRemainingSize

skipDma:

    pla 
    rts 
.endproc

; DONE
.proc _HdmaStreamPrepare
    pha
    phx

    ;***********************************************
    ;*** Update Brightness and force VBlank
    ;***********************************************
    ; Channel: 1 & 7
    ; Transfer direction : CPU -> PPU
    ; HDMA Addressing mode : Absolute
    ; CPU address auto : INC / Enabled
    ; DMA word select : 
    ;   Write 1 byte, B0->$21xx
    ; -> $2100
    ;***********************************************
    ldx #$0000
    stx $4310
    stx $4370

    ldx #.LOWORD(FmvHdmaList_1)
    lda #.BANKBYTE(FmvHdmaList_1)
    stx $4312
    sta $4314

    ldx #.LOWORD(FmvHdmaList_7)
    lda #.BANKBYTE(FmvHdmaList_7)
    stx $4372
    sta $4374

    ;***********************************************
    ;*** Update VRAM address
    ;***********************************************
    ; Channel: 2
    ; Transfer direction : CPU -> PPU
    ; HDMA Addressing mode : Absolute
    ; CPU address auto : INC / Enabled
    ; DMA word select : 
    ;   Write 2 bytes, B0->$21XX, B1->$21XX+1
    ; -> $2116
    ;***********************************************
    ldx #$1601
    stx $4320

    ldx #.LOWORD(FmvHdmaList_2_Odd_part_1)
    lda #.BANKBYTE(FmvHdmaList_2_Odd_part_1)
    stx $4322
    sta $4324

    ;***********************************************
    ;*** Transfer to VRAM
    ;***********************************************
    ; Channel: 3, 4, 5 & 6
    ; Transfer direction : CPU -> PPU
    ; HDMA Addressing mode : Indirect
    ; CPU address auto : INC / Disabled
    ; DMA word select : 
    ;   Write 4 bytes, B0->$21XX B1->$21XX+1 
    ;   B2->$21XX B3->$21XX+1 (Undocumented)
    ; -> $2118
    ;***********************************************
    ldx #$184D
    stx $4330
    stx $4340
    stx $4350
    stx $4360

    ldx #.LOWORD(FmvHdmaList_3)
    lda #.BANKBYTE(FmvHdmaList_3)
    stx $4332
    sta $4334
    stz $4337

    ldx #.LOWORD(FmvHdmaList_4)
    lda #.BANKBYTE(FmvHdmaList_4)
    stx $4342
    sta $4344
    stz $4347

    ldx #.LOWORD(FmvHdmaList_5)
    lda #.BANKBYTE(FmvHdmaList_5)
    stx $4352
    sta $4354
    stz $4357

    ldx #.LOWORD(FmvHdmaList_6)
    lda #.BANKBYTE(FmvHdmaList_6)
    stx $4362
    sta $4364
    stz $4367

    plx
    pla
    rts
.endproc

; DONE
.proc _HdmaStreamStatusUpdate
    pha
    phx

    ; update status
    m_getHdmaStatus
    inc
    m_setHdmaStatus

    plx
    pla
    rts
.endproc 

; DONE
.proc _DmaStreamBufferPrepare
    pha
    phx
    phy

    ; call method from Source Object
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::procDmaStreamBufferPrepare,x)

    ply
    plx
    pla
    rts
.endproc

.proc _DmaStreamTileFull
    pha
    phx
    phy

    ; call method from Source Object
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::procDmaStreamTileFull,x)

    ply
    plx
    pla
    rts
.endproc

; DONE
.proc _DmaStreamTileBig
    pha
    phx
    phy

    ; call method from Source Object
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::procDmaStreamTileBig,x)

    ply
    plx
    pla
    rts
.endproc

.proc _DmaStreamTileSmall
    pha
    phx
    phy

    ; call method from Source Object
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::procDmaStreamTileSmall,x)

    ply
    plx
    pla
    rts
.endproc

; DONE
.proc _DmaStreamMap
    pha
    phx
    phy

    ; call method from Source Object
    ldx FmvClass::sourceObjectPtr
    lda a:FmvSource::mapSkip,x      ; check if Source is skipping map stream
    bne skipMap
    jsr (FmvSource::procDmaStreamMap,x)

skipMap:
    ply
    plx
    pla
    rts
.endproc

; DONE
.proc _DmaStreamPalette
    pha
    phx
    phy

    ; call method from Source Object
    ldx FmvClass::sourceObjectPtr
    lda a:FmvSource::palSkip,x      ; check if Source is skipping pal stream
    bne skipPal
    jsr (FmvSource::procDmaStreamPalette,x)

skipPal:
    ply
    plx
    pla
    rts
.endproc

; DONE
.proc _DmaStreamStatusUpdate
    pha
    phx

    ; update status
    m_getDmaStatus
    inc
    m_setDmaStatus

    plx
    pla
    rts
.endproc 

; DONE
.proc __IRQ_FmvHdmaStream
    pha
    phx

    lda #$00
    sta VBlankFlag

    setThis_DP FmvObject

    ; Check if video is stopped or paused
    lda FmvClass::videoStatus
    cmp #FmvVideoStatus::STOPPED
    bne videoIsPlaying

    ; Video is not playing -> exit function
    unsetThis_DP

    ;setINIDSP $0f                ; Disable forced VBlank + full brightness

    plx
    pla
    rts

videoIsPlaying:
    ; Check if wee need to skip a frame
    lda FmvClass::frameToSkip
    beq noFrameSkip

    lda a:verticalAlignOffset
    beq hdmaExtraConfigSkip

    ; Reset HDMA for starting on random scanline
    lda #$01
    
    sta $431A
    ldx $4312
    stx $4318

    sta $437A
    ldx $4372
    stx $4378
hdmaExtraConfigSkip:
    lda #%10000010
    sta $420C

    jmp frameSkip

noFrameSkip:
    m_setCurrentFrameToX

    ; Start DMA buffer + HDMA channels
    jsr _HdmaStreamStart

    ; Update Hdma status
    jsr _HdmaStreamStatusUpdate

frameSkip:
    unsetThis_DP 

    plx
    pla
    rts
.endproc

; DONE
.proc __IRQ_FmvDmaStream
    pha
    phx

    lda #$01
    sta VBlankFlag

    ; --- Forced VBlank is needed here and it's done by 
    ;     Hdma channel 7

    setThis_DP FmvObject

    stz $420C                   ; Disable all HDMA channels

    ; Check if video is stopped or paused
    lda FmvClass::videoStatus
    cmp #FmvVideoStatus::STOPPED
    bne videoIsPlaying

    ; Video is not playing -> exit function
    unsetThis_DP

    ;setINIDSP $80   				; Enable forced VBlank

    plx
    pla
    rts

videoIsPlaying:
    ; Check if wee need to skip a frame
    lda FmvClass::frameToSkip
    beq noFrameSkip
    jmp frameSkip

noFrameSkip:
    m_setCurrentFrameToX

    ; Check dmaStreamStatus
    m_getDmaStatus
    bne updateEvenFrame

updateOddFrame:
    ; --- Setup and start BIG Tile DMA to VRAM
    jsr _DmaStreamTileBig
    ; --- Update dmaStreamStatus
    jsr _DmaStreamStatusUpdate
    bra exit

updateEvenFrame:
    ; --- Setup and start SMALL Tile DMA to VRAM
    jsr _DmaStreamTileSmall
    ; --- Setup and start Map DMA to VRAM
    jsr _DmaStreamMap
    ; --- Setup and start Palette DMA to VRAM
    jsr _DmaStreamPalette
    ; --- Update dmaStreamStatus
    jsr _DmaStreamStatusUpdate

exit:
frameSkip:
    unsetThis_DP 

    plx
    pla
    rts
.endproc

; DONE
.proc __IRQ_FmvNextFrame
    pha
    phx

    setThis_DP FmvObject

    ; TODO SOMETHING IS WRONG first push isn't working
    jsr readPad1

    ; Check if video is stopped or paused
    lda FmvClass::videoStatus
    beq videoIsPlaying

    cmp #FmvVideoStatus::STARTING   ; Video is not playing, check if STARTING
    bne checkVideoIsStopping

    lda #FmvVideoStatus::PLAYING    ; If STARTING
    sta FmvClass::videoStatus       ; Switch to PLAYING
    bra videoIsPlaying              ; Branch to play

checkVideoIsStopping:
    cmp #FmvVideoStatus::STOPPING   ; Video is not playing or starting, check if STOPPING
    bne videoNotPlaying

    lda #FmvVideoStatus::STOPPED    ; If STOPPING
    sta FmvClass::videoStatus       ; Switch to STOPPED

videoNotPlaying:
    unsetThis_DP

    plx
    pla
    rts

videoIsPlaying:
    m_setCurrentFrameToX

checkFrameSkip:
    ; Check if wee need to skip a frame
    lda FmvClass::frameToSkip   
    beq checkFrameStatus          ; Branch to checkFpsConfig if frameToSkip = 0
    dec
    sta FmvClass::frameToSkip 
    jmp frameSkip

checkFrameStatus:
    ; Check if frame is over
    ; HdmaStatus and DmaStatus are 1 
    ; if frame switching is needed
    m_getHdmaStatus
    cmp #$02
    bne branchSameFrame
    m_getDmaStatus
    cmp #$02
    bne branchSameFrame
    bra checkFpsConfig

branchSameFrame:
    bra sameFrame

checkFpsConfig:
    lda FmvClass::fpsValue 
    and #$0f 

check_30FPS:
    cmp #$00
    bne check_24FPS

    ; --- 30 FPS CONFIG
    ; Do nothing in 30 FPS config
    bra nextFrame

check_24FPS:
    cmp #$02
    bne nextFrame

    ; --- 24 FPS Config
    lda FmvClass::frameCounter 
    inc 
    sta FmvClass::frameCounter  ; Increment frameCounter
    cmp #$06                    ; Check if framecounter is 6
    bne nextFrame

    stz FmvClass::frameCounter  ; Reset frameCounter
    lda #$01
    sta FmvClass::frameToSkip   ; Set frame to skip to 1

nextFrame:
    ; --- update frame pointer
    cpx #.LOWORD(FmvClass::frameEven)
    beq setFrameOdd
setFrameEven:
    ; --- Setup working frame as Even
    ldx #.LOWORD(FmvClass::frameEven)
    stx FmvClass::currentFramePtr
    ; --- update Hdma list
    ldx #.LOWORD(FmvHdmaList_2_Even_part_1)
    lda #.BANKBYTE(FmvHdmaList_2_Even_part_1)
    stx $4322
    sta $4324
    ; --- Reset vramTileAddress
    ldx #FRAME_EVEN_TILE_VRAM_ADDRESS
    stx FmvClass::frameEven + FmvFrameClass::vramTileAddress
    ; --- Set display of frame Odd
    setBG12NBA FRAME_ODD_TILE_VRAM_ADDRESS, $00
    bra resetStatus
setFrameOdd:
    ; --- Setup working frame as Odd
    ldx #.LOWORD(FmvClass::frameOdd)
    stx FmvClass::currentFramePtr
    ; --- update Hdma list
    ldx #.LOWORD(FmvHdmaList_2_Odd_part_1)
    lda #.BANKBYTE(FmvHdmaList_2_Odd_part_1)
    stx $4322
    sta $4324
    ; --- Reset vramTileAddress
    ldx #FRAME_ODD_TILE_VRAM_ADDRESS
    stx FmvClass::frameOdd + FmvFrameClass::vramTileAddress
    ; --- Set display of frame Even
    setBG12NBA FRAME_EVEN_TILE_VRAM_ADDRESS, $00

resetStatus:
    ; --- reset frame status
    m_setCurrentFrameToX
    lda #$00
    m_setHdmaStatus
    m_setDmaStatus
    ; Get full tile size
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::getTileSize,x)
    ; Check if tile size is 0 -> Stop video
    cpy #$0000
    beq stopVideo
    m_setVramTileRemainingSize loadX
    bra allFrames

sameFrame:
    ; --- update hdma list 
    cpx #.LOWORD(FmvClass::frameEven)
    bne setNextPartFrameOdd
setNextPartFrameEven:
    ldx #.LOWORD(FmvHdmaList_2_Even_part_2)
    lda #.BANKBYTE(FmvHdmaList_2_Even_part_2)
    stx $4322
    sta $4324
    m_setCurrentFrameToX
    bra allFrames
setNextPartFrameOdd:
    ldx #.LOWORD(FmvHdmaList_2_Odd_part_2)
    lda #.BANKBYTE(FmvHdmaList_2_Odd_part_2)
    stx $4322
    sta $4324
    m_setCurrentFrameToX

allFrames:
    ; --- setup dma source buffer
    jsr _DmaStreamBufferPrepare
    bra frameSkip

stopVideo:
    jsr stopVideo

frameSkip:
    unsetThis_DP

    plx
    pla
    rts
.endproc

.proc playVideo
    pha

    setThis_DP FmvObject

    lda #FmvVideoStatus::STARTING
    sta FmvClass::videoStatus

    ; call method from Source Object
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::procPlayVideo,x)

    unsetThis_DP

    pla
    rts
.endproc

.proc pauseVideo
    pha
    phx

    setThis_DP FmvObject

    lda #FmvVideoStatus::STOPPING
    sta FmvClass::videoStatus

    ; call method from Source Object
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::procPauseVideo,x)

    unsetThis_DP

    plx
    pla
    rts
.endproc

.proc stopVideo
    pha
    phx
    phy

    setThis_DP FmvObject

    lda #FmvVideoStatus::STOPPING
    sta FmvClass::videoStatus

    ; call method from Source Object
    ldx FmvClass::sourceObjectPtr
    jsr (FmvSource::procStopVideo,x)

    unsetThis_DP

    ply
    plx
    pla
    rts
.endproc

