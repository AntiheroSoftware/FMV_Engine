;
; FMV Engine :: Test Rom
;
; by lintbe/AntiheroSoftware <jfdusar@gmail.com>
;

            .setcpu     "65816"
            .feature	  c_comments
            .linecont   +

            .include    "snes.inc"
            .include    "snes-pad.inc"
            .include    "snes-sprite.inc"
            .include    "snes-event.inc"

            .include    "fmv.inc"

            .forceimport	__STARTUP__

            .export     _main
            .export     _IRQHandler
            .export     _NMIHandler
            .export     _preInit

.segment "RODATA"

staticMap:
    .res $0600

.segment "BSS"



.segment "CODE"

.proc _main

  rep #$10
  sep #$20
  .A8
  .I16                       

  setINIDSP $80   				  ; Enable forced VBlank during DMA transfer

  jsr initEvents
  jsr initPad
  jsr clearOAM

  m_FmvInit FpsConfig::NTSC_30, VerticalAlign::CENTER, Msu1 

  ;m_FmvInit FpsConfig::NTSC_24, VerticalAlign::CENTER, Msu1 

  ;STATIC_MAP_BANK = .bankbyte(staticMap)
  ;STATIC_MAP_ADDRESS = .loword(staticMap)
  ;STATIC_MAP_SIZE = $0600
  ;m_FmvInit FpsConfig::NTSC_30, VerticalAlign::CENTER, Sfx

  ; TODO Need to document the usage of the Helpers
  ;lda #%00010001
  ;jsr FmvSfxHelper::setSCMRegister

infiniteLoop:
  ;jsr waitForVBlank 
  ; WaitVBlank_Polling:
  ;   LDA $4212       ; Lire le registre d'état du balayage (HVBJOY)
  ;   AND #$80        ; Isoler le bit 7 (VBlank status)
  ;   BEQ WaitVBlank_Polling ; Si = 0, on n'est pas en VBlank, on boucle 

waitVBlank:
  jsr FmvHelper::waitVBlank
  beq waitVBlank


	; Wait time before reading pad
	; .repeat 32
	; 	nop
	; .endrepeat

  ;jsr readPad1
  jsr updateVideoStatusFromPad
  jsr FmvHelper::discardVBlank

  ;  WaitVBlank_EndPolling:
  ;   LDA $4212       ; Lire le registre d'état du balayage (HVBJOY)
  ;   AND #$80        ; Isoler le bit 7 (VBlank status)
  ;   BNE WaitVBlank_EndPolling ; Si = 0, on n'est pas en VBlank, on boucle 

  bra infiniteLoop

.endproc

.proc updateVideoStatusFromPad
  pha

checkButtonA:
	lda padFirstPushDataHigh1
	cmp #PAD_HIGH_A
	bne checkButtonB

	; Handle Play / Pause
	jsr FmvHelper::getVideoStatus
	cmp #FmvVideoStatus::PLAYING
	bne checkVideoStatusStopped
	jsr FmvHelper::pauseVideo

	bra exit
checkVideoStatusStopped:
	cmp #FmvVideoStatus::STOPPED
	bne exit
	jsr FmvHelper::playVideo
	bra exit

	; Handle Stop
checkButtonB:
	lda padFirstPushDataLow1
	cmp #PAD_LOW_B
	bne exit
	jsr FmvHelper::stopVideo

exit:
	pla
	rts
.endproc

.proc _IRQHandler
  pha
  phx
  php
  phb

  jsr FmvIrqHandler

  plb
  plp
  plx
  pla
  rts
.endproc

.proc _NMIHandler
  jsr readPad1
  jsr processEvents
  rts
.endproc

.proc _preInit
  rts
.endproc