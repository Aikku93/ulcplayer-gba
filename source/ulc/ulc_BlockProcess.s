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

.equ QSCALE_BASE, (0x5025 | (0x18+5 - ULC_COEF_PRECISION)<<7) @ "MOV r5, r5, lsr #X", lower hword
.equ QSCALE_ZERO, 0x5025 @ "MOV r5, r5, lsr #32", lower hword

ulc_BlockProcess:
	STMFD	sp!, {r4-fp,lr}
	LDR	r4, =ulc_State
	LDR	r3, =ulc_OutputBuffer
	LDRB	r0, [r4, #0x01]           @ nBufProc -> r0
	LDMIB	r4, {r1-r2,r6}            @ WrBufIdx | Pause<<1 | nBlkRem<<2 -> r1, &File -> r2, &NextData -> r6
	CMP	r2, #0x00                 @ !File? Early exit to avoid reading from NULL
	BEQ	.LNoBufProc
	LDRH	fp, [r2, #0x04]           @ BlockSize -> fp
.if ULC_STEREO_SUPPORT
	LDRH	r2, [r2, #0x10]           @ nChan -> r2
.endif
0:	AND	ip, r6, #0x03             @ Prepare reader (&NextData | NybbleCounter<<29 -> r6, StreamData -> r7)
	LDR	r7, [r6, -ip]!
	ORR	r6, r6, ip, lsl #0x20-3+1 @ [8 nybbles per word (hence 32-3=29), and 2 nybbles per byte (hence +1)]
	MOVS	ip, ip, lsl #0x03
	MOVNE	r7, r7, lsr ip
.if ULC_STEREO_SUPPORT
	ORR	r3, r3, r2, lsr #0x01     @ Set stereo flag as needed (nChan can only be 1 or 2, so this is safe)
.endif
0:	SUBS	r0, r0, #0x01             @ --nBufProc?
	BCC	.LNoBufProc
	STRB	r0, [r4, #0x01]           @ <- This assumes that ulc_BlockProcess is called at least once between timer interrupts (race condition)
	EOR	r1, r1, #0x01             @ WrBufIdx ^= 1
	MOVS	r0, r1, lsl #0x1F         @ N=WrBufIdx?, C=Pause?
	ADDPL	r3, r3, fp                @ Move to second buffer as needed
	BCS	.LOutputPaused
	SUBS	r1, r1, #0x01<<2          @ --nBlkRem?
	BCC	.LNoBlocksRem
	STR	r1, [r4, #0x04]
	LDRH	r4, [r4, #0x02]           @ LastSubBlockSize -> r4
	MOV	r9, #QSCALE_BASE & 0xFF00
	ORR	r9, r9, #QSCALE_BASE & 0xFF
	STR	r3, [sp, #-0x04]!         @ No need to stash LastSubBlockSize for mono only

.LReadBlockHeader:
	AND	r5, r7, #0x0F         @ QScaleBase | WindowCtrl<<16 -> r9
	ORR	r9, r9, r5, lsl #0x10
	NextNybble
	TST	r5, #0x08             @ Decimating?
	BEQ	1f
0:	ORR	r9, r9, r7, lsl #0x1C @  Append decimation control to upper bits
	NextNybble
1:

/**************************************/

@ r0:
@ r1:
@ r2:
@ r3:
@ r4:  LastSubBlockSize
@ r5:
@ r6: &NextData | NybbleCounter<<29
@ r7:  StreamData
@ r8:  DecimationPattern
@ r9:  QScaleBase | WindowCtrl<<16
@ sl:
@ fp:  BlockSize
@ ip:
@ lr:
@ NOTE: WindowCtrl is stored as:
@  b0..2:   OverlapScale
@  b3:      Decimation toggle
@  b4..11:  Unused
@  b12..15: Decimation (0b0000 == 0b0001 == No decimation)

.LChannels_Loop:
	ADR	r8, .LDecodeCoefs_DecimationPattern
	LDR	r8, [r8, r9, lsr #0x1C-2] @ DecimationPattern -> r8

/**************************************/

@ r0: 0
@ r1: 0
@ r2: 0
@ r3: 0
@ r4:  LastSubBlockSize|SubBlockSize<<16
@ r5: [Scratch]
@ r6: &NextData | NybbleCounter<<29
@ r7:  StreamData
@ r8:  DecimationPattern
@ r9:  QScaleBase | WindowCtrl<<16
@ sl: &CoefDst
@ fp:  BlockSize | -CoefRem<<16
@ ip: [Scratch]
@ lr:  Log2[Quant]

.LDecodeCoefs_SubBlockLoop:
	MOV	r0, #0x00     @ 0 -> r0,r1,r2,r3
	MOV	r1, #0x00
	MOV	r2, #0x00
	MOV	r3, #0x00
	AND	r5, r8, #0x07 @ CoefRem = BlockSize >> (DecimationPattern&0x7)
	MOV	r5, fp, lsr r5
	ORR	r4, r4, r5, lsl #0x10 @ LastSubBlockSize|SubBlockSize<<16 -> r4
	SUB	fp, fp, r5, lsl #0x10
	LDR	sl, =ulc_TransformBuffer
	B	.LDecodeCoefs_Start

.LDecodeCoefs_DecimationPattern:
	.word (0+8)                                   @ 0000: N/1*
.if 0
	.word (0+8)                                   @ 0001: N/1* (unused, mapped to above)
.else
.LZeroWord:
	.word 0
.endif
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

.LDecodeCoefs_ChangeQuant:
	NextNybble

.LDecodeCoefs_Start:
	AND	r5, r7, #0x0F
	NextNybble
	CMP	r5, #0x0E                         @ Normal quantizer? (8h,0h,0h..Dh)
	BHI	.LDecodeCoefs_Stop_NoiseFill      @  Noise-fill (exp-decay to end) (8h,0h,Fh,Zh,Yh,Xh)
	MOVCC	lr, r5
	BCC	1f
0:	AND	r5, r7, #0x0F
	NextNybble
	CMP	r5, #0x0F                         @ Stop? (8h,0h,Eh,Fh)
	SUBEQ	r5, r0, fp, asr #0x10             @  Treat as zero-fill with N=CoefRem
	BEQ	.LDecodeCoefs_FillZeros_PostBiasCore
	ADD	lr, r5, #0x0E                     @ Extended-precision quantizer (8h,0h,Eh,0h..Ch)
	CMP	lr, #0x20-24-5+ULC_COEF_PRECISION @ Limit LSR value to 31 and convert >=32 to LSR #32
	EORCS	r5, r9, #QSCALE_BASE ^ QSCALE_ZERO
1:	ADDCC	r5, r9, lr, lsl #0x07             @ Modify the quantizer instruction
	STRH	r5, .LDecodeCoefs_Normal_Shifter

.LDecodeCoefs_DecodeLoop:
	SUBS	r5, r0, r7, lsl #0x1C    @ -QCoef -> r5?
	BEQ	.LDecodeCoefs_FillRun    @ Zeros/noise run? (0h)
	BVS	.LDecodeCoefs_EscapeCode @ Escape code? (8h)

.LDecodeCoefs_Normal:
	NextNybble
	MOVS	ip, r5, asr #0x10 @ 4.12fxp
	MULNE	r5, ip, ip        @ 7.24fxp <- Non-linear quantization (technically 8.24fxp but lost sign bit)
.LDecodeCoefs_Normal_Shifter:
	MOV	r5, r5, lsr #0x00 @ Coef=QCoef*2^(-24+ACCURACY-Quant) -> r5 (NOTE: Self-modifying dequantization)
	RSBMI	r5, r5, #0x00     @ Restore sign after dequantization (round towards 0)
	STR	r5, [sl], #0x04   @ Coefs[n++] = Coef
	ADDS	fp, fp, #0x01<<16 @ --CoefRem?
	BCC	.LDecodeCoefs_DecodeLoop
1:	B	.LDecodeCoefs_NoMoreCoefs

.LDecodeCoefs_FillRun:
	NextNybble
	AND	r5, r7, #0x0F @ n -> r5 (not yet biased)
	NextNybble
	AND	ip, r7, #0x0F
	ORR	r5, ip, r5, lsl #0x04
	NextNybble
	AND	ip, r7, #0x0F
	NextNybble
	MOVS	ip, ip, lsr #0x01 @ v -> ip
	ADC	r5, r5, r5
	BEQ	.LDecodeCoefs_FillZeros

.LDecodeCoefs_FillNoise:
	MUL	ip, ip, ip
	ADD	r5, r5, #0x10         @ 0h,Zh,Yh,Xh: 16 .. 527 noise samples (Xh.bit[1..3] != 0)
	ADD	fp, fp, r5, lsl #0x10 @ CoefRem -= n
	MOV	ip, ip, lsl #ULC_COEF_PRECISION+1-1 - 5 @ Scale = v^2*Quant/2 -> ip? (+.1 for .31->.32 scaling in rand(), -5 for quantizer bias)
	MOVS	ip, ip, lsr lr        @ Out of range? Zero-code instead
	BEQ	.LDecodeCoefs_FillZeros_PostDecCore
0:	SUB	lr, lr, r5, lsl #0x08 @ Log2[Quant] | -CoefRem<<8 -> lr
	EOR	r5, r6, r7, ror #0x17 @ Seed = [random garbage] -> r5
1:	SMULL	r0, r1, r5, ip        @ Rand*Scale -> r0,r1
	EOR	r5, r5, r5, lsl #0x0D @ <- Xorshift generator
	EOR	r5, r5, r5, lsr #0x11
	EOR	r5, r5, r5, lsl #0x05
	ADDS	lr, lr, #0x01<<8
	STR	r1, [sl], #0x04
	BCC	1b
2:	MOV	r0, #0x00 @ Reset r0,r1 to 0 again
	MOV	r1, #0x00
	CMP	fp, #0x010000
	BCS	.LDecodeCoefs_DecodeLoop
	B	.LDecodeCoefs_NoMoreCoefs

.LDecodeCoefs_EscapeCode:
	NextNybble
	ANDS	r5, r7, #0x0F           @ Quantizer change? (8h,0h,Xh)
	BEQ	.LDecodeCoefs_ChangeQuant
	NextNybble
	@B	.LDecodeCoefs_FillZeros @ 8h,1h..Fh: Zero run (1 .. 15 coefficients)
	@ Z=1 cannot happen from NextNybble macro, so biasing is not used in fall-through

@ Must enter with Z=1 to trigger biasing
.LDecodeCoefs_FillZeros:
	ADDEQ	r5, r5, #0x1F         @ 0h,Zh,Yh,Xh: 31 .. 542 zeros (Xh.bit[1..3] == 0)
.LDecodeCoefs_FillZeros_PostBiasCore:
	ADD	fp, fp, r5, lsl #0x10 @ CoefRem -= zR
.LDecodeCoefs_FillZeros_PostDecCore:
0:	MOVS	ip, r5, lsl #0x1F     @ N=CoefRem&1, C=CoefRem&2
	STRMI	r0, [sl], #0x04
	STMCSIA	sl!, {r0-r1}
	MOVS	r5, r5, lsr #0x02
1:	STMNEIA	sl!, {r0-r3}
	SUBNES	r5, r5, #0x01
	BNE	1b
2:	CMP	fp, #0x010000
	BCS	.LDecodeCoefs_DecodeLoop
	B	.LDecodeCoefs_NoMoreCoefs

.LDecodeCoefs_Stop_NoiseFill:
	AND	ip, r7, #0x0F               @ v -> ip
	NextNybble
	AND	r5, r7, #0x0F               @ r -> r5
	NextNybble
	ORR	r5, r5, r7, lsl #0x1C       @ Shift up and append low nybble
	MOV	r5, r5, ror #0x1C
	NextNybble
1:	ADD	ip, ip, #0x01               @ Unpack p = (v+1)^2*Quant/8
	MUL	ip, ip, ip
	MOV	ip, ip, lsl #ULC_COEF_PRECISION+1-3 - 5 @ Same as normal noise fill (minus 3 for 1/8 quantizer). Scale -> ip
	MOVS	ip, ip, lsr lr
	MULNE	lr, r5, r5                  @ Unpack Decay = 1 - r^2*2^-16 -> lr
	SUBEQ	r5, r0, fp, asr #0x10       @ Out of range: Treat as zero-run to end
	BEQ	.LDecodeCoefs_FillZeros_PostBiasCore
	SUB	lr, r0, lr, lsl #0x20-16
	EOR	r5, r6, r7, ror #0x17       @ Seed = [random garbage] -> r5
1:	SMULL	r0, r1, r5, ip        @ Rand*Scale -> r0,r1
	UMULL	r0, ip, lr, ip        @ Scale *= Decay
	EOR	r5, r5, r5, lsl #0x0D @ <- Xorshift generator
	EOR	r5, r5, r5, lsr #0x11
	EOR	r5, r5, r5, lsl #0x05
	ADDS	fp, fp, #0x01<<16     @ --CoefRem?
	STR	r1, [sl], #0x04
	BCC	1b

.LDecodeCoefs_NoMoreCoefs:
	SUB	sl, sl, r4, lsr #0x10-2 @ Rewind buffer

/**************************************/

@ r0:
@ r1:
@ r2:
@ r3:
@ r4:  SubBlockSize
@ r5:
@ r6: &NextData | NybbleCounter<<29
@ r7:  StreamData
@ r8:  DecimationPattern
@ r9:  QScaleBase | WindowCtrl<<16
@ sl: &CoefDst
@ fp:  BlockSize
@ ip:
@ lr:
@ sp+00h: &OutBuf | Chan<<31 | IsStereo

.LDecodeCoefs_SubBlockLoop_IMDCT:
	MOV	r0, sl                @ Undo DCT-IV
	ADD	r1, sl, #0x04*ULC_MAX_BLOCK_SIZE @ TempBuffer(=TransformBuffer+MAX_BLOCK_SIZE)
	MOV	r2, r4, lsr #0x10
	BL	Fourier_DCT4

@ r0:
@ r1:
@ r2:
@ r3:
@ r4:  SubBlockSize
@ r5: &OutBuf
@ r6: [Scratch]
@ r7: [Scratch]
@ r8: &LapEnd
@ r9: [Scratch/&CosSinTable]
@ sl: &Src
@ fp:  BlockSize
@ ip:
@ lr:

0:	LDR	r5, [sp, #0x00]       @ OutBuf -> r5
	STMFD	sp!, {r6-r9}
	ADD	r6, r5, r4, lsr #0x10 @ Advance to next subblock in OutBuf
	STR	r6, [sp, #0x10]
	MOV	r6, r4, lsr #0x10     @ OverlapSize = SubBlockSize -> r6
	BIC	ip, r4, r6, lsl #0x10 @ LastSubBlockSize -> ip
	TST	r8, #0x08             @ Transient subblock?
	MOVNE	lr, r9, lsr #0x10     @  Y: OverlapSize >>= (WindowCtrl&7)
	ANDNE	lr, lr, #0x07
	MOVNE	r6, r6, lsr lr
	LDR	r9, =Fourier_CosSin - 0x02*16
	CMP	r6, ip                @ OverlapSize > LastSubBlockSize?
	MOVHI	r6, ip                @  Y: OverlapSize = LastSubBlockSize
	MOV	r4, r4, lsr #0x10     @ LastSubBlockSize = SubBlockSize -> r4
	ADD	r8, sl, #0x04*ULC_MAX_BLOCK_SIZE*2 @ LappingBuffer(=TransformBuffer+2*MAX_BLOCK_SIZE) -> r8
.if ULC_STEREO_SUPPORT
	TST	r5, #0x80000000                    @ Second channel?
	BIC	r5, r5, #0x80000001                @ [Clear Chan and IsStereo from OutBuf]
	ADDNE	r5, r5, #0x01*ULC_MAX_BLOCK_SIZE*2 @  Skip to second channel data
	ADDNE	r8, r8, #0x04*ULC_MAX_BLOCK_SIZE/2
.endif
	ADD	r8, r8, r4, lsl #0x02-1          @ Lap   = LapBuffer+SubBlockSize/2 -> r8
	ADD	ip, sl, #0x04*ULC_MAX_BLOCK_SIZE @ OutLo(=TempBuffer) -> ip
	ADD	lr, ip, r4, lsl #0x02            @ OutHi = OutLo+SubBlockSize -> lr
	ADD	sl, sl, r4, lsl #0x02-1          @ Skip the next-block aliased samples (Src += SubBlockSize/2)
0:	ADD	r9, r9, r6, lsl #0x01 @ Index the Cos/Sin table by OverlapSize
	RSBS	r6, r6, r4            @ Have any non-overlap samples? (nNonOverlap = SubBlockSize-OverlapSize -> r6)
	BEQ	.LDecodeCoefs_SubBlockLoop_IMDCT_Overlap

@ r0: [Scratch]
@ r1: [Scratch]
@ r2: [Scratch]
@ r3: [Scratch]
@ r4:  SubBlockSize
@ r5: &OutBuf
@ r6: [Scratch/nNonOverlapRem]
@ r7: [Scratch]
@ r8: &LapSrc
@ r9: [Scratch/&CosSinTable]
@ sl: &Src
@ fp:  BlockSize
@ ip: &OutLo
@ lr: &OutHi

.LDecodeCoefs_SubBlockLoop_IMDCT_NoOverlap:
0:	LDMDB	r8!, {r0-r3}      @ a = *--Lap
	STR	r0, [ip, #0x0C]   @ *OutLo++ = a
	STR	r1, [ip, #0x08]
	STR	r2, [ip, #0x04]
	STR	r3, [ip], #0x10
	LDMIA	sl!, {r0-r3}      @ b = *Src++
	STR	r0, [lr, #-0x04]! @ *--OutHi = b
	STR	r1, [lr, #-0x04]!
	STR	r2, [lr, #-0x04]!
	STR	r3, [lr, #-0x04]!
	SUBS	r6, r6, #0x08
	BNE	0b
1:	CMP	ip, lr @ End? (OutLo == OutHi)
	BEQ	.LDecodeCoefs_SubBlockLoop_IMDCT_End

.LDecodeCoefs_SubBlockLoop_IMDCT_Overlap:
0:	LDR	r0, [r9], #0x04       @ c | s<<16 -> r0
	LDR	r2, [r8, #-0x04]!     @ a = *--Lap -> r2
	LDR	r3, [sl], #0x04       @ b = *Src++ -> r3
	MOV	r1, r0, lsr #0x10     @ s -> r1
	BIC	r0, r0, r1, lsl #0x10 @ c -> r0
	SMULL	r6, r7, r2, r1        @ *--OutHi = s*a + c*b -> r6,r7 [.16]
	SMLAL	r6, r7, r3, r0
	RSB	r3, r3, #0x00
	SMULL	r0, r2, r2, r0        @ *OutLo++ = c*a - s*b -> r0,r2 [.16] <- GCC complains about this, but should be fine
	SMLAL	r0, r2, r3, r1
	MOVS	r6, r6, lsr #0x10     @ Shift down and round
	ADC	r7, r6, r7, lsl #0x10
	MOVS	r6, r0, lsr #0x10
	ADC	r6, r6, r2, lsl #0x10
	STR	r6, [ip], #0x04
	STR	r7, [lr, #-0x04]!
	CMP	ip, lr
	BNE	0b

.LDecodeCoefs_SubBlockLoop_IMDCT_End:
	SUB	sl, sl, r4, lsl #0x02 @ Store lapped samples from start of SrcBuf to LapBuf
	SUB	r4, r4, r4, lsl #0x10-1
0:	LDMIA	sl!, {r0-r3,r6-r7,ip,lr}
	STMIA	r8!, {r0-r3,r6-r7,ip,lr}
	LDMIA	sl!, {r0-r3,r6-r7,ip,lr}
	STMIA	r8!, {r0-r3,r6-r7,ip,lr}
	ADDS	r4, r4, #0x10<<16
	BCC	0b
1:	SUB	r8, r8, r4, lsl #0x02-1 @ Rewind LapBuf, and then advance to the end
	ADD	r8, r8, fp, lsl #0x02-1
	SUB	sl, sl, r4, lsl #0x02-1 @ Rewind &Src

@ r0: [Scratch]
@ r1: [Scratch]
@ r2: [Scratch]
@ r3: [Scratch]
@ r4:  SubBlockSize
@ r5: &OutBuf
@ r6:  LapRem*2
@ r7:  nLapOut
@ r8: &LapEnd
@ r9:  ClipMask(=7Fh)
@ sl: &SrcSmp
@ fp:  BlockSize
@ ip:
@ lr:

.equ UNPACK_SHIFT, (ULC_COEF_PRECISION+1-8) @ Input is 1.XX (+1 due to the sign bit), output is 8.0

.LDecodeCoefs_SubBlockLoop_IMDCT_LappingCycle:
	ADD	sl, sl, #0x04*ULC_MAX_BLOCK_SIZE @ &SrcSmp(=TempBuffer) -> sl
	MOV	r9, #0x7F         @ ClipMask -> r9
	SUB	r6, fp, r4        @ LapRem*2 = BlockSize-SubBlockSize -> r6
	CMP	r6, r4, lsl #0x01 @ LapRem < SubBlockSize?
	MOVCC	r7, r6, lsr #0x01 @  Y: nLapOut = LapRem       -> r7
	MOVCS	r7, r4            @  N: nLapOut = SubBlockSize -> r7
1:	SUBS	r7, r7, r7, lsl #0x10   @ -nLapOutRem = -nLapOut?
	BCS	2f
10:	LDMDB	r8!, {r0-r3}            @ *Dst++ = *--LapEnd
	MOV	r0, r0, asr #UNPACK_SHIFT
	MOV	r1, r1, asr #UNPACK_SHIFT
	MOV	r2, r2, asr #UNPACK_SHIFT
	MOV	r3, r3, asr #UNPACK_SHIFT
	TEQ	r0, r0, lsl #0x18
	EORMI	r0, r9, r0, asr #0x20
	TEQ	r1, r1, lsl #0x18
	EORMI	r1, r9, r1, asr #0x20
	TEQ	r2, r2, lsl #0x18
	EORMI	r2, r9, r2, asr #0x20
	TEQ	r3, r3, lsl #0x18
	EORMI	r3, r9, r3, asr #0x20
	AND	r3, r3, #0xFF
	AND	r2, r2, #0xFF
	AND	r1, r1, #0xFF
	ORR	r3, r3, r2, lsl #0x08
	ORR	r3, r3, r1, lsl #0x10
	ORR	r0, r3, r0, lsl #0x18
	STR	r0, [r5], #0x04
	ADDS	r7, r7, #0x04<<16
	BCC	10b
2:	SUB	r0, r4, r7
	SUBS	r7, r7, r0, lsl #0x10 @ -nSrcOut = nLapOut-SubBlockSize?
	BCS	3f
20:	LDMIA	sl!, {r0-r3}          @ *Dst++ = *SrcSmp++
	MOV	r0, r0, asr #UNPACK_SHIFT
	MOV	r1, r1, asr #UNPACK_SHIFT
	MOV	r2, r2, asr #UNPACK_SHIFT
	MOV	r3, r3, asr #UNPACK_SHIFT
	TEQ	r0, r0, lsl #0x18
	EORMI	r0, r9, r0, asr #0x20
	TEQ	r1, r1, lsl #0x18
	EORMI	r1, r9, r1, asr #0x20
	TEQ	r2, r2, lsl #0x18
	EORMI	r2, r9, r2, asr #0x20
	TEQ	r3, r3, lsl #0x18
	EORMI	r3, r9, r3, asr #0x20
	AND	r0, r0, #0xFF
	AND	r1, r1, #0xFF
	AND	r2, r2, #0xFF
	ORR	r0, r0, r1, lsl #0x08
	ORR	r0, r0, r2, lsl #0x10
	ORR	r0, r0, r3, lsl #0x18
	STR	r0, [r5], #0x04
	ADDS	r7, r7, #0x04<<16
	BCC	20b
3:	ADD	r9, r8, r7, lsl #0x02   @ LapBufDst = LapEnd -> r9
	ORR	r7, r7, r7, lsl #0x10
	SUBS	r7, r7, r6, lsl #0x10-1 @ -nLapShift = nLapOut-LapRem -> r7?
	ADD	r6, r6, r7, asr #0x10-1 @ [nLapInsert*2 = LapRem*2 - nLapShift*2]
	BCS	4f
30:	LDMDB	r8!, {r0-r3}            @ *--LapBufDst = *--LapEnd
	STMDB	r9!, {r0-r3}
	ADDS	r7, r7, #0x04<<16
	BCC	30b
4:	MOVS	r6, r6, lsr #0x01       @ nLapInsert?
	BEQ	5f
40:	LDMIA	sl!, {r0-r3}            @ *--LapBufDst = *SrcSmp++
	STR	r0, [r9, #-0x04]!
	STR	r1, [r9, #-0x04]!
	STR	r2, [r9, #-0x04]!
	STR	r3, [r9, #-0x04]!
	SUBS	r6, r6, #0x04
	BNE	40b
5:

.LDecodeCoefs_SubBlockLoop_Tail:
	LDMFD	sp!, {r6-r9}
	MOVS	r8, r8, lsr #0x04 @ Advance decimation pattern. Finished?
	BNE	.LDecodeCoefs_SubBlockLoop

@ r4:  LastSubBlockSize
@ r5:
@ r6: &NextData | NybbleCounter<<29
@ r7:  StreamData
@ r8:  DecimationPattern
@ r9:  QScaleBase | WindowCtrl<<16
@ sl:
@ fp:  BlockSize

.LDecodeCoefs_NextChan:
.if ULC_STEREO_SUPPORT
	LDR	r0, [sp], #0x04
.else
	ADD	sp, sp, #0x04 @ Pop OutBuf, not needed anymore
.endif
	LDR	r5, =ulc_State
.if ULC_STEREO_SUPPORT
	SUB	r0, r0, fp            @ Rewind OutBuf
	ADDS	r0, r0, r0, lsl #0x1F @ Stereo, second channel?
	LDRMIH	r4, [r5, #0x02]       @  Restore old LastSubBlockSize
	STRMI	r0, [sp, #-0x04]!
	BMI	.LChannels_Loop
.endif
0:	STRH	r4, [r5, #0x02] @ Save LastSubBlockSize

/**************************************/

.if ULC_STEREO_SUPPORT
.LMidSideXfm:
	TST	r0, #0x01 @ Check for IsStereo
	BEQ	3f
	BIC	r4, r0, #0x01
0:	MOV	r7, #0x80000000
	MOV	r8, fp
	MOV	r9, #0x01*ULC_MAX_BLOCK_SIZE*2
1:	LDR	r0, [r4]
	LDR	r1, [r4, r9]
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
2:	STR	r1, [r4, r9]
	STR	r0, [r4], #0x04
	SUBS	r8, r8, #0x04
	BNE	1b
3:
.endif

/**************************************/

@ r5: &State
@ r6: &NextData | NybbleCounter<<29

.LSaveState_Exit:
	LDR	r0, [r5, #0x0C]
	MOVS	ip, r6, lsr #0x1D+1 @ Get bytes to advance by (C countains nybble rounding)
	BIC	r6, r6, #0xE0000000 @ Clear nybble counter
	ADC	r6, r6, ip
	STR	r6, [r5, #0x0C]
	RSB	r0, r0, r6 @ Return bytes read for this block

.LNoBufProc:
	@MOV	r0, #0x00 @ No bytes were read
	@B	.LExit

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
1:	LDR	r0, =.LZeroWord
	LDR	r1, =ulc_OutputBuffer
	LDR	r2, =(((0x01 * ULC_MAX_BLOCK_SIZE*2) * (1+ULC_STEREO_SUPPORT)) / 0x04) | 1<<24 | 1<<26
	SWI	0x0C0000
2:	MOV	r0, #0x00 @ No bytes were read
	B	.LExit

/**************************************/

@ r3: &OutBuf | IsStereo
@ fp:  BlockSize

.LOutputPaused:
	STR	r1, [r4, #0x04] @ Store updated WrBufIdx
.if ULC_STEREO_SUPPORT
	AND	r6, r3, #0x01   @ IsStereo -> r6
	BIC	r3, r3, #0x01
.endif
	MOV	r0, #0x00
	MOV	r1, r0
	MOV	r2, r0
	MOV	r4, r0
	MOV	r5, r0
	MOV	r7, r0
	MOV	r8, r0
	MOV	r9, r0
1:	SUB	fp, fp, fp, lsl #0x10
10:	STMIA	r3!, {r0-r2,r4-r5,r7-r9} @ Clear 32 samples at once
	ADDS	fp, fp, #0x20<<16
	BCC	10b
.if ULC_STEREO_SUPPORT
2:	SUB	r3, r3, fp         @ Clear right buffer on stereo
	ADD	r3, r3, #0x01*ULC_MAX_BLOCK_SIZE*2
	MOVS	r6, r6, lsr #0x01
	BCS	1b
.endif
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
	.space 0x04 * ULC_MAX_BLOCK_SIZE
.size ulc_TransformBuffer, .-ulc_TransformBuffer

ulc_TransformTemp:
	.space 0x04 * ULC_MAX_BLOCK_SIZE
.size ulc_TransformTemp, .-ulc_TransformTemp

ulc_LappingBuffer:
	.space 0x04 * (ULC_MAX_BLOCK_SIZE/2) * (1+ULC_STEREO_SUPPORT)

.size   ulc_LappingBuffer, .-ulc_LappingBuffer
.global ulc_LappingBuffer @ Cleared on starting playback, so must be global

/**************************************/
/* EOF                                */
/**************************************/
