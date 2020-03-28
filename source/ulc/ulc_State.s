/**************************************/
.include "source/ulc/ulc_Specs.inc"
/**************************************/
.text
.balign 2
/**************************************/

@ r0: &SoundFile

.thumb
.thumb_func
ulc_Init:
	PUSH	{r4,lr}
	LDR	r2, [r0, #0x00] @ File.Magic -> r2
	LDR	r4, [r0, #0x10] @ File.BlockSize -> r4
	LDR	r3, =ULC_FILE_MAGIC
0:	CMP	r2, r3                         @ Signature mismatch?
	BNE	.LInit_Exit_Fail
	LDRH	r2, [r0, #0x14]                @ File.nChan -> r2
	LSR	r3, r4, #MAX_BLOCK_SIZE_LOG2+1 @ Incompatible block size?
	BNE	.LInit_Exit_Fail
	LDR	r3, =0x077CB531
	CMP	r2, #0x01+ULC_STEREO           @ Incompatible number of channels?
	BNE	.LInit_Exit_Fail
	MUL	r3, r4                         @ Log2(BlockSize) -> r2
	LDR	r2, =_IRQProc_Log2Tab
	LSR	r3, #0x20-5
	LDRB	r2, [r2, r3]
	LDR	r3, [r0, #0x08]                @ File.nSamp -> r3
	LDR	r1, =ulc_State
	ADD	r3, r4                         @ State.nBlkRem = File.nSamp/BlockSize + 1
	LSR	r3, r2
	MOV	r2, #0x00
	STMIA	r1!, {r2,r3}                   @ WrBufIdx = 0, nBufProc = 0, RdBufIdx = 0
	MOV	r2, #0x18                      @ State.NextData    = File.SkipHeader()
	ADD	r2, r0
	STMIA	r1!, {r0,r2,r4}                @ State.SoundFile   = File, State.BlockSize = BlockSize
	STR	r4, [r1]                       @ State.NextOverlap = BlockSize (not important, as long as 2^(4+n))
1:	LDR	r1, [r0, #0x0C]                @ Period = HW_RATE / RateHz -> r0
	MOV	r0, #0x01
	LSL	r0, #0x18
	BL	__aeabi_uidiv

.LInit_SetupHardware:
	LDR	r2, =_IRQTable     @ Set TM1 (BufferEnd) interrupt handler
	LDR	r3, =ulc_TM1Proc
	LDR	r1, =0x04000080    @ &SOUNDCNT -> r1
	STR	r3, [r2, #0x04*4]
.if ULC_STEREO
	LDR	r2, =0x9A0C        @ FIFOB 100%, FIFOB 100%, FIFOA -> L, FIFOB -> R, FIFOA reset, FIFOB reset
.else
	LDR	r2, =0x0B04        @ FIFOA 100%,             FIFOA -> L, FIFOA -> R, FIFOA reset
.endif
	STR	r1, [r1, #0x04]    @ Master enable for audio (Bit7)
	STRH	r2, [r1, #0x02]    @ Store DMA audio control
1:	ADD	r1, #0x0100-0x80   @ &TM0 -> r1
	MOV	r2, #0x81          @ TM0 = ENABLE, Period = HW_RATE / RateHz
	LSL	r2, #0x10
	STRH	r2, [r1, #0x02]    @ [TM0CNT = 0, safety]
	STRH	r2, [r1, #0x06]    @ [TM1CNT = 0, safety]
	SUB	r2, r0
	MOV	r3, #0xC5          @ TM1 = ENABLE|IRQ|SLAVE, Period = BlockSize
	LSL	r3, #0x10
	SUB	r3, r4
	STMIA	r1!, {r2-r3}       @ Start timers (TM0 for sound FIFO, TM1 for BufferEnd interrupt)
	MOV	r0, #0x0200-0x0108 @ &IE -> r0
	ADD	r0, r1
	LDRH	r2, [r0]           @ IE |= TM1
	MOV	r3, #0x01<<4
	ORR	r2, r3
	STRH	r2, [r0]
2:	SUB	r1, #0x0108 - 0xBC @ &DMA1 -> r1
	LDR	r0, =ulc_OutputBuffer
	MOV	r2, #0xBC-0xA0     @ DMA1.Dst = &FIFOA -> r2
	SUB	r2, r1, r2
	MOV	r3, #0xB6          @ DMA1.Cnt = DST_INC, SRC_INC, REPT, WORDS, SOUNDFIFO, ENABLE
	LSL	r3, #0x18
	STRH	r3, [r1, #0x0A]    @ [CNT_H=0, safety]
	STMIA	r1!, {r0,r2,r3}
.if ULC_STEREO
	ADD	r0, r4             @ Double-buffered, so skip two buffers for the right channel
	ADD	r0, r4
	ADD	r2, #0x04          @ DMA2.Dst = &FIFOB -> r2
	STRH	r3, [r1, #0x0A]
	STMIA	r1!, {r0,r2,r3}
.endif

.LInit_Exit_Okay:
	MOV	r0, #0x01 @ Return TRUE
	POP	{r4}
	POP	{r3}
	BX	r3

.LInit_Exit_Fail:
	MOV	r0, #0x00 @ Return FALSE
	POP	{r4}
	POP	{r3}
	BX	r3

/**************************************/
.size   ulc_Init, .-ulc_Init
.global ulc_Init
/**************************************/
.section .iwram, "ax", %progbits
.balign 2
/**************************************/

.thumb
.thumb_func
ulc_TM1Proc:
	LDR	r0, =ulc_State
	MOV	r2, #0x01
	LDRB	r1, [r0, #0x02] @ RdBufIdx ^= 1?
	EOR	r2, r1
	BNE	2f
1:	LSL	r1, #0x1A       @ &REG_BASE -> r1
	ADD	r1, #0xC6       @ &DMA1.CNT_H -> r1
	LDRH	r3, [r1, #0x00] @ DMA1.CNT_H(=B600h) -> r3
	STRH	r2, [r1, #0x00] @ DMA1.CNT_H = 0
	STRH	r3, [r1, #0x00] @ Restart DMA1
.if ULC_STEREO
	STRH	r2, [r1, #0x0C] @ DMA2.CNT_H = 0
	STRH	r3, [r1, #0x0C] @ Restart DMA2
.endif
2:	LDRB	r1, [r0, #0x01] @ nBufProc++
	STRB	r2, [r0, #0x02]
	ADD	r1, #0x01
	STRB	r1, [r0, #0x01]
	BX	lr

/**************************************/
.size ulc_TM1Proc, .-ulc_TM1Proc
/**************************************/
.section .sbss
.balign 4
/**************************************/

ulc_State:
	.byte 0 @ [00h]  WrBufIdx
	.byte 0 @ [01h]  nBufProc
	.byte 0 @ [02h]  RdBufIdx
	.byte 0 @ [03h]
	.word 0 @ [04h]  nBlkRem
	.word 0 @ [08h] &SoundFile
	.word 0 @ [0Ch] &NextData
	.word 0 @ [10h]  BlockSize
	.word 0 @ [14h]  NextOverlap
.size   ulc_State, .-ulc_State
.global ulc_State

/**************************************/

ulc_OutputBuffer:
	.space 0x01 * 2*MAX_BLOCK_SIZE @ Double-buffered output
.if ULC_STEREO
	.space 0x01 * 2*MAX_BLOCK_SIZE
.endif
.size   ulc_OutputBuffer, .-ulc_OutputBuffer
.global ulc_OutputBuffer

/**************************************/
/* EOF                                */
/**************************************/
