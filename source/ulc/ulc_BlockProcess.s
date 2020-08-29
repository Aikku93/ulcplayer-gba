/**************************************/
.include "source/ulc/ulc_Specs.inc"
/**************************************/
.section .iwram, "ax", %progbits
.balign 4
/**************************************/

.macro NextNybble
	ADDS	r6, r6, #0x01<<29 @ More nybbles?
	LDRCS	r7, [r6, #0x04]!  @  No:  Move to next data
	MOVCC	r7, r7, lsr #0x04 @  Yes: Move to next nybble
.endm

/**************************************/

@ Returns the number of bytes read

ulc_BlockProcess:
	STMFD	sp!, {r4-fp,lr}
	LDR	r4, =ulc_State
	LDR	r5, =ulc_OutputBuffer
	LDRB	r0, [r4, #0x01]           @ nBufProc -> r0
	LDMIB	r4, {r1-r2,r6}            @ WrBufIdx | Pause<<1 | nBlkRem<<2 -> r1, &File -> r2, &NextData -> r6
	CMP	r2, #0x00                 @ !File? Early exit to avoid reading from NULL
	BEQ	.LNoBufProc
	LDR	fp, [r2, #0x10]           @ BlockSize -> fp
.if ULC_STEREO_SUPPORT
	LDRB	r2, [r2, #0x14]           @ nChan -> r2
.endif
0:	AND	ip, r6, #0x03             @ Prepare reader (&NextData | NybbleCounter<<29 -> r6, StreamData -> r7)
	LDR	r7, [r6, -ip]!
	ORR	r6, r6, ip, lsl #0x20-3+1 @ [8 nybbles per word (hence 32-3=29), and 2 nybbles per byte (hence +1)]
	MOVS	ip, ip, lsl #0x03
	MOVNE	r7, r7, lsr ip
.if ULC_STEREO_SUPPORT
	CMP	r2, #0x02                 @ Set stereo flag as needed
	ORREQ	r5, r5, #0x01
.endif
0:	SUBS	r0, r0, #0x01             @ --nBufProc?
	BCC	.LNoBufProc
	STRB	r0, [r4, #0x01]           @ <- This assumes that ulc_BlockProcess is called at least once between timer interrupts (race condition)
	EOR	r1, r1, #0x01             @ WrBufIdx ^= 1
	MOVS	r0, r1, lsl #0x1F         @ N=WrBufIdx?, C=Pause?
	ADDPL	r5, r5, fp                @ Move to second buffer as needed
	BCS	.LOutputPaused
	SUBS	r1, r1, #0x01<<2          @ --nBlkRem?
	BCC	.LNoBlocksRem
	STR	r1, [r4, #0x04]
0:	MOV	r9, #0x8700               @ "MOV r8, r8, asr #0x18+5-15" lower hword (=QScaleBase) -> r9
	ORR	r9, r9, #0x48

.LReadBlockHeader:
	AND	r8, r7, #0x0F         @ QScaleBase | WindowCtrl<<16 -> r9
	ORR	r9, r9, r8, lsl #0x10
	NextNybble
	TST	r8, #0x08             @ Decimating?
	BEQ	1f
0:	ORR	r9, r9, r7, lsl #0x1C @  Append decimation control to upper bits
	NextNybble
1:

/**************************************/

@ r0: 0
@ r1: 0
@ r2: 0
@ r3: 0
@ r4: &State
@ r5: &OutBuf | Chan<<31 | IsStereo
@ r6: &NextData | NybbleCounter<<29
@ r7:  StreamData
@ r8: [Scratch]
@ r9:  QScaleBase | WindowCtrl<<16
@ sl: &CoefDst
@ fp:  BlockSize | -CoefRem<<16
@ ip: [Scratch]
@ lr: [Scratch]
@ NOTE: WindowCtrl is stored as:
@  b0..2:   OverlapScale
@  b3:      Decimation toggle
@  b4..11:  Unused
@  b12..15: Decimation pattern (0b0000 == 0b0001 == No decimation)

.LChannels_Loop:
	MOV	r0, #0x00                    @ 0 -> r0,r1,r2,r3
	MOV	r1, #0x00
	MOV	r2, #0x00
	MOV	r3, #0x00
	LDR	sl, =ulc_TransformBuffer
	TST	r9, #0x08<<16                @ Decimating?
	ADDNE	sl, sl, #0x04*MAX_BLOCK_SIZE @  Store to TempBuffer for deinterleaving to TransformBuffer
	SUB	fp, fp, fp, lsl #0x10
	B	.LDecodeCoefs_Start

.LDecodeCoefs_ChangeQuant:
	NextNybble

.LDecodeCoefs_Start:
	AND	r8, r7, #0x0F
	NextNybble
	CMP	r8, #0x0E @ Stop? (8h,0h,Fh)
	BHI	.LDecodeCoefs_Stop
	BNE	1f
0:	AND	r8, r6, #0x0F         @ Extended-precision quantizer (8h,0h,Eh,Xh)
	NextNybble
	ADD	r8, r8, #0x0E
	CMP	r8, #0x12             @ Limit ASR value to 31, otherwise turn "ASR #x" into "LSR #20h"
	SUBCS	r8, r9, #0x0720
1:	ADDCC	r8, r9, r8, lsl #0x07 @ Modify the quantizer instruction
	STRH	r8, .LDecodeCoefs_Normal_Shifter

.LDecodeCoefs_DecodeLoop:
	SUBS	r8, r0, r7, lsl #0x1C    @ -QCoef -> r8?
	BVS	.LDecodeCoefs_EscapeCode @ Escape code? (8h)

.LDecodeCoefs_Normal:
	NextNybble
	MOVS	ip, r8, asr #0x10 @ 4.12fxp
	MULNE	r8, ip, ip        @ 7.24fxp <- Non-linear quantization (technically 8.24fxp but lost sign bit)
	RSBMI	r8, r8, #0x00
.LDecodeCoefs_Normal_Shifter:
	MOV	r8, r8, asr #0x00 @ Coef=QCoef*2^(-24+16-Quant) -> r8 (NOTE: Self-modifying dequantization)
	STR	r8, [sl], #0x04   @ Coefs[n++] = Coef
	ADDS	fp, fp, #0x01<<16 @ --CoefRem?
	BCC	.LDecodeCoefs_DecodeLoop
1:	B	.LDecodeCoefs_NoMoreCoefs

.LDecodeCoefs_EscapeCode:
	NextNybble
	ANDS	r8, r7, #0x0F @ Quantizer change? (8h,0h,Xh)
	BEQ	.LDecodeCoefs_ChangeQuant
	NextNybble
1:	CMP	r8, #0x0F           @ 8h,1h..Eh:   3.. 16 zeros
	BNE	2f
	AND	r8, r7, #0x0F       @ 8h,Fh,Yh,Xh: 17 .. 272 zeros
	NextNybble
	ORR	r8, r8, r7, lsl #0x1C
	NextNybble
	MOV	r8, r8, ror #0x1C
	ADD	r8, r8, #0x11-2
2:	ADD	r8, r8, #0x02
	ADD	fp, fp, r8, lsl #0x10 @ CoefRem -= zR
	MOVS	ip, r8, lsl #0x1F     @ N=CoefRem&1, C=CoefRem&2
	STRMI	r0, [sl], #0x04
	STMCSIA	sl!, {r0-r1}
	MOVS	r8, r8, lsr #0x02
20:	STMNEIA	sl!, {r0-r3}
	SUBNES	r8, r8, #0x01
	BNE	20b
3:	CMP	fp, #0x010000
	BCS	.LDecodeCoefs_DecodeLoop
	B	.LDecodeCoefs_NoMoreCoefs

.LDecodeCoefs_Stop:
	RSB	r8, fp, #0x010000
	MOVS	r8, r8, lsr #0x01+16
	STRCS	r0, [sl], #0x04
	MOVS	r8, r8, lsr #0x01
	STMCSIA	sl!, {r0-r1}
1:	STMNEIA	sl!, {r0-r3}
	SUBNES	r8, r8, #0x01
	BNE	1b
2:	MOV	fp, fp, lsl #0x10 @ Clear CoefRem
	MOV	fp, fp, lsr #0x10

.LDecodeCoefs_NoMoreCoefs:
	SUB	sl, sl, fp, lsl #0x02 @ Rewind buffer

/**************************************/

.LDecodeCoefs_Deinterleave:
	STMFD	sp!, {r4-r7,r9}
	ANDS	r8, r9, #0xE0000000          @ Lowermost bit controls which side gets overlap scaling only, so ignore it
	SUBNE	r0, sl, #0x04*MAX_BLOCK_SIZE @  DstA = TransformBuffer(=TempBuffer-MAX_BLOCK_SIZE)
	SUBNE	fp, fp, fp, lsl #0x10        @  Cnt  = BlockSize
	LDRNE	pc, [pc, r8, lsr #0x1C+1-2]
	BEQ	.LDecodeCoefs_NoDeinterleave
	.word	.LDecodeCoefs_NoDeinterleave @ Unused
	.word	.LDecodeCoefs_Deinterleave_N2_N2
	.word	.LDecodeCoefs_Deinterleave_N4_N4_N2
	.word	.LDecodeCoefs_Deinterleave_N2_N4_N4
	.word	.LDecodeCoefs_Deinterleave_N8_N8_N4_N2
	.word	.LDecodeCoefs_Deinterleave_N4_N8_N8_N2
	.word	.LDecodeCoefs_Deinterleave_N2_N8_N8_N4
	.word	.LDecodeCoefs_Deinterleave_N2_N4_N8_N8

.LDecodeCoefs_Deinterleave_DecimationPattern:
	.word (0+8)                                   @ 0000: N/1*
	.word (0+8)                                   @ 0001: N/1* (technically unused, maps to above)
	.word (1+8) | (1  )<<4                        @ 0010: N/2* | N/2
	.word (1  ) | (1+8)<<4                        @ 0011: N/2  | N/2*
	.word (2+8) | (2  )<<4 | (1  )<<8             @ 0100: N/4* | N/4  | N/2
	.word (2  ) | (2+8)<<4 | (1  )<<8             @ 0101: N/4  | N/4* | N/2
	.word (1  ) | (2+8)<<4 | (2  )<<8             @ 0110: N/2  | N/4* | N/4
	.word (1  ) | (2  )<<4 | (2+8)<<8             @ 0111: N/2  | N/4  | N/4*
	.word (3+8) | (3  )<<4 | (2  )<<8 | (1  )<<12 @ 1000: N/8* | N/8  | N/4  | N/2
	.word (3  ) | (3+8)<<4 | (2  )<<8 | (1  )<<12 @ 1001: N/8  | N/8* | N/4  | N/2
	.word (2  ) | (3+8)<<4 | (3  )<<8 | (1  )<<12 @ 1010: N/4  | N/8* | N/8  | N/2
	.word (2  ) | (3  )<<4 | (3+8)<<8 | (1  )<<12 @ 1011: N/4  | N/8  | N/8* | N/2
	.word (1  ) | (3+8)<<4 | (3  )<<8 | (2  )<<12 @ 1100: N/2  | N/8* | N/8  | N/4
	.word (1  ) | (3  )<<4 | (3+8)<<8 | (2  )<<12 @ 1101: N/2  | N/8  | N/8* | N/4
	.word (1  ) | (2  )<<4 | (3+8)<<8 | (3  )<<12 @ 1110: N/2  | N/4  | N/8* | N/8
	.word (1  ) | (2  )<<4 | (3  )<<8 | (3+8)<<12 @ 1111: N/2  | N/4  | N/8  | N/8*

@ r0: &DstA
@ r1: &DstB
@ r2: &DstC
@ r3: &DstD
@ r4: [Pushed/Scratch]
@ r5: [Pushed/Scratch]
@ r6: [Pushed/Scratch]
@ r7: [Pushed/Scratch]
@ r8: [Scratch]
@ r9: [Pushed/Scratch]
@ sl: &SrcBuf
@ fp:  BlockSize | -BlockSize<<16
@ ip: [Scratch]
@ lr: [Scratch]
@ sp+00h: &State
@ sp+04h: &OutBuf | Chan<<31 | IsStereo
@ sp+08h: &NextData | NybbleCounter<<29
@ sp+0Ch:  StreamData
@ sp+10h:  QScaleBase | WindowCtrl

.LDecodeCoefs_Deinterleave_N2_N2:
	@MOV	r0, r0                    @ DstA = TransformBuffer
	SUB	r3, r0, fp, asr #0x10+1-2 @ DstB = DstA + N/2
0:	LDMIA	sl!, {r4-r9,ip,lr}
	STMIA	r0!, {r4,r6,r8,ip}
	STMIA	r3!, {r5,r7,r9,lr}
	ADDS	fp, fp, #0x08<<16
	BCC	0b
0:	B	.LDecodeCoefs_DeinterleaveComplete

.LDecodeCoefs_Deinterleave_N4_N4_N2:
	@MOV	r0, r0                    @ DstA = TransformBuffer
	SUB	r2, r0, fp, asr #0x10+2-2 @ DstB = DstA + N/4
	SUB	r3, r2, fp, asr #0x10+2-2 @ DstC = DstB + N/4
0:	LDMIA	sl!, {r4-r9,ip,lr}
	STMIA	r0!, {r4,r8}
	STMIA	r2!, {r5,r9}
	STMIA	r3!, {r6-r7,ip,lr}
	ADDS	fp, fp, #0x08<<16
	BCC	0b
0:	B	.LDecodeCoefs_DeinterleaveComplete

.LDecodeCoefs_Deinterleave_N2_N4_N4:
	@MOV	r0, r0                    @ DstA = TransformBuffer
	SUB	r2, r0, fp, asr #0x10+1-2 @ DstB = DstA + N/2
	SUB	r3, r2, fp, asr #0x10+2-2 @ DstC = DstB + N/4
0:	LDMIA	sl!, {r4-r9,ip,lr}
	STMIA	r0!, {r4-r5,r8-r9}
	STMIA	r2!, {r6,ip}
	STMIA	r3!, {r7,lr}
	ADDS	fp, fp, #0x08<<16
	BCC	0b
0:	B	.LDecodeCoefs_DeinterleaveComplete

.LDecodeCoefs_Deinterleave_N8_N8_N4_N2:
	@MOV	r0, r0                    @ DstA = TransformBuffer
	SUB	r1, r0, fp, asr #0x10+3-2 @ DstB = DstA + N/8
	SUB	r2, r1, fp, asr #0x10+3-2 @ DstC = DstB + N/8
	SUB	r3, r2, fp, asr #0x10+2-2 @ DstD = DstC + N/4
0:	LDMIA	sl!, {r4-r9,ip,lr}
	STR	r4, [r0], #0x04
	STR	r5, [r1], #0x04
	STMIA	r2!, {r6-r7}
	STMIA	r3!, {r8-r9,ip,lr}
	ADDS	fp, fp, #0x08<<16
	BCC	0b
0:	B	.LDecodeCoefs_DeinterleaveComplete

.LDecodeCoefs_Deinterleave_N4_N8_N8_N2:
	@MOV	r0, r0                    @ DstA = TransformBuffer
	SUB	r1, r0, fp, asr #0x10+2-2 @ DstB = DstA + N/4
	SUB	r2, r1, fp, asr #0x10+3-2 @ DstC = DstB + N/8
	SUB	r3, r2, fp, asr #0x10+3-2 @ DstD = DstC + N/8
0:	LDMIA	sl!, {r4-r9,ip,lr}
	STMIA	r0!, {r4-r5}
	STR	r6, [r1], #0x04
	STR	r7, [r2], #0x04
	STMIA	r3!, {r8-r9,ip,lr}
	ADDS	fp, fp, #0x08<<16
	BCC	0b
0:	B	.LDecodeCoefs_DeinterleaveComplete

.LDecodeCoefs_Deinterleave_N2_N8_N8_N4:
	@MOV	r0, r0                    @ DstA = TransformBuffer
	SUB	r1, r0, fp, asr #0x10+1-2 @ DstB = DstA + N/2
	SUB	r2, r1, fp, asr #0x10+3-2 @ DstC = DstB + N/8
	SUB	r3, r2, fp, asr #0x10+3-2 @ DstD = DstC + N/8
0:	LDMIA	sl!, {r4-r9,ip,lr}
	STMIA	r0!, {r4-r7}
	STR	r8, [r1], #0x04
	STR	r9, [r2], #0x04
	STMIA	r3!, {ip,lr}
	ADDS	fp, fp, #0x08<<16
	BCC	0b
0:	B	.LDecodeCoefs_DeinterleaveComplete

.LDecodeCoefs_Deinterleave_N2_N4_N8_N8:
	@MOV	r0, r0                    @ DstA = TransformBuffer
	SUB	r1, r0, fp, asr #0x10+1-2 @ DstB = DstA + N/2
	SUB	r2, r1, fp, asr #0x10+2-2 @ DstC = DstB + N/4
	SUB	r3, r2, fp, asr #0x10+3-2 @ DstD = DstC + N/8
0:	LDMIA	sl!, {r4-r9,ip,lr}
	STMIA	r0!, {r4-r7}
	STMIA	r1!, {r8-r9}
	STR	ip, [r2], #0x04
	STR	lr, [r3], #0x04
	ADDS	fp, fp, #0x08<<16
	BCC	0b
0:	@B	.LDecodeCoefs_DeinterleaveComplete

.LDecodeCoefs_DeinterleaveComplete:
	SUB	sl, r3, fp, lsl #0x02 @ Rewind TransformBuffer(=LastDstBuf-BlockSize) as coefficient source
.LDecodeCoefs_NoDeinterleave:

/**************************************/

@ r0: [Scratch]
@ r1: [Scratch]
@ r2: [Scratch]
@ r3: [Scratch]
@ r4: &OutBuf
@ r5: &LapBuf
@ r6:  DecimationPattern
@ r7:  NextOverlapSize | OverlapSize<<16
@ r8: [Scratch]
@ r9:  OverlapScale | SubBlockSize<<16
@ sl: &TransformBuffer
@ fp:  BlockSize
@ ip: [Scratch]
@ lr: [Scratch]
@ sp+00h: &State
@ sp+04h: &OutBuf | Chan<<31 | IsStereo
@ sp+08h: &NextData | NybbleCounter<<29
@ sp+0Ch:  StreamData
@ sp+10h:  QScaleBase | WindowCtrl

.LDecodeCoefs_SubBlockProcess:
	LDMIA	sp, {r3,r4}                    @ &State -> r3, &OutBuf[ | Chan<<31 | IsStereo] -> r4
	LDRH	r9, [sp, #0x12]
	LDRH	r7, [r3, #0x02]                @ NextOverlapSize -> r7
	ADD	r5, sl, #0x04*MAX_BLOCK_SIZE*2 @ LappingBuffer(=TransformBuffer+2*MAX_BLOCK_SIZE -> r5
.if ULC_STEREO_SUPPORT
	TST	r4, #0x80000000                @ Second channel?
	BIC	r4, r4, #0x80000001            @ [Clear Chan and IsStereo from OutBuf]
	ADDNE	r4, r4, #0x01*MAX_BLOCK_SIZE*2 @  Skip to second channel
	ADDNE	r5, r5, #0x04*MAX_BLOCK_SIZE/2
.endif
	ADR	r8, .LDecodeCoefs_Deinterleave_DecimationPattern
	LDR	r6, [r8, r9, lsr #0x0C-2]      @ DecimationPattern -> r6
	@AND	r9, r9, #0x07                  @ OverlapScale -> r9 (masked on every loop iteration)

.LDecodeCoefs_SubBlockLoop:
	AND	r9, r9, #0x07         @ Clear old SubBlockSize
	AND	r8, r6, #0x07         @ SubBlockSize = BlockSize >> DecimationPattern[SubBlockIdx] -> r8
	MOV	r8, fp, lsr r8
	ORR	r9, r9, r8, lsl #0x10 @ OverlapScale | SubBlockSize<<16 -> r9
	CMP	r7, r8                @ OverlapSize > SubBlockSize?
	MOVHI	r7, r8                @  OverlapSize = SubBlockSize
	MOVS	r6, r6, lsr #0x04     @ Advance subblock decimation. Transient subblock?
	MOVCS	r8, r8, lsr r9        @  Y: NextOverlapSize = SubBlockSize >> OverlapScale
	ORR	r7, r8, r7, lsl #0x10 @  N: NextOverlapSize = SubBlockSize

.LDecodeCoefs_SubBlockLoop_IMDCT:
	MOV	r0, sl @ Undo DCT-IV
	ADD	r1, sl, #0x04*MAX_BLOCK_SIZE @ <- In TempBuffer
	MOV	r2, r9, lsr #0x10
	BL	Fourier_DCT4
0:	STMFD	sp!, {r6-r7}
	ADD	r5, r5, r9, lsr #0x10+1-2    @ Lap   = LapBuffer+SubBlockSize/2 -> r5
	ADD	ip, sl, #0x04*MAX_BLOCK_SIZE @ OutLo (in TempBuffer) -> ip
	ADD	lr, ip, r9, lsr #0x10-2      @ OutHi = OutLo+SubBlockSize -> lr
	ADD	sl, sl, r9, lsr #0x10+1-2    @ Skip the next-block aliased samples (SrcBuf += SubBlockSize/2)
	SUBS	r8, r7, r9                   @ Have any non-overlap samples? (-nNonOverlap = OverlapSize-SubBlockSize -> r8, high 16 bits)
	BCS	.LDecodeCoefs_SubBlockLoop_IMDCT_Overlap @ NOTE: NextOverlapSize is always greater than OverlapScale, so this hacky condition works

@ r0: [Scratch]
@ r1: [Scratch]
@ r2: [Scratch]
@ r3: [Scratch]
@ r4: &OutBuf
@ r5: &Lap
@ r6:  DecimationPattern
@ r7:  NextOverlapSize | OverlapSize<<16
@ r8:  xxxx | -nNonOverlapRem<<16
@ r9:  OverlapScale | SubBlockSize<<16
@ sl: &Src
@ fp:  BlockSize
@ ip: &OutLo
@ lr: &OutHi

.LDecodeCoefs_SubBlockLoop_IMDCT_NoOverlap:
0:	LDMDB	r5!, {r0-r3}      @ a = *--Lap
	STR	r0, [ip, #0x0C]   @ *OutLo++ = a
	STR	r1, [ip, #0x08]
	STR	r2, [ip, #0x04]
	STR	r3, [ip], #0x10
	LDMIA	sl!, {r0-r3}      @ b = *Src++
	STR	r0, [lr, #-0x04]! @ *--OutHi = b
	STR	r1, [lr, #-0x04]!
	STR	r2, [lr, #-0x04]!
	STR	r3, [lr, #-0x04]!
	ADDS	r8, r8, #0x08<<16
	BCC	0b
1:	CMP	ip, lr @ End? (OutLo == OutHi)
	BEQ	.LDecodeCoefs_SubBlockLoop_IMDCT_End

@ r0: [Scratch]
@ r1: [Scratch]
@ r2: [Scratch]
@ r3: [Scratch]
@ r4: &OutBuf
@ r5: &Lap
@ r6: [Scratch]
@ r7: [Scratch, input is NextOverlapSize | OverlapSize<<16]
@ r8: &CosSin
@ r9:  OverlapScale | SubBlockSize<<16
@ sl: &Src
@ fp:  BlockSize
@ ip: &OutLo
@ lr: &OutHi

.LDecodeCoefs_SubBlockLoop_IMDCT_Overlap:
	LDR	r8, =Fourier_DCT4_CosSin - 0x02*16
	ADD	r8, r8, r7, lsr #0x10-1
0:	LDR	r0, [r8], #0x04       @ c | s<<16 -> r0
	LDR	r2, [r5, #-0x04]!     @ a = *--Lap -> r2
	LDR	r3, [sl], #0x04       @ b = *Src++ -> r3
	MOV	r1, r0, lsr #0x10     @ s -> r1
	BIC	r0, r0, r1, lsl #0x10 @ c -> r0
	MUL	r6, r0, r2            @ c*a -> r6
	MUL	r7, r1, r2            @ s*a -> r7
	MUL	r2, r1, r3            @ s*b -> r2
	MLA	r7, r0, r3, r7        @ *--OutHi = s*a + c*b
	SUB	r6, r6, r2            @ *OutLo++ = c*a - s*b
	MOV	r6, r6, asr #0x0F
	MOV	r7, r7, asr #0x0F
	STR	r6, [ip], #0x04
	STR	r7, [lr, #-0x04]!
	CMP	ip, lr
	BNE	0b

.LDecodeCoefs_SubBlockLoop_IMDCT_End:
	MOV	r8, r9, lsr #0x10
	SUB	fp, fp, r8, lsl #0x10-1 @ Store lapped samples from start of SrcBuf
	SUB	r8, sl, r8, lsl #0x02   @ NOTE: Leave SrcBuf untouched, as it now points to the next subblock
0:	LDMIA	r8!, {r0-r3,r6-r7,ip,lr}
	STMIA	r5!, {r0-r3,r6-r7,ip,lr}
	LDMIA	r8!, {r0-r3,r6-r7,ip,lr}
	STMIA	r5!, {r0-r3,r6-r7,ip,lr}
	ADDS	fp, fp, #0x10<<16
	BCC	0b
1:	SUB	r5, r5, r9, lsr #0x10+1-2 @ Rewind LapBuf, and then advance to the end
	ADD	r5, r5, fp, lsl #0x02-1

@ r0: [Scratch]
@ r1: [Scratch]
@ r2: [Scratch]
@ r3: [Scratch]
@ r4: &OutBuf
@ r5: &LapEnd
@ r6: &SrcSmp
@ r7:  ClipMask(=7Fh)
@ r8: [Scratch]
@ r9:  OverlapScale | SubBlockSize<<16
@ sl: &SrcBuf (for next subblock)
@ fp:  BlockSize
@ ip:  LapExtra*2
@ lr:  LapCopy | -LapCopyRem<<16
@ sp+00h:  DecimationPattern
@ sp+04h:  NextOverlapSize | OverlapSize<<16
@ sp+08h: &State
@ sp+0Ch: &OutBuf | Chan<<31 | IsStereo
@ sp+10h: &NextData | NybbleCounter<<29
@ sp+14h:  StreamData
@ sp+18h:  QScaleBase | WindowCtrl

.LDecodeCoefs_SubBlockLoop_IMDCT_LappingCycle:
	SUB	r6, sl, r9, lsr #0x10-2 @ SrcSmp = TempBuf (IMDCT samples were stored here)
	ADD	r6, r6, #0x04*MAX_BLOCK_SIZE
	MOV	r7, #0x7F               @ ClipMask -> r7
	SUB	ip, fp, r9, lsr #0x10   @ LapExtra*2 = BlockSize-SubBlockSize -> ip
	CMP	ip, r9, lsr #0x10-1     @ LapExtra < SubBlockSize?
	MOVCC	lr, ip, lsr #0x01       @  Y: LapCopy = LapExtra     -> lr
	MOVCS	lr, r9, lsr #0x10       @  N: LapCopy = SubBlockSize -> lr
1:	SUBS	lr, lr, lr, lsl #0x10   @ -LapCopyRem = -LapCopy?
	BCS	2f
10:	LDMDB	r5!, {r0-r3}            @ *Dst++ = *--LapEnd
	MOV	r0, r0, asr #0x08
	MOV	r1, r1, asr #0x08
	MOV	r2, r2, asr #0x08
	MOV	r3, r3, asr #0x08
	TEQ	r0, r0, lsl #0x18
	EORMI	r0, r7, r0, asr #0x20
	TEQ	r1, r1, lsl #0x18
	EORMI	r1, r7, r1, asr #0x20
	TEQ	r2, r2, lsl #0x18
	EORMI	r2, r7, r2, asr #0x20
	TEQ	r3, r3, lsl #0x18
	EORMI	r3, r7, r3, asr #0x20
	AND	r3, r3, #0xFF
	AND	r2, r2, #0xFF
	AND	r1, r1, #0xFF
	ORR	r3, r3, r2, lsl #0x08
	ORR	r3, r3, r1, lsl #0x10
	ORR	r0, r3, r0, lsl #0x18
	STR	r0, [r4], #0x04
	ADDS	lr, lr, #0x04<<16
	BCC	10b
2:	MOV	r0, r9, lsr #0x10     @ -SubBlockCopyRem = LapCopy-SubBlockSize?
	ADD	lr, lr, lr, lsl #0x10
	SUBS	lr, lr, r0, lsl #0x10
	BCS	3f
20:	LDMIA	r6!, {r0-r3}          @ *Dst++ = *SrcSmp++
	MOV	r0, r0, asr #0x08
	MOV	r1, r1, asr #0x08
	MOV	r2, r2, asr #0x08
	MOV	r3, r3, asr #0x08
	TEQ	r0, r0, lsl #0x18
	EORMI	r0, r7, r0, asr #0x20
	TEQ	r1, r1, lsl #0x18
	EORMI	r1, r7, r1, asr #0x20
	TEQ	r2, r2, lsl #0x18
	EORMI	r2, r7, r2, asr #0x20
	TEQ	r3, r3, lsl #0x18
	EORMI	r3, r7, r3, asr #0x20
	AND	r0, r0, #0xFF
	AND	r1, r1, #0xFF
	AND	r2, r2, #0xFF
	ORR	r0, r0, r1, lsl #0x08
	ORR	r0, r0, r2, lsl #0x10
	ORR	r0, r0, r3, lsl #0x18
	STR	r0, [r4], #0x04
	ADDS	lr, lr, #0x04<<16
	BCC	20b
3:	ADD	r8, r5, lr, lsl #0x02   @ LapBufDst = LapEnd -> r8
	ADD	lr, lr, lr, lsl #0x10   @ -NewCopyRem = LapCopy-LapExtra?
	SUBS	lr, lr, ip, lsl #0x10-1
	ADD	ip, ip, lr, asr #0x10-1 @ [LapTailNew*2 = LapExtra*2 - NewCopy*2]
	BCS	4f
30:	LDMDB	r5!, {r0-r3}            @ *--LapBufDst = *--LapEnd
	STMDB	r8!, {r0-r3}
	ADDS	lr, lr, #0x04<<16
	BCC	30b
4:	MOVS	ip, ip, lsr #0x01       @ LapTailNew?
	BEQ	5f
40:	LDMIA	r6!, {r0-r3}            @ *--LapBufDst = *SrcSmp++
	STR	r0, [r8, #-0x04]!
	STR	r1, [r8, #-0x04]!
	STR	r2, [r8, #-0x04]!
	STR	r3, [r8, #-0x04]!
	SUBS	ip, ip, #0x04
	BNE	40b
5:	SUB	r5, r5, r9, lsr #0x10+1-2 @ Rewind LapBuf

.LDecodeCoefs_SubBlockLoop_Tail:
	LDMFD	sp!, {r6-r7}
	CMP	r6, #0x00 @ Not finished with the decimation pattern?
	BNE	.LDecodeCoefs_SubBlockLoop
0:	MOV	r0, r7    @ Save NextOverlapSize
	LDMFD	sp!, {r4-r7,r9}

@ r4: &State
@ r5: &OutBuf | Chan<<31 | IsStereo
@ r6: &NextData | NybbleCounter<<29
@ r7:  StreamData
@ r8: [Scratch]
@ r9:  QScaleBase | WindowCtrl<<16
@ sl: &CoefDst
@ fp:  BlockSize

.LDecodeCoefs_NextChan:
.if ULC_STEREO_SUPPORT
	ADDS	r5, r5, r5, lsl #0x1F @ Stereo, second channel?
	BMI	.LChannels_Loop
.endif
0:	STRH	r0, [r4, #0x02] @ Save OverlapSize = NextOverlapSize

/**************************************/

.if ULC_STEREO_SUPPORT
.LMidSideXfm:
	TST	r5, #0x01 @ Check for IsStereo
	BEQ	3f
	BIC	r5, r5, #0x01
0:	MOV	r7, #0x80000000
	MOV	r8, fp
	MOV	r9, #0x01*MAX_BLOCK_SIZE*2
1:	LDR	r0, [r5]
	LDR	r1, [r5, r9]
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
2:	STR	r1, [r5, r9]
	STR	r0, [r5], #0x04
	SUBS	r8, r8, #0x04
	BNE	1b
3:
.endif

/**************************************/

@ r4: &State
@ r6: &NextData | NybbleCounter<<29

.LSaveState_Exit:
	LDR	r0, [r4, #0x0C]
	MOVS	ip, r6, lsr #0x1D+1 @ Get bytes to advance by (C countains nybble rounding)
	BIC	r6, r6, #0xE0000000 @ Clear nybble counter
	ADC	r6, r6, ip
	STR	r6, [r4, #0x0C]
	RSB	r0, r0, r6 @ Return bytes read for this block

.LExit:
	LDMFD	sp!, {r4-fp,lr}
	BX	lr

/**************************************/

.LNoBlocksRem:
	MOV	r0, #0x00
	STR	r0, [r4, #0x08]   @ SoundFile = NULL
0:	MOV	r2, #0x04000000
.if ULC_STEREO_SUPPORT
	CMP	ip, #0x00
.endif
	STRH	r2, [r2, #0x82]   @ Disable DMA audio
	STR	r2, [r2, #0xC4]   @ Disable DMA1
.if ULC_STEREO_SUPPORT
	STRNE	r2, [r2, #0xD0]   @ Disable DMA2 (with IsStereo)
.endif
	STR	r2, [r2, #0x0100] @ Disable TM0
	STR	r2, [r2, #0x0104] @ Disable TM1

.LNoBufProc:
	@MOV	r0, #0x00 @ No bytes were read
	B	.LExit

/**************************************/

@ r5: &OutBuf | IsStereo
@ fp:  BlockSize

.LOutputPaused:
	STR	r1, [r4, #0x04] @ Store updated WrBufIdx
	AND	r6, r5, #0x01   @ IsStereo -> r6
	BIC	r5, r5, #0x01
	MOV	r0, #0x00
	MOV	r1, r0
	MOV	r2, r0
	MOV	r3, r0
	MOV	r4, r0
	MOV	r7, r0
	MOV	r8, r0
	MOV	r9, r0
1:	SUB	fp, fp, fp, lsl #0x10
10:	STMIA	r5!, {r0-r4,r7-r9} @ Clear 32 samples at once
	ADDS	fp, fp, #0x20<<16
	BCC	10b
2:	SUB	r5, r5, fp         @ Clear right buffer on stereo
	ADD	r5, r5, #0x01*MAX_BLOCK_SIZE*2
	MOVS	r6, r6, lsr #0x01
	BCS	1b
3:	@MOV	r0, #0x00 @ No bytes were read
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
	.space 0x04 * (MAX_BLOCK_SIZE/2) * (1+ULC_STEREO_SUPPORT)

.size   ulc_LappingBuffer, .-ulc_LappingBuffer
.global ulc_LappingBuffer @ Cleared on starting playback, so must be global

/**************************************/
/* EOF                                */
/**************************************/
