.import playVideo

.ifndef __FMV_INC
__FMV_INC = 1

.import FmvObject
.import FmvInit
.import FmvIrqHandler

.import irqTableVCountValues
.import verticalAlignOffset

.include    "fmvClass.inc"

.linecont +

; --- List of FPS possible values
.scope FpsConfig
    NTSC_30   = $00
    NTSC_25   = $01
    NTSC_24   = $02
    PAL_25    = $11
    PAL_24    = $12
.endscope

; --- List of FPS possible values
.scope VerticalAlign
    TOP     = $00
    CENTER  = $10
    BOTTOM  = $20
.endscope

.scope FmvHelper
    .import getVideoStatus
    .import waitVBlank
    .import discardVBlank
    .import playVideo
    .import pauseVideo
    .import stopVideo
.endscope

.macro m_FmvInit fpsConfigValue, VerticalAlignValue, srcName, srcIncludePath 
    ; Check that fps value is supported
    .if .xmatch(fpsConfigValue, FpsConfig::NTSC_30)
        .out "FMV: FPS = NTSC_30"
        setThis_DP FmvObject
        lda #FpsConfig::NTSC_30
        sta FmvClass::fpsValue
        unsetThis_DP 
    .elseif .xmatch(fpsConfigValue, FpsConfig::NTSC_24)
        .out "FMV: FPS = NTSC_24"
        setThis_DP FmvObject
        lda #FpsConfig::NTSC_24
        sta FmvClass::fpsValue
        unsetThis_DP 
    .else 
        .error .sprintf("Unsupported fps value [%s]", .string(fpsConfigValue))
    .endif

    ; Check that vertical aligne value is supported
    .if .xmatch(VerticalAlignValue, VerticalAlign::TOP) 
        ; --- Setup irqTableVCountValues
        ldx #$00C1
        stx irqTableVCountValues
        ldx #$102
        stx irqTableVCountValues+2
        ldx #$105
        stx irqTableVCountValues+4
        ; --- Set VerticalAlignValue
        ldx #$0000 
        stx verticalAlignOffset
    .elseif .xmatch(VerticalAlignValue, VerticalAlign::CENTER) \
        .or .xmatch(VerticalAlignValue, VerticalAlign::BOTTOM)
        ; --- Setup irqTableVCountValues
        ldx #($00C1 + VerticalAlignValue)
        stx irqTableVCountValues
        ldx #(($0101 + VerticalAlignValue) .mod 261)
        stx irqTableVCountValues+2
        ldx #(($0104 + VerticalAlignValue) .mod 261)
        stx irqTableVCountValues+4
        ; --- Set VerticalAlignValue
        ldx #.loword($0000 - VerticalAlignValue - 1)
        stx verticalAlignOffset
    .else
         .error .sprintf("Unsupported vertical aliggn value [%s]", .string(VerticalAlignValue))
    .endif

    ; Include source file
    .out .concat("FMV: SOURCE = ", .string(srcName))
    .ifnblank srcIncludePath
        .out .sprintf("DEBUG: include %s file from include path", .string(srcIncludePath))
        .include .sprintf("%s", .string(srcIncludePath))
    .else
        .out .sprintf("DEBUG: include fmvSource%s.inc file from source name", .string(srcName))
        .include .sprintf("fmvSource%s.inc", .string(srcName))
    .endif

    ; TODO I would like to check if function are defined
    ; FmvSource::init
    ; FmvSource::getTileSize

    ; TODO call Msu1Detect

    jsr FmvInit
.endmacro

.endif