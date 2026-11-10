.ifndef __FMV_SOURCE_INC
__FMV_SOURCE_INC = 1

.struct FmvSource   
    init                            .word ; Pointer to init function
    getTileSize                     .word ; Pointer to getTileSize function
    procDmaStreamBufferPrepare      .word
    procDmaStreamTileFull           .word 
    procDmaStreamTileBig            .word 
    procDmaStreamTileSmall          .word 
    procDmaStreamMap                .word
    procDmaStreamPalette            .word
    procDmaStartTransfer            .word
    procPlayVideo                   .word
    procPauseVideo                  .word
    procStopVideo                   .word
    palSkip                         .byte
    palOffset                       .byte
    palSize                         .word
    mapSkip                         .byte
    mapSize                         .word    
.endstruct

.endif