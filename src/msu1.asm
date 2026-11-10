;
; MSU1 FMV Engine :: msu1 functions
;
; by lintbe/AntiheroSoftware <jfdusar@gmail.com>
; using code from https://zumi.neocities.org/stuff/msu1_notes/msu1_snippets.txt

            .setcpu     "65816"
            .feature	c_comments
            .linecont   +

            __MSU1_INC_SKIP_IMPORT = 1
            .include    "msu1.inc"

            .export     Msu1Detect
            .export     Msu1Seek
            .export     Msu1ReadByte
            .export     Msu1ReadWord

.segment "CODE"

.A8
.I16 

.proc Msu1Detect
    phx 

    ldx MSU_ID		;
    cpx #$2D53		; 'S-'
    bne NoMSU
    ldx MSU_ID + 2
    cpx #$534D		; 'MS'
    bne NoMSU
    ldx MSU_ID + 4
    cpx #$3155		; 'U1'
    bne NoMSU
MSUFound:
    lda #$01
    plx
    rts
NoMSU:
    lda #$00
    plx
    rts
.endproc

.proc Msu1Seek
    stx MSU_ADRESS
    sty MSU_ADRESS+2

    nop   ;some delay seems to be required, otherwise, sd2snes sometimes reads from wrong address
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    phx
    
    ldx #MSU1_SEEK_TIMEOUT
waitSeekOk:
	dex
	beq _Msu1SeekTimeout
	lda MSU_STATUS
	bmi waitSeekOk

    plx
    rts
.endproc

.proc _Msu1SeekTimeout
    brk #$00
.endproc

.proc Msu1ReadByte
    lda MSU_DATA
    rts
.endproc

.proc Msu1ReadWord
    pha
    lda MSU_DATA
    xba
    lda MSU_DATA
    xba
    tay
    pla
    rts
.endproc