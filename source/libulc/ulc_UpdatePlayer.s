/**************************************/
#include "AsmMacros.h"
/**************************************/
#include "ulc_Specs.h"
/**************************************/

#if ULC_USE_INPLACE_XFM
# define LAPPING_BUFFER_OFFS (0x04 * ULC_MAX_BLOCK_SIZE) //! Past the transform buffer
#else
# define TEMP_BUFFER_OFFS    (0x04 * ULC_MAX_BLOCK_SIZE)
# define LAPPING_BUFFER_OFFS (0x04 * ULC_MAX_BLOCK_SIZE + TEMP_BUFFER_OFFS)
#endif

/**************************************/

@ "MOV r5, r5, asr #X", lower hword
.equ QSCALE_BASE, (0x5045 | (0x18+5 - ULC_COEF_PRECISION)<<7)

@ "MOV r5, r5, lsr #32", lower hword
.equ QSCALE_ZERO, 0x5025

@ Skip tp next nybble (and load more data as needed)
.macro NextNybble
	ADDS	r6, r6, #0x01<<29 @ More nybbles?
	LDRCS	r7, [r6, #0x04]!  @  No:  Move to next data
	MOVCC	r7, r7, lsr #0x04 @  Yes: Move to next nybble
.endm

/**************************************/

@ Same oscillator as DCT4 is used here
.macro STEP_OSCILLATOR PatchLabel
	ADD	ip, r9, r9, asr #0x01 @ ks = s*k -> ip
	ADD	ip, ip, ip, asr #0x04
	ADD	lr, r8, r8, asr #0x02 @ kc = c*k -> lr
	ADD	lr, lr, lr, asr #0x02
\PatchLabel :
	SUB	r8, r8, ip            @ c -= ks (needs scaling by 2/N)
	ADD	r9, r9, lr            @ s += kc (needs scaling by 2/N)
.endm

@ Shift, clip, and mask sample
@ Input/output in Rm, sign mask in Rn
@ Notes:
@  * Input is 1.x, and output is 1.7 for 8-bit audio
.macro SCALE_AND_CLIP Rm, Rn, Mask=0
	MOV	\Rm, \Rm, asr #(ULC_COEF_PRECISION-7)
	TEQ	\Rm, \Rm, lsl #0x18
	EORMI	\Rm, \Rn, \Rm, asr #0x20
.if (\Mask != 0)
	AND	\Rm, \Rm, #\Mask
.endif
.endm

/**************************************/

ASM_FUNC_GLOBAL(ulc_UpdatePlayer)
ASM_FUNC_BEG   (ulc_UpdatePlayer, ASM_MODE_ARM;ASM_SECTION_TEXT)

ulc_UpdatePlayer:
	STMFD	sp!, {r4-fp,lr}
	LDR	r4, =ulc_State
	LDR	r3, =ulc_OutputBuffer
	LDMIB	r4, {r1-r2,r6}            @ WrBufIdx | Pause<<1 | nBlkRem<<2 -> r1, &File -> r2, &NextData -> r6
	CMP	r2, #0x00                 @ !File? Early exit to avoid reading from NULL
	BEQ	.LNoBufProc
	LDRH	fp, [r2, #0x04]           @ BlockSize -> fp
#if ULC_STEREO_SUPPORT
	LDRH	r2, [r2, #0x10]           @ nChan -> r2
#endif
0:	AND	ip, r6, #0x03             @ Prepare reader (&NextData | NybbleCounter<<29 -> r6, StreamData -> r7)
	LDR	r7, [r6, -ip]!
	ORR	r6, r6, ip, lsl #0x20-3+1 @ [8 nybbles per word (hence 32-3=29), and 2 nybbles per byte (hence +1)]
	MOVS	ip, ip, lsl #0x03
	MOVNE	r7, r7, lsr ip
#if ULC_STEREO_SUPPORT
	ORR	r3, r3, r2, lsr #0x01     @ Set stereo flag as needed (nChan can only be 1 or 2, so this is safe)
#endif
#if !ULC_SINGLE_BUFFER
	MRS	r5, cpsr                  @ cpsr -> r5
	ORR	r9, r5, #0xC0             @ I=F=1 (need to lock while updating nBufProc)
	MSR	cpsr_c, r9
	LDRB	r0, [r4, #0x01]           @ nBufProc -> r0
	SUBS	r0, r0, #0x01             @ --nBufProc?
	STRCSB	r0, [r4, #0x01]
	MSR	cpsr_c, r5
	BCC	.LNoBufProc
	EOR	r1, r1, #0x01             @ WrBufIdx ^= 1
#endif
	MOVS	r0, r1, lsl #0x1F         @ N=WrBufIdx?, C=Pause?
#if !ULC_SINGLE_BUFFER
	ADDPL	r3, r3, fp                @ Move to second buffer as needed
#endif
	BCS	.LOutputPaused
	SUBS	r1, r1, #0x01<<2          @ --nBlkRem?
	BCC	.LNoBlocksRem
	STR	r1, [r4, #0x04]
	LDRH	r4, [r4, #0x02]           @ LastSubBlockSize -> r4
	MOV	r9, #QSCALE_BASE & 0xFF00
	ORR	r9, r9, #QSCALE_BASE & 0xFF
	STR	r3, [sp, #-0x04]!

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
	LDR	pc, =.LDecodeCoefs_ChangeQuant

/**************************************/

.LDecodeCoefs_DecimationPattern:
	.word (0+8)                                   @ 0000: N/1*
#if 0
	.word (0+8)                                   @ 0001: N/1* (unused, mapped to above)
#else
.LZeroWord:
	.word 0
#endif
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

/**************************************/

.LNoBufProc:
	MOV	r0, #0x00 @ No bytes were read
	LDMFD	sp!, {r4-fp,lr}
	BX	lr

.LNoBlocksRem:
	LDMFD	sp!, {r4-fp,lr}
	LDR	r0, =ulc_StopPlayer
	BX	r0

@ r3: &OutBuf | IsStereo
@ fp:  BlockSize

.LOutputPaused:
	STRB	r1, [r4, #0x04] @ Store updated WrBufIdx
#if ULC_STEREO_SUPPORT
	AND	r6, r3, #0x01   @ IsStereo -> r6
	BIC	r3, r3, #0x01
#endif
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
#if ULC_STEREO_SUPPORT
2:	SUB	r3, r3, fp         @ Clear right buffer on stereo
	ADD	r3, r3, #0x01*ULC_MAX_BLOCK_SIZE*2
	MOVS	r6, r6, lsr #0x01
	BCS	1b
#endif
3:	@MOV	r0, #0x00 @ No bytes were read
	LDMFD	sp!, {r4-fp,lr}
	BX	lr

ASM_FUNC_END(ulc_UpdatePlayer)

/**************************************/

ASM_FUNC_GLOBAL(ulc_UpdatePlayerIWRAM)
ASM_FUNC_BEG   (ulc_UpdatePlayerIWRAM, ASM_MODE_ARM;ASM_SECTION_IWRAM)

ulc_UpdatePlayerIWRAM:

.LDecodeCoefs_EscapeCode:
	NextNybble
	@ NOTE: We are assuming that we never encounter the unallocated codes Fh,Eh,Dh or Fh,Eh,Eh here

.LDecodeCoefs_ChangeQuant:
	AND	r5, r7, #0x0F
	NextNybble
	CMP	r5, #0x0E                         @ Normal quantizer? (Fh,0h..Dh)
	BHI	.LDecodeCoefs_Stop_NoiseFill      @  Noise-fill (exp-decay to end) (Fh,Fh,Zh,Yh,Xh)
	MOVCC	lr, r5
	BCC	1f
0:	AND	r5, r7, #0x0F
	NextNybble
	CMP	r5, #0x0F                         @ Stop? (Fh,Eh,Fh)
	SUBEQ	r5, r0, fp, asr #0x10             @  Treat as zero-fill with N=CoefRem
	BEQ	.LDecodeCoefs_ZerosRun_PostBiasCore
	ADD	lr, r5, #0x0E                     @ Extended-precision quantizer (Fh,Eh,0h..Ch)
#if (0x20-24-5+ULC_COEF_PRECISION <= 0xE + 0xC) //! <- Only clip when the smallest quantizer is out of bounds of our precision
	CMP	lr, #0x20-24-5+ULC_COEF_PRECISION @ Limit LSR value to 31 and convert >=32 to LSR #32
	EORCS	r5, r9, #QSCALE_BASE ^ QSCALE_ZERO
#endif
1:	ADDCC	r5, r9, lr, lsl #0x07             @ Modify the quantizer instruction
	STRH	r5, .LDecodeCoefs_Normal_Shifter

.LDecodeCoefs_DecodeLoop:
	SUBS	r5, r0, r7, lsl #0x1C    @ -QCoef -> r5?
	BVS	.LDecodeCoefs_NoiseFill  @  8h,Zh,Yh,Xh: Noise fill
	BEQ	.LDecodeCoefs_ZerosRun   @  0h,0h..Fh:   Zeros run
	CMP	r5, #0x01<<28            @  Fh...:       Escape code
	BEQ	.LDecodeCoefs_EscapeCode
	CMN	r5, #0x01<<28            @  1h,Yh,Xh:    Zeros run (long)
	BEQ	.LDecodeCoefs_ZerosRunLong

.LDecodeCoefs_Normal:
	ADR	ip, .LDecodeCoefs_Normal_Uncompanded
	LDR	r5, [ip, r5, lsr #0x1C-2] @ Using a LUT is 1c faster than raw maths
	NextNybble
.LDecodeCoefs_Normal_Shifter:
	MOV	r5, r5, asr #0x00 @ Coef=QCoef*2^(-24+ACCURACY-Quant) -> r5 (NOTE: Self-modifying dequantization)
	STR	r5, [sl], #0x04   @ Coefs[n++] = Coef
	ADDS	fp, fp, #0x01<<16 @ --CoefRem?
	BCC	.LDecodeCoefs_DecodeLoop
1:	B	.LDecodeCoefs_NoMoreCoefs

.LDecodeCoefs_Normal_Uncompanded:
	.word 0x00000000,+0x01000000,+0x04000000,+0x09000000,+0x10000000,+0x19000000,+0x24000000,+0x31000000
	.word 0x00000000,-0x31000000,-0x24000000,-0x19000000,-0x10000000,-0x09000000,-0x04000000,-0x01000000

.LDecodeCoefs_NoiseFill:
	NextNybble
	AND	r5, r7, #0x0F         @ n -> r5
	NextNybble
	AND	ip, r7, #0x0F
	NextNybble
	ORR	r5, ip, r5, lsl #0x04
	AND	ip, r7, #0x0F
	NextNybble
	MOVS	ip, ip, lsr #0x01     @ v -> ip
	ADC	r5, r5, r5
	ADD	ip, ip, #0x01
	MUL	ip, ip, ip
	ADD	r5, r5, #0x10
	MOV	ip, ip, lsl #ULC_COEF_PRECISION-5 - 2 @ Scale = (v+1)^2*Quant/4 -> ip? (-5 for quantizer bias)
	MOVS	ip, ip, lsr lr        @ Out of range? Zero-code instead
	BEQ	.LDecodeCoefs_ZerosRun_PostBiasCore
	ADD	fp, fp, r5, lsl #0x10 @ CoefRem -= n
0:	SUB	lr, lr, r5, lsl #0x08 @ Log2[Quant] | -CoefRem<<8 -> lr
	EOR	r5, r6, r7, ror #0x17 @ Seed = [random garbage] -> r5
1:	EOR	r5, r5, r5, lsl #0x0D @ <- Xorshift (Galois LFSR can produce weird results)
	EOR	r5, r5, r5, lsr #0x11
	EORS	r5, r5, r5, lsl #0x05
	RSBCS	ip, ip, #0x00         @ Sign flip at random
	ADDS	lr, lr, #0x01<<8
	STR	ip, [sl], #0x04
	BCC	1b
2:	CMP	fp, #0x010000
	BCS	.LDecodeCoefs_DecodeLoop
	B	.LDecodeCoefs_NoMoreCoefs

.LDecodeCoefs_ZerosRun:
	NextNybble
	AND	r5, r7, #0x0F         @ n -> r5
	NextNybble
	ADD	r5, r5, #0x01
.LDecodeCoefs_ZerosRun_PostBiasCore:
	ADD	fp, fp, r5, lsl #0x10 @ CoefRem -= zR
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

.LDecodeCoefs_ZerosRunLong:
	NextNybble
	AND	r5, r7, #0x0F         @ n -> r5
	NextNybble
	AND	ip, r7, #0x0F
	NextNybble
	ORR	r5, ip, r5, lsl #0x04
	ADD	r5, r5, #0x21
	B	.LDecodeCoefs_ZerosRun_PostBiasCore

.LDecodeCoefs_Stop_NoiseFill:
	AND	ip, r7, #0x0F               @ v -> ip
	NextNybble
	AND	r5, r7, #0x0F               @ r -> r5
	NextNybble
	ORR	r5, r5, r7, lsl #0x1C       @ Shift up and append low nybble
	MOV	r5, r5, ror #0x1C
	NextNybble
1:	ADD	ip, ip, #0x01               @ Unpack p = (v+1)^2*Quant/16
	MUL	r1, ip, ip
	MUL	r2, r5, r5                  @ Unpack Decay = 1 - r^2*2^-19 -> r2
	MOV	r1, r1, lsl #ULC_COEF_PRECISION-5 - 4 @ Same as normal noise fill. Scale -> r1
	SUBS	r2, r0, r2, lsl #0x20-19
	MVNEQ	r2, #0x00                   @  Clip to slowest decay when Decay=1.0
	EOR	r5, r6, r7, ror #0x17       @ Seed = [random garbage] -> r5
1:	EOR	r5, r5, r5, lsl #0x0D @ <- Xorshift
	EOR	r5, r5, r5, lsr #0x11
	EOR	r5, r5, r5, lsl #0x05
	EOR	r3, r1, r5, asr #0x20 @ Random sign (plus some "rounding error" from using NOT as negation)
	MOV	r3, r3, asr lr
	UMULL	r0, r1, r2, r1        @ Scale *= Decay
	ADDS	fp, fp, #0x01<<16     @ --CoefRem?
	STR	r3, [sl], #0x04
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
	MOV	r0, sl                             @ Undo DCT-IV
#if ULC_USE_INPLACE_XFM
	MOV	r1, r4, lsr #0x10
	BL	Fourier_DCT4_InPlace
#else
	ADD	r1, sl, #TEMP_BUFFER_OFFS
	MOV	r2, r4, lsr #0x10
	BL	Fourier_DCT4
#endif
1:	STMFD	sp!, {r6-r9}
	MOV	r6, r4, lsr #0x10                  @ OverlapSize = SubBlockSize -> r6
	BIC	r7, r4, r6, lsl #0x10              @ LastSubBlockSize -> r7
	TST	r8, #0x08                          @ Transient subblock?
	MOVNE	ip, r9, lsr #0x10                  @  Y: OverlapSize >>= ShiftFactor(=(WindowCtrl&7))
	ANDNE	ip, ip, #0x07
	MOVNE	r6, r6, lsr ip
	CMP	r6, r7                             @ OverlapSize > LastSubBlockSize?
	MOVHI	r6, r7                             @  Y: OverlapSize = LastSubBlockSize
	LDR	r7, [sp, #0x10]                    @ &OutBuf -> r7
	MOV	r4, r4, lsr #0x10                  @ LastSubBlockSize = SubBlockSize -> r4
	ADD	r5, sl, #LAPPING_BUFFER_OFFS       @ LappingBuffer -> r5
	ADD	ip, r7, r4, lsl #0x00              @ OutBuf += SubBlockSize for next subblock
	STR	ip, [sp, #0x10]
#if ULC_STEREO_SUPPORT
	TST	r7, #0x80000000                    @ Second channel?
	BIC	r7, r7, #0x80000001                @ [Clear Chan and IsStereo from OutBuf]
	ADDNE	r7, r7, #0x01*ULC_MAX_BLOCK_SIZE*2 @  Skip to second channel data
	ADDNE	r5, r5, #0x04*ULC_MAX_BLOCK_SIZE/2
	STMFD	sp!, {r7,fp}
#endif

.LIMDCT_SwapLappedHalf:
	ADD	ip, sl, r4, lsl #0x02-1            @ Buf + N/2 -> ip
	ADD	lr, r5, r4, lsl #0x02-1            @ Lap + N/2 -> lr
	ORR	r4, r4, r6, lsl #0x10              @ SubBlockSize | OverlapSize<<16 -> r4
1:	LDMIA	r5, {r0-r1}                        @ a = Lap[n]       -> r0,r1
	LDMDB	lr, {r2-r3}                        @ b = Lap[N/2-1-n] -> r2,r3
	LDMIA	sl, {r6-r7}                        @ c = Buf[n]       -> r6,r7
	LDMDB	ip, {r8-r9}                        @ d = Buf[N/2-1-n] -> r8,r9
	STR	r0, [ip, #-0x04]!                  @ Buf[N/2-1-n] = a
	STR	r1, [ip, #-0x04]!
	STR	r3, [sl], #0x04                    @ Buf[n]       = b
	STR	r2, [sl], #0x04
	STMIA	r5!, {r6-r7}                       @ Lap[n]       = c
	STMDB	lr!, {r8-r9}                       @ Lap[N/2-1-n] = d
	CMP	sl, ip
	BCC	1b

.LIMDCT_ApplyOverlap:
	MOVS	r0, r4, lsr #0x10                  @ OverlapSize -> r0?
	BIC	r4, r4, r0, lsl #0x10              @ SubBlockSize -> r4
	SUB	sl, sl, r4, lsl #0x02-2            @ Rewind Buf
	SUB	r5, r5, r4, lsl #0x02-2            @ Rewind Lap
	BEQ	.LIMDCT_SkipOverlap
0:	LDR	r2, =0x077CB531
	LDR	r3, =ulc_Log2Table
	MUL	r1, r2, r0
	LDRB	r1, [r3, r1, lsr #0x20-5]          @ Log2[OverlapSize] -> r1
	LDR	r8, =Fourier_DCT4_TwiddleTable - 0x04*4
	LDR	r2, .LIMDCT_PatchOpcodes+0x00
	LDR	r3, .LIMDCT_PatchOpcodes+0x04
	LDR	r8, [r8, r1, lsl #0x02]            @ omega -> r8
	ADD	r2, r2, r1, lsl #0x07              @ Patch shift amounts in oscillator
	ADD	r3, r3, r1, lsl #0x07
	STR	r2, .LIMDCT_Patch0+0x00
	STR	r3, .LIMDCT_Patch0+0x04
	STR	r2, .LIMDCT_Patch1+0x00
	STR	r3, .LIMDCT_Patch1+0x04
	MOV	r9, r8, lsr #0x10                  @ s = omega.Im -> r9
	BIC	r8, r8, r9, lsl #0x10              @ c = omega.Re -> r8
1:	SUB	r6, r4, r0                         @ OverlapStart*2 = N-OverlapSize -> r6
	ADD	sl, sl, r6, lsl #0x02-1            @ BufLo = Buf + OverlapStart -> sl
	ADD	fp, sl, r4, lsl #0x02-1            @ BufHi = Buf + OverlapStart + N/2 -> fp
	SUB	r4, r4, r0, lsl #0x10-1            @ N = OverlapSize/2
10:	LDMIA	sl, {r0-r1}                        @ a = BufLo[n] -> r0,r1
	LDMIA	fp, {r2-r3}                        @ b = BufHi[n] -> r2,r3
#if ULC_USE_64BIT_MATH
	SMULL	ip, lr, r0, r9                     @ BufHi[n] = s*a0 + c*b0 -> r6
	SMLAL	ip, lr, r2, r8
	MOVS	r6, ip, lsr #0x0F
	ADC	r6, r6, lr, lsl #0x20-15
	RSB	r2, r2, #0x00                      @ BufLo[n] = c*a0 - s*b0 -> r0
	SMULL	ip, lr, r0, r8
	SMLAL	ip, lr, r2, r9
	MOVS	r0, ip, lsr #0x0F
	ADC	r0, r0, lr, lsl #0x20-15
#else
	MUL	r6, r9, r0
	MLA	r6, r8, r2, r6
	MUL	r0, r8, r0
	MUL	r2, r9, r2
	MOV	r6, r6, asr #0x0F
	SUB	r0, r0, r2
	MOV	r0, r0, asr #0x0F
#endif
	STEP_OSCILLATOR .LIMDCT_Patch0
#if ULC_USE_64BIT_MATH
	SMULL	ip, lr, r1, r9                     @ BufHi[n+1] = s*a1 + c*b1 -> r7
	SMLAL	ip, lr, r3, r8
	MOVS	r7, ip, lsr #0x0F
	ADC	r7, r7, lr, lsl #0x20-15
	RSB	r3, r3, #0x00                      @ BufLo[n+1] = c*a1 - s*b1 -> r1
	SMULL	ip, lr, r1, r8
	SMLAL	ip, lr, r3, r9
	MOVS	r1, ip, lsr #0x0F
	ADC	r1, r1, lr, lsl #0x20-15
#else
	MUL	r7, r9, r1
	MLA	r7, r8, r3, r7
	MUL	r1, r8, r1
	MUL	r3, r9, r3
	MOV	r7, r7, asr #0x0F
	SUB	r1, r1, r3
	MOV	r1, r1, asr #0x0F
#endif
	STEP_OSCILLATOR .LIMDCT_Patch1
	STMIA	sl!, {r0-r1}
	STMIA	fp!, {r6-r7}
	ADDS	r4, r4, #0x02<<16                  @ --N?
	BCC	10b
2:	SUB	sl, sl, r4, lsl #0x02-1            @ Rewind Buf
.LIMDCT_SkipOverlap:

.LIMDCT_ReverseLastHalf:
	ADD	r8, sl, r4, lsl #0x02-1            @ BufLo = Buf + N/2 -> r8
	ADD	r9, sl, r4, lsl #0x02              @ BufHi = Buf + N   -> r9
1:	LDMIA	r8, {r0-r3}                        @ a = BufLo[ n] -> r0,r1,r2,r3
	LDMDB	r9, {r6-r7,ip,lr}                  @ b = BufHi[-n] -> lr,ip,r7,r6
	STR	r0, [r9, #-0x04]!                  @ BufLo[ n] = b
	STR	r1, [r9, #-0x04]!
	STR	r2, [r9, #-0x04]!
	STR	r3, [r9, #-0x04]!
	STR	lr, [r8], #0x04                    @ BufHi[-n] = a
	STR	ip, [r8], #0x04
	STR	r7, [r8], #0x04
	STR	r6, [r8], #0x04
	CMP	r8, r9
	BCC	1b
2:	LDMFD	sp!, {r7,fp}                       @ Restore OutBuf,BlockSize

@ r0: [Scratch]
@ r1: [Scratch]
@ r2: [Scratch]
@ r3: [Scratch]
@ r4:  SubBlockSize
@ r5: &LapSrc
@ r6: &LapDst
@ r7: &OutBuf
@ r8:  nAvailable*2
@ r9:  nFromLap
@ sl: &Buf
@ fp:  BlockSize
@ ip:  ClipMask(=7Fh)
@ lr: [Unused]

.LIMDCT_LappingCycle:
	ADD	r5, r5, fp, lsl #0x02-1            @ LapSrc = Lap + BlockSize/2 -> r5
	ADD	r6, r5, #0x00                      @ LapDst = Lap + BlockSize/2 -> r6
	SUB	r8, fp, r4                         @ nAvailable << 1 = BlockSize - SubBlockSize -> r8
	CMP	r8, r4, lsl #0x01                  @ nFromLap = MIN(nAvailable, SubBlockSize) -> r9
	MOVCC	r9, r8, lsr #0x01
	MOVCS	r9, r4
	MOV	ip, #0x7F                          @ ClipMask -> ip
1:	SUBS	r9, r9, r9, lsl #0x10              @ Store output from lapping buffer (nFromLap samples)
	BCS	2f
10:	LDMDB	r5!, {r0-r3}                       @  *Dst++ = *--LapSrc
	SCALE_AND_CLIP r0, ip
	SCALE_AND_CLIP r1, ip, 0xFF
	SCALE_AND_CLIP r2, ip, 0xFF
	SCALE_AND_CLIP r3, ip, 0xFF
	ORR	r0, r1, r0, lsl #0x08
	ORR	r0, r2, r0, lsl #0x08
	ORR	r0, r3, r0, lsl #0x08
	STR	r0, [r7], #0x04
	ADDS	r9, r9, #0x04<<16
	BCC	10b
2:	SUB	r4, r4, r4, lsl #0x10              @ Store remaining output from decode buffer (SubBlockSize-nFromLap samples)
	ADDS	r4, r4, r9, lsl #0x10
	BCS	3f
20:	LDMIA	sl!, {r0-r3}                       @  *Dst++ = *Buf++
	SCALE_AND_CLIP r0, ip, 0xFF
	SCALE_AND_CLIP r1, ip, 0xFF
	SCALE_AND_CLIP r2, ip, 0xFF
	SCALE_AND_CLIP r3, ip
	ORR	r3, r2, r3, lsl #0x08
	ORR	r3, r1, r3, lsl #0x08
	ORR	r3, r0, r3, lsl #0x08
	STR	r3, [r7], #0x04
	ADDS	r4, r4, #0x04<<16
	BCC	20b
3:	SUBS	r8, r8, r4, lsl #0x01              @ Shift lapped samples down (nAvailable-SubBlockSize samples)
	BLS	4f
30:	LDMDB	r5!, {r0-r3}                       @  *--LapDst = *--LapSrc
	STMDB	r6!, {r0-r3}
	SUBS	r8, r8, #0x04 << 1
	BHI	30b
4:	CMP	r9, #0x00                          @ Store new lapped samples (nFromLap samples)
	BEQ	5f
40:	LDMIA	sl!, {r0-r3}                       @  *--LapDst = *Buf++
	STR	r0, [r6, #-0x04]!
	STR	r1, [r6, #-0x04]!
	STR	r2, [r6, #-0x04]!
	STR	r3, [r6, #-0x04]!
	SUBS	r9, r9, #0x04
	BHI	40b
5:

.LDecodeCoefs_SubBlockLoop_Tail:
	LDMFD	sp!, {r6-r9}
	MOVS	r8, r8, lsr #0x04 @ Advance decimation pattern. Finished?
	LDRNE	pc, =.LDecodeCoefs_SubBlockLoop

@ r4:  LastSubBlockSize
@ r5:
@ r6: &NextData | NybbleCounter<<29
@ r7:  StreamData
@ r8:  DecimationPattern
@ r9:  QScaleBase | WindowCtrl<<16
@ sl:
@ fp:  BlockSize

.LDecodeCoefs_NextChan:
#if ULC_STEREO_SUPPORT
	LDR	r0, [sp], #0x04
#else
	ADD	sp, sp, #0x04 @ Pop OutBuf, not needed anymore
#endif
	LDR	r5, =ulc_State
#if ULC_STEREO_SUPPORT
	SUB	r0, r0, fp            @ Rewind OutBuf
	ADDS	r0, r0, r0, lsl #0x1F @ Stereo, second channel?
	LDRMIH	r4, [r5, #0x02]       @  Restore old LastSubBlockSize
	STRMI	r0, [sp, #-0x04]!
	LDRMI	pc, =.LChannels_Loop
#endif
0:	STRH	r4, [r5, #0x02] @ Save LastSubBlockSize

/**************************************/

#if ULC_STEREO_SUPPORT
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
#endif

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

.LExit:
	LDMFD	sp!, {r4-fp,lr}
	BX	lr

/**************************************/

.LIMDCT_PatchOpcodes:
	.word 0xE048804C @ SUB r8, r8, ip, asr #0+xx
	.word 0xE089904E @ ADD r9, r9, lr, asr #0+xx

ASM_FUNC_END(ulc_UpdatePlayerIWRAM)

/**************************************/

ASM_DATA_BEG(ulc_TransformBuffer, ASM_SECTION_IWRAM_BSS;ASM_ALIGN(4))

ulc_TransformBuffer: .space 0x04 * ULC_MAX_BLOCK_SIZE

ASM_DATA_END(ulc_TransformBuffer)

/**************************************/
#if !ULC_USE_INPLACE_XFM
/**************************************/

ASM_DATA_BEG(ulc_TransformTemp, ASM_SECTION_IWRAM_BSS;ASM_ALIGN(4))

ulc_TransformTemp: .space 0x04 * ULC_MAX_BLOCK_SIZE

ASM_DATA_END(ulc_TransformTemp)

/**************************************/
#endif
/**************************************/

//! This buffer needs clearing inside ulc_StartPlayer(), so it needs to be global
ASM_DATA_GLOBAL(ulc_LappingBuffer)
ASM_DATA_BEG(ulc_LappingBuffer, ASM_SECTION_IWRAM_BSS;ASM_ALIGN(4))

ulc_LappingBuffer: .space 0x04 * (ULC_MAX_BLOCK_SIZE/2) * (1+ULC_STEREO_SUPPORT)

ASM_DATA_END(ulc_LappingBuffer)

/**************************************/
//! EOF
/**************************************/
