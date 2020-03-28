/**************************************/
.include "source/ulc/ulc_Specs.inc"
/**************************************/
.section .iwram, "ax", %progbits
.balign 4
/**************************************/

.macro NextNybble
	ADDS	r6, r6, #0x20000000 @ More nybbles?
	LDRCS	r7, [r6, #0x04]!    @  No:  Move to next data
	MOVCC	r7, r7, lsr #0x04   @  Yes: Move to next nybble
.endm

/**************************************/

@ Return values:
@  Anything less than 0: Nothing to process
@  1: A block was decoded
@  0: End of stream

ulc_BlockProcess:
	STMFD	sp!, {r4-fp,lr}
	LDR	r4, =ulc_State
0:	LDRH	r0, [r4, #0x00] @ --nBufProc?
	SUBS	r0, r0, #0x0100
	BCC	.LExit          @  Return something < 0 for 'nothing to process'
	TST	r0, #0x01
	EOR	r0, r0, #0x01   @ WrBufIdx ^= 1?
	STRH	r0, [r4, #0x00]
0:	LDR	r5, =ulc_OutputBuffer
	LDR	fp, [r4, #0x10] @  BlockSize -> fp
	LDR	r1, [r4, #0x04] @  nBlkRem   -> r1
	LDR	r6, [r4, #0x0C] @ &NextData  -> r6
	ADDNE	r5, r5, fp      @ Skip to second buffer as needed
	SUBS	r1, r1, #0x01   @ --nBlkRem?
	STRCS	r1, [r4, #0x04]
	BCC	.LNoBlocksRem
1:	AND	r0, r6, #0x03   @ Prepare reader (StreamData -> r7)
	LDR	r7, [r6, -r0]!
	ORR	r6, r6, r0, lsl #0x20-3+1 @ [Two nybbles per byte, hence +1]
	MOVS	r0, r0, lsl #0x03
	MOVNE	r7, r7, lsr r0
	MOV	r8, #0x00       @ 0 -> r8
	MOV	r9, #0x06C0     @ "MOV r0, r0, asr #0x18+4-15", lower HWord -> r9
	LDR	sl, =ulc_TransformBuffer
1:	AND	r0, r7, #0x0F   @ NextOverlap = BlockSize >> Nybble()
	MOV	r0, fp, lsr r0
	LDR	ip, [r4, #0x14] @ Read BlockOverlap from state, and store NextOverlap
	STR	r0, [r4, #0x14]
	STMFD	sp!, {fp,ip}    @ BlockSize -> sp+00h, BlockOverlap -> sp+04h
	NextNybble

/**************************************/

@ r4: &State
@ r5: &OutputBuf | Chan<<31
@ r6: &NextData | NybbleCounter<<29
@ r7:  StreamData
@ r8:  0
@ r9:  0x06C0
@ sl: &CoefDst
@ fp:  BlockSize | -CoefRem<<16
@ sp+00h: BlockSize
@ sp+04h: BlockOverlap

.LChannels_Loop:
	SUB	fp, fp, fp, lsl #0x10
	B	.LDecodeCoefs_Start

.LDecodeCoefs_ChangeQuant:
	NextNybble

.LDecodeCoefs_Start:
	AND	r0, r7, #0x0F
	NextNybble
	CMP	r0, #0x0E @ Stop? (8h,0h,Fh)
	BHI	.LDecodeCoefs_Stop
	BNE	1f
0:	AND	r0, r6, #0x0F         @ Extended-precision quantizer (8h,0h,Eh,Xh)
	NextNybble
	ADD	r0, r0, #0x0E
	CMP	r0, #0x13             @ Limit ASR value to 31, otherwise turn "ASR #x" into "LSR #20h"
	MOVCS	r0, #0x0020
1:	ADDCC	r0, r9, r0, lsl #0x07 @ Form "MOV r0, r0, asr #0x0D+n", lower hword (06C0h + n<<7)
	STRH	r0, .LDecodeCoefs_Normal_Shifter

.LDecodeCoefs_DecodeLoop:
	SUBS	r0, r8, r7, lsl #0x1C    @ -QCoef -> r0?
	BVS	.LDecodeCoefs_EscapeCode @ Escape code? (8h)

.LDecodeCoefs_Normal:
	NextNybble
	MOVS	r1, r0, asr #0x10 @ 4.12fxp
	MULNE	r0, r1, r1        @ 7.24fxp <- Non-linear quantization (technically 8.24fxp but lost sign bit)
	RSBMI	r0, r0, #0x00
.LDecodeCoefs_Normal_Shifter:
	MOV	r0, r0, asr #0x00 @ Coef=QCoef*2^(-24+16-Quant) -> r0 (NOTE: Self-modifying dequantization)
	STR	r0, [sl], #0x04   @ Coefs[n++] = Coef
	ADDS	fp, fp, #0x01<<16 @ --CoefRem?
	BCC	.LDecodeCoefs_DecodeLoop
1:	B	.LDecodeCoefs_NoMoreCoefs

.LDecodeCoefs_EscapeCode:
	NextNybble
	ANDS	r0, r7, #0x0F @ Quantizer change? (8h,0h,Xh)
	BEQ	.LDecodeCoefs_ChangeQuant
	NextNybble
1:	CMP	r0, #0x0C     @ Short?
	BCC	2f
1:	ORR	r0, r0, r7, lsl #0x1C @ Long: 8h,Ch..Fh,Xh -> 26..152 zeros
	MOV	r0, r0, ror #0x1C
	ADD	r0, r0, #(26-2)/2 - (0xC<<4)
	NextNybble
2:	ADD	fp, fp, r0, lsl #0x01+16 @ CoefRem -= (zR-1)*2
	MOV	r1, #0x00
20:	STMIA	sl!, {r1,r8}
	SUBS	r0, r0, #0x01
	BCS	20b
3:	ADDS	fp, fp, #0x02<<16 @ CoefRem -= 2? (because biased earlier)
	BCC	.LDecodeCoefs_DecodeLoop
	B	.LDecodeCoefs_NoMoreCoefs

.LDecodeCoefs_Stop:
	MOV	r0, #0x00
	MOV	r1, #0x00
	MOV	r2, #0x00
	RSB	ip, fp, #0x010000
	MOVS	ip, ip, lsr #0x01+16
	STRCS	r0, [sl], #0x04
	MOVS	ip, ip, lsr #0x01
	STMCSIA	sl!, {r0-r1}
1:	STMNEIA	sl!, {r0-r2,r8}
	SUBNES	ip, ip, #0x01
	BNE	1b
2:	MOV	fp, fp, lsl #0x10 @ Clear CoefRem
	MOV	fp, fp, lsr #0x10

.LDecodeCoefs_NoMoreCoefs:
	SUB	sl, sl, fp, lsl #0x02 @ Rewind buffer

/**************************************/

@ r0:
@ r1:
@ r2:
@ r3:
@ r4: &State
@ r5: &OutputBuf | Chan<<31
@ r6: &NextData | NybbleCounter<<29
@ r7:  StreamData
@ r8:  0
@ r9:  0x06C0
@ sl: &CoefBuf
@ fp:  BlockSize
@ ip:
@ lr:
@ sp+00h: BlockSize
@ sp+04h: BlockOverlap

.LDecodeCoefs_BlockUnpack:
	STMFD	sp!, {r4-r9}

.LDecodeCoefs_IMDCT:
	MOV	r0, sl
	ADD	r1, sl, fp, lsl #0x02
	MOV	r2, fp
	BL	Fourier_DCT4
0:	LDR	r0, [sp, #0x1C]           @ BlockOverlap -> r0
	LDR	ip, [sp, #0x04]           @ OutLo = OutBuf+0
	MOV	r9, #0x7F
	SUB	r9, r9, fp, lsl #0x10     @ 0x7F | -BlockSize<<16 -> r9
	SUB	sl, sl, r9, asr #0x10+1-2 @ Tmp   = TmpBuf+N/2 (forwards)
	LDR	fp, =ulc_LappingBuffer    @ Lap   = LapBuf+N/2 (backwards)
	SUB	fp, fp, r9, asr #0x10+1-2
.if ULC_STEREO
	TST	ip, #0x80000000
	SUBNE	ip, ip, r9, asr #0x10-1
	SUBNE	fp, fp, r9, asr #0x10+1-2
	BIC	ip, ip, #0x80000000
.endif
	SUB	lr, ip, r9, asr #0x10     @ OutHi = OutLo + BlockSize
	ADDS	r9, r9, r0, lsl #0x10     @ Have non-overlap samples?
	BCS	.LDecodeCoefs_IMDCT_Overlapped

.LDecodeCoefs_IMDCT_NonOverlapped:
1:	LDMDB	fp!, {r0-r7}
	MOV	r0, r0, asr #0x08
	MOV	r1, r1, asr #0x08
	MOV	r2, r2, asr #0x08
	MOV	r3, r3, asr #0x08
	MOV	r4, r4, asr #0x08
	MOV	r5, r5, asr #0x08
	MOV	r6, r6, asr #0x08
	MOV	r7, r7, asr #0x08
	TEQ	r0, r0, lsl #0x18
	ADCMI	r0, r9, #0x00
	TEQ	r1, r1, lsl #0x18
	ADCMI	r1, r9, #0x00
	TEQ	r2, r2, lsl #0x18
	ADCMI	r2, r9, #0x00
	TEQ	r3, r3, lsl #0x18
	ADCMI	r3, r9, #0x00
	TEQ	r4, r4, lsl #0x18
	ADCMI	r4, r9, #0x00
	TEQ	r5, r5, lsl #0x18
	ADCMI	r5, r9, #0x00
	TEQ	r6, r6, lsl #0x18
	ADCMI	r6, r9, #0x00
	TEQ	r7, r7, lsl #0x18
	ADCMI	r7, r9, #0x00
	AND	r7, r7, #0xFF
	AND	r6, r6, #0xFF
	ORR	r7, r7, r6, lsl #0x08
	AND	r5, r5, #0xFF
	ORR	r7, r7, r5, lsl #0x10
	ORR	r7, r7, r4, lsl #0x18
	AND	r8, r3, #0xFF
	AND	r2, r2, #0xFF
	ORR	r8, r8, r2, lsl #0x08
	AND	r1, r1, #0xFF
	ORR	r8, r8, r1, lsl #0x10
	ORR	r8, r8, r0, lsl #0x18
	STMIA	ip!, {r7-r8}
	LDMIA	sl!, {r0-r7}
	MOV	r0, r0, asr #0x08
	MOV	r1, r1, asr #0x08
	MOV	r2, r2, asr #0x08
	MOV	r3, r3, asr #0x08
	MOV	r4, r4, asr #0x08
	MOV	r5, r5, asr #0x08
	MOV	r6, r6, asr #0x08
	MOV	r7, r7, asr #0x08
	TEQ	r0, r0, lsl #0x18
	ADCMI	r0, r9, #0x00
	TEQ	r1, r1, lsl #0x18
	ADCMI	r1, r9, #0x00
	TEQ	r2, r2, lsl #0x18
	ADCMI	r2, r9, #0x00
	TEQ	r3, r3, lsl #0x18
	ADCMI	r3, r9, #0x00
	TEQ	r4, r4, lsl #0x18
	ADCMI	r4, r9, #0x00
	TEQ	r5, r5, lsl #0x18
	ADCMI	r5, r9, #0x00
	TEQ	r6, r6, lsl #0x18
	ADCMI	r6, r9, #0x00
	TEQ	r7, r7, lsl #0x18
	ADCMI	r7, r9, #0x00
	AND	r3, r3, #0xFF
	AND	r2, r2, #0xFF
	ORR	r3, r3, r2, lsl #0x08
	AND	r1, r1, #0xFF
	ORR	r3, r3, r1, lsl #0x10
	ORR	r3, r3, r0, lsl #0x18
	AND	r2, r7, #0xFF
	AND	r6, r6, #0xFF
	ORR	r2, r2, r6, lsl #0x08
	AND	r5, r5, #0xFF
	ORR	r2, r2, r5, lsl #0x10
	ORR	r2, r2, r4, lsl #0x18
	STMDB	lr!, {r2-r3}
2:	ADDS	r9, r9, #0x10<<16
	BCC	1b

@ NOTE: Overlap cannot be 0, so no need to check for that here
.LDecodeCoefs_IMDCT_Overlapped:
	LDR	r8, =Fourier_DCT4_CosSin - 0x04*(16/2)
	ADD	r4, sp, #0x18
	LDMIA	r4, {r4,r5}           @ BlockSize -> r4, BlockOverlap -> r5
	MOV	r9, #0x80000000
	ADD	r8, r8, r5, lsl #0x02-1
1:	LDR	r6, [r8], #0x04
	LDR	r0, [fp, #-0x04]!     @ a = *--Lap
	LDR	r1, [sl], #0x04       @ b = *Tmp++
	MOV	r7, r6, lsr #0x10     @ s -> r7
	BIC	r6, r6, r7, lsl #0x10 @ c -> r6
	MUL	r5, r7, r0            @ *--OutHi = s*a + c*b
	MLA	r5, r6, r1, r5
	@ stall
	ADDS	r5, r5, r5
	ADDVS	r5, r9, r5, asr #0x1F
	MOV	r3, r3, lsl #0x08
	ORR	r3, r3, r5, lsr #0x18
	MUL	r5, r6, r0            @ *OutLo++ = c*a - s*b
	MUL	r1, r7, r1
	@ stall
	SUB	r5, r5, r1
	ADDS	r5, r5, r5
	ADDVS	r5, r9, r5, asr #0x1F
	AND	r5, r5, #0xFF000000
	ORR	r2, r5, r2, lsr #0x08
0:	ADDS	ip, ip, #0x40000000 @ Repeat until have 4 samples in each register
	BCC	1b
	STR	r2, [ip], #0x04
	STR	r3, [lr, #-0x04]!
2:	CMP	ip, lr
	BNE	1b

.LDecodeCoefs_IMDCT_CopyAliasing:
	SUB	r9, r4, r4, lsl #0x10
	SUB	sl, sl, r4, lsl #0x02
1:	LDMIA	sl!, {r0-r7}
	STMIA	fp!, {r0-r7}
	LDMIA	sl!, {r0-r7}
	STMIA	fp!, {r0-r7}
	ADDS	r9, r9, #0x10*2<<16 @ Only copying half the samples, hence *2
	BCC	1b
0:	SUB	sl, sl, r9, lsl #0x02-0x01 @ Rewind buffer
	MOV	fp, r9 @ ResetCoefRem=BlockSize
	LDMFD	sp!, {r4-r9}

.LDecodeCoefs_NextChan:
.if ULC_STEREO
	ADDS	r5, r5, #0x80000000
	BCC	.LChannels_Loop
.endif

/**************************************/

.if ULC_STEREO && ULC_MIDSIDE_XFM
.LMidSideXfm:
	MOV	r7, #0x80000000
	MOV	r8, fp
	MOV	r9, fp
1:	LDR	r0, [r5]
	LDR	r1, [r5, r9, lsl #0x01]
0:	MOV	ip, r0, lsl #0x18
	ADDS	r2, ip, r1, lsl #0x18
	ADDVS	r2, r7, r2, asr #0x1F
	SUBS	r3, ip, r1, lsl #0x18
	ADDVS	r3, r7, r3, asr #0x1F
	AND	r2, r2, #0xFF<<24
	AND	r3, r3, #0xFF<<24
	ORR	r0, r2, r0, lsr #0x08
	ORR	r1, r3, r1, lsr #0x08
	ADDS	r8, r8, #0x40000000
	BCC	0b
2:	STR	r1, [r5, r9, lsl #0x01]
	STR	r0, [r5], #0x04
	SUBS	r8, r8, #0x04
	BNE	1b
.endif

/**************************************/

@ r4: &State
@ r6: &NextData | NybbleCounter<<29

.LSaveState_Exit:
	MOVS	ip, r6, lsr #0x1D+1 @ Get bytes to advance by (C countains nybble rounding)
	BIC	r6, r6, #0xE0000000 @ Clear nybble counter
	ADC	r6, r6, ip
	STR	r6, [r4, #0x0C]
	ADD	sp, sp, #0x08 @ Pop BlockSize, BlockOverlap
	MOV	r0, #0x01 @ Return 'block was decoded'

.LExit:
	LDMFD	sp!, {r4-fp,lr}
	BX	lr

/**************************************/

.LNoBlocksRem:
	MOV	r0, #0x00
	MOV	r1, #0x00
	MOV	r2, #0x00
	MOV	r3, #0x00
	MOV	r4, #0x00
	MOV	r6, #0x00
	MOV	r7, #0x00
	MOV	r8, #0x00
	MOV	r9, #MAX_BLOCK_SIZE
.if ULC_STEREO
	ADD	sl, r5, #MAX_BLOCK_SIZE*2
.endif
1:	STMIA	r5!, {r0-r4,r6-r8}
	STMIA	r5!, {r0-r4,r6-r8}
	STMIA	r5!, {r0-r4,r6-r8}
	STMIA	r5!, {r0-r4,r6-r8}
.if ULC_STEREO
	STMIA	sl!, {r0-r4,r6-r8}
	STMIA	sl!, {r0-r4,r6-r8}
	STMIA	sl!, {r0-r4,r6-r8}
	STMIA	sl!, {r0-r4,r6-r8}
.endif
	SUBS	r9, r9, #0x08*16
	BNE	1b
2:	MOV	r2, #0x04000000
	STRH	r2, [r2, #0x82]   @ Disable DMA audio
	STR	r2, [r2, #0xC4]   @ Disable DMA1
.if ULC_STEREO
	STR	r2, [r2, #0xD0]   @ Disable DMA2
.endif
	STR	r2, [r2, #0x0100] @ Disable TM0
	STR	r2, [r2, #0x0104] @ Disable TM1
3:	@MOV	r0, #0x00 @ Return 'end of stream'
	B	.LExit

/**************************************/
.size   ulc_BlockProcess, .-ulc_BlockProcess
.global ulc_BlockProcess
/**************************************/
.section .bss
.balign 4
/**************************************/

ulc_TransformBuffer:
	.space 0x04 * MAX_BLOCK_SIZE
.size ulc_TransformBuffer, .-ulc_TransformBuffer

ulc_TransformTemp:
	.space 0x04 * MAX_BLOCK_SIZE
.size ulc_TransformTemp, .-ulc_TransformTemp

ulc_LappingBuffer:
	.space 0x04 * (MAX_BLOCK_SIZE/2)
.if ULC_STEREO
	.space 0x04 * (MAX_BLOCK_SIZE/2)
.endif
.size ulc_LappingBuffer, .-ulc_LappingBuffer

/**************************************/
/* EOF                                */
/**************************************/
