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
	LDR	r2, [r0, #0x00]
	LDR	r3, =ULC_FILE_MAGIC
	CMP	r2, r3
	BNE	.LInit_BadHeader
	LDR	r2, [r0, #0x10]
	LDR	r3, =BLOCK_SIZE + BLOCK_OVERLAP<<16
	SUB	r2, r3
	BNE	.LInit_BadHeader
	LDRH	r3, [r0, #0x14]
.if ULC_STEREO
	CMP	r3, #0x02
.else
	CMP	r3, #0x01
.endif
	BNE	.LInit_BadHeader
0:	MOV	ip, r0
	PUSH	{lr}
0:	LDR	r1, =ulc_State
	@MOV	r2, #0x00       @ [already 0 from above]
	STR	r2, [r1, #0x00] @ WrBufIdx = 0, nBufProc = 0, RdBufIdx = 0
	STR	r0, [r1, #0x0C] @ SoundFile
	LDR	r2, [r0, #0x08] @ nBlkRem = nSamp/BLOCK_SIZE+1
	LSR	r2, #BLOCK_SIZE_LOG2
	ADD	r2, #0x01
	STR	r2, [r1, #0x04]
	ADD	r0, #0x18       @ NextByte = Data + sizeof(Header)
	STR	r0, [r1, #0x08]
0:	LDR	r0, =_IRQTable     @ Set TM1 (buffer end) interrupt handler
	LDR	r1, =ulc_TM1Proc
	STR	r1, [r0, #0x04*4]
0:	LDR	r0, =0x04000080    @ &SOUNDCNT -> r0
.if ULC_STEREO
	LDR	r1, =0x9A0C0000    @ FIFOB 100%, FIFOB 100%, FIFOA -> L, FIFOB -> R, FIFOA reset, FIFOB reset
.else
	LDR	r1, =0x0B040000    @ FIFOA 100%, FIFOA -> L+R, FIFOA reset
.endif
	STR	r0, [r0, #0x04]    @ Master enable (bit 7)
	STR	r1, [r0]
0:	ADD	r0, #0xBC-0x80     @ &DMA1.{SAD,DAD,CNT}
	LDR	r1, =ulc_OutputBuffer
	MOV	r2, #0xBC-0xA0     @ &FIFO_A
	SUB	r2, r0, r2
	MOV	r3, #0xB6          @ DST_INC, SRC_INC, REPT, WORDS, SOUNDFIFO, ENABLE
	LSL	r3, #0x18
	STRH	r3, [r0, #0x0A]    @ [CNT_H=0]
	STMIA	r0!, {r1-r3}
.if ULC_STEREO
	LDR	r1, =ulc_OutputBuffer + 2*BLOCK_SIZE
	ADD	r2, #0x04
	STRH	r3, [r0, #0x0A]
	STMIA	r0!, {r1-r3}
.endif
0:	LDR	r0, =16777216      @ Period = HW_RATE / PlaybackRate
	MOV	r1, ip
	LDR	r1, [r1, #0x0C]
	BL	__aeabi_uidiv
	MOV	r2, #0x80 + (0x010000>>16) @ ENABLE
	LSL	r2, #0x10
	SUB	r2, r0
	LDR	r0, =0x04000100
	LDR	r3, =0x00C40000 | (0x010000 - BLOCK_SIZE) @ ENABLE | IRQ | SLAVE
	STMIA	r0!, {r2-r3}       @ Start timers (TM0 for sound FIFO, TM1 for buffer refill)
0:	ADD	r0, #0x0200-0x0108 @ &IE -> r0
	LDRH	r1, [r0]           @ IE |= TM1
	MOV	r2, #0x01<<4
	ORR	r1, r2
	STRH	r1, [r0]
1:	POP	{r0}
	BX	r0

.LInit_BadHeader:
	BX	lr

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
	LDRB	r1, [r0, #0x02] @ RdBufIdx ^= 1?
	MOV	r2, #0x01
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
2:	STRB	r2, [r0, #0x02]
	LDRB	r1, [r0, #0x01] @ nBufProc++
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
	.byte 0 @ [00h] WrBufIdx
	.byte 0 @ [01h] nBufProc
	.byte 0 @ [02h] RdBufIdx
	.byte 0 @ [03h]
	.word 0 @ [04h] nBlkRem
	.word 0 @ [08h] &NextByte
	.word 0 @ [0Ch] &SoundFile
.size   ulc_State, .-ulc_State
.global ulc_State

/**************************************/

ulc_OutputBuffer:
	.space 2*BLOCK_SIZE
.if ULC_STEREO
	.space 2*BLOCK_SIZE
.endif
.size   ulc_OutputBuffer, .-ulc_OutputBuffer
.global ulc_OutputBuffer

/**************************************/
/* EOF                                */
/**************************************/
