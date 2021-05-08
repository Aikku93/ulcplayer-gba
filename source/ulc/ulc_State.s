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
	LDRH	r4, [r0, #0x04] @ File.BlockSize -> r4
	LDR	r3, =ULC_FILE_MAGIC
0:	CMP	r2, r3                             @ Signature mismatch?
	BNE	.LInit_Exit_Fail
	LDRH	r2, [r0, #0x10]                    @ File.nChan -> r2
	LSR	r3, r4, #ULC_MAX_BLOCK_SIZE_LOG2+1 @ Incompatible block size?
	BNE	.LInit_Exit_Fail
	LDR	r3, =0x077CB531
.if ULC_STEREO_SUPPORT
	SUB	r1, r2, #0x01                      @ Incompatible number of channels?
	MOV	ip, r1                             @ [IsStereo -> ip]
	CMP	r1, #0x02-1
	BHI	.LInit_Exit_Fail
.else
	CMP	r2, #0x01
	BNE	.LInit_Exit_Fail
.endif
	MUL	r3, r4                         @ Log2(BlockSize) -> r2
	LDR	r2, =_IRQProc_Log2Tab
	LSR	r3, #0x20-5
	LDRB	r2, [r2, r3]
	LDR	r3, [r0, #0x08]                @ State.nBlkRem = File.nBlocks-1 -> r3
	LDR	r1, =ulc_State
	SUB	r3, #0x01                      @ NOTE: -1 because we count by using the -CS condition
	LSL	r3, #0x02                      @ WrBufIdx=0 | Pause=0
	MOV	r2, #0x00
	STMIA	r1!, {r2,r3}                   @ RdBufIdx = 0,nBufProc = 0,LastSubBlockSize = 0, store WrBufIdx|nBlkRem<<1
	LDR	r2, [r0, #0x14]                @ File.StreamOffs -> r2
	ADD	r2, r0                         @ State.SoundFile = File, State.NextData = File + StreamOffs
	STMIA	r1!, {r0,r2}
.if ULC_STEREO_SUPPORT
	ADD	r4, r4                         @ IsStereo | BlockSize<<1 -> r4
	ADD	r4, ip
.endif
1:	LDR	r1, [r0, #0x0C]                @ Period = Ceil[HW_RATE / RateHz] -> r0
	MOV	r0, #0x01
	LSL	r0, #0x18
	SUB	r0, #0x01
	BL	__aeabi_uidiv
	@ADD	r0, #0x01                      @ <- Account for this later

.LInit_ClearBuffers:
	PUSH	{r0}
	LDR	r0, =.LInit_ZeroWord
	LDR	r1, =ulc_OutputBuffer
	LDR	r2, =(((0x01 * ULC_MAX_BLOCK_SIZE*2) * (1+ULC_STEREO_SUPPORT)) / 0x04) | 1<<24 | 1<<26
	SWI	0x0C
	LDR	r0, =.LInit_ZeroWord
	LDR	r1, =ulc_LappingBuffer
	LDR	r2, =((0x04 * (ULC_MAX_BLOCK_SIZE/2) * (1+ULC_STEREO_SUPPORT)) / 0x04) | 1<<24 | 1<<26
	SWI	0x0C
	POP	{r0}

.LInit_SetupHardware:
.if ULC_STEREO_SUPPORT
	LDR	r1, =0x04000080    @ &SOUNDCNT -> r1
	LDR	r2, =_IRQTable
	LSR	r4, #0x01          @ IsStereo? (and restore BlockSize -> r4)
	BCS	2f
1:	LDR	r3, =ulc_TM1Proc_1ch
	STR	r3, [r2, #0x04*4]  @ Set TM1 (BufferEnd) interrupt handler
	LDR	r2, =0x0B04        @ FIFOA 100%,             FIFOA -> L, FIFOA -> R, FIFOA reset
	B	3f
2:	LDR	r3, =ulc_TM1Proc_2ch
	STR	r3, [r2, #0x04*4]
	LDR	r2, =0x9A0C        @ FIFOB 100%, FIFOB 100%, FIFOA -> L, FIFOB -> R, FIFOA reset, FIFOB reset
3:
.else
	LDR	r2, =_IRQTable     @ Set TM1 (BufferEnd) interrupt handler
	LDR	r3, =ulc_TM1Proc_1ch
	LDR	r1, =0x04000080    @ &SOUNDCNT -> r1
	STR	r3, [r2, #0x04*4]
	LDR	r2, =0x0B04        @ FIFOA 100%,             FIFOA -> L, FIFOA -> R, FIFOA reset
.endif
	STR	r1, [r1, #0x04]    @ Master enable for audio (Bit7)
	STRH	r2, [r1, #0x02]    @ Store DMA audio control
.if ULC_STEREO_SUPPORT
	MOV	ip, r2             @ Save DMA audio control -> ip
.endif
1:	ADD	r1, #0x0100-0x80   @ &TM0 -> r1
	MOV	r2, #0x81          @ TM0 = ENABLE, Period = HW_RATE / RateHz
	LSL	r2, #0x10          @ [C=0]
	STRH	r2, [r1, #0x02]    @ [TM0CNT = 0, safety]
	STRH	r2, [r1, #0x06]    @ [TM1CNT = 0, safety]
	SBC	r2, r0             @ [this completes the ceiling division by adding 1 to the off-by-one result]
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
.if ULC_STEREO_SUPPORT
	MOV	r4, ip             @ Stereo has DMA bit 15 set
	LSR	r4, #0x0F
	BEQ	1f
0:	LSL	r4, #ULC_MAX_BLOCK_SIZE_LOG2+1
	ADD	r2, #0x04          @ DMA2.Dst = &FIFOB -> r2
	ADD	r0, r4             @ Advance source to the right-channel buffer
	STRH	r3, [r1, #0x0A]
	STMIA	r1!, {r0,r2,r3}
1:
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

.balign 4
.LInit_ZeroWord: .word 0

/**************************************/
.size   ulc_Init, .-ulc_Init
.global ulc_Init
/**************************************/
.section .iwram, "ax", %progbits
.balign 2
/**************************************/

.thumb
.thumb_func
ulc_TM1Proc_1ch:
	LDR	r0, =ulc_State
	MOV	r2, #0x01
	LDRB	r1, [r0, #0x00] @ RdBufIdx ^= 1?
	EOR	r2, r1
	BNE	2f
1:	LSL	r1, #0x1A       @ &REG_BASE -> r1
	ADD	r1, #0xC6       @ &DMA1.CNT_H -> r1
	LDRH	r3, [r1, #0x00] @ DMA1.CNT_H(=B600h) -> r3
	STRH	r2, [r1, #0x00] @ DMA1.CNT_H = 0
	STRH	r3, [r1, #0x00] @ Restart DMA1
2:	LDRB	r1, [r0, #0x01] @ nBufProc++
	STRB	r2, [r0, #0x00]
	ADD	r1, #0x01
	STRB	r1, [r0, #0x01]
	BX	lr

/**************************************/
.size ulc_TM1Proc_1ch, .-ulc_TM1Proc_1ch
/**************************************/
.if ULC_STEREO_SUPPORT
/**************************************/

.thumb
.thumb_func
ulc_TM1Proc_2ch:
	LDR	r0, =ulc_State
	MOV	r2, #0x01
	LDRB	r1, [r0, #0x00] @ RdBufIdx ^= 1?
	EOR	r2, r1
	BNE	2f
1:	LSL	r1, #0x1A       @ &REG_BASE -> r1
	ADD	r1, #0xC6       @ &DMA1.CNT_H -> r1
	LDRH	r3, [r1, #0x00] @ DMA1.CNT_H(=B600h) -> r3
	STRH	r2, [r1, #0x00] @ DMA1.CNT_H = 0
	STRH	r3, [r1, #0x00] @ Restart DMA1
	STRH	r2, [r1, #0x0C] @ DMA2.CNT_H = 0
	STRH	r3, [r1, #0x0C] @ Restart DMA2
2:	LDRB	r1, [r0, #0x01] @ nBufProc++
	STRB	r2, [r0, #0x00]
	ADD	r1, #0x01
	STRB	r1, [r0, #0x01]
	BX	lr

/**************************************/
.size ulc_TM1Proc_2ch, .-ulc_TM1Proc_2ch
/**************************************/
.endif
/**************************************/
.section .sbss
.balign 4
/**************************************/

ulc_State:
	.byte  0 @ [00h]  RdBufIdx
	.byte  0 @ [01h]  nBufProc
	.hword 0 @ [02h]  LastSubBlockSize
	.word  0 @ [04h]  WrBufIdx | Pause<<1 | nBlkRem<<2
	.word  0 @ [08h] &SoundFile
	.word  0 @ [0Ch] &NextData
.size   ulc_State, .-ulc_State
.global ulc_State

/**************************************/

ulc_OutputBuffer:
	.space (0x01 * ULC_MAX_BLOCK_SIZE*2) * (1+ULC_STEREO_SUPPORT) @ Double-buffered output

.size   ulc_OutputBuffer, .-ulc_OutputBuffer
.global ulc_OutputBuffer

/**************************************/
/* EOF                                */
/**************************************/
