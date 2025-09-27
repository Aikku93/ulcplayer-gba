/**************************************/
#include "AsmMacros.h"
/**************************************/
#include "ulc_Specs.h"
/**************************************/
#if ULC_USE_INPLACE_XFM
/**************************************/
@ Implementation from:
@  "Regular FFT-related Transform Kernels for DCT/DST-based Polyphase Filter Banks"
@  DOI: 10.1109/ICASSP.1991.150852
/**************************************/

@ Perform complex multiply:
@  Rn = Conjugate[Rm]*Rn
@ Notes:
@  * Rm is expected to have smaller magnitude,
@    for faster MUL/SMULL execution.
@  * With 64-bit math, RnRe (or RnIm when conjugated) is destroyed.
@  * Without 64-bit math, t1 is unused.
.macro CPLXMUL RdRe,RdIm, RmRe,RmIm, RnRe,RnIm, t0,t1, Conjugate=0
#if ULC_USE_64BIT_MATH
.if (\Conjugate == 0)
	SMULL	\RdRe, \t0, \RnRe, \RmRe
	SMULL	\RdIm, \t1, \RnIm, \RmRe
	RSB	\RnRe, \RnRe, #0x00
	SMLAL	\RdRe, \t0, \RnIm, \RmIm
	SMLAL	\RdIm, \t1, \RnRe, \RmIm
.else
	SMULL	\RdRe, \t0, \RnRe, \RmRe
	SMULL	\RdIm, \t1, \RnRe, \RmIm
	SMLAL	\RdRe, \t0, \RnIm, \RmIm
	RSB	\RnIm, \RnIm, #0x00
	SMLAL	\RdIm, \t1, \RnIm, \RmRe
.endif
	MOVS	\RdRe, \RdRe, lsr #0x0F
	ADC	\RdRe, \RdRe, \t0, lsl #0x20-15
	MOVS	\RdIm, \RdIm, lsr #0x0F
	ADC	\RdIm, \RdIm, \t1, lsl #0x20-15
#else
	MUL	\RdRe, \RnRe, \RmRe
	MUL	\RdIm, \RnIm, \RmRe
	MUL	\t0, \RnRe, \RmIm
	MLA	\RdRe, \RnIm, \RmIm, \RdRe
.if (\Conjugate == 0)
	SUB	\RdIm, \RdIm, \t0
.else
	RSB	\RdIm, \RdIm, \t0
.endif
	MOV	\RdRe, \RdRe, asr #0x0F
	MOV	\RdIm, \RdIm, asr #0x0F
#endif
.endm

@ I forgot where this oscillator came from...
@ Parameters:
@  k = Tan[omega]
@ Update loop:
@  ck = c*k
@  sk = s*k
@  c -= sk
@  s += ck
@ This is slightly faster than the FFT oscillator,
@ but only really works for larger N.
.macro STEP_OSCILLATOR_0 PatchLabel
	ADD	ip, r3, r3, asr #0x01 @ ks = s*k -> ip
	ADD	ip, ip, ip, asr #0x04
	ADD	lr, r2, r2, asr #0x02 @ kc = c*k -> lr
	ADD	lr, lr, lr, asr #0x02
\PatchLabel :
	SUB	r2, r2, ip            @ c -= ks (needs scaling by 2/N)
	ADD	r3, r3, lr            @ s += kc (needs scaling by 2/N)
.endm
.macro STEP_OSCILLATOR_1 PatchLabel
	ADD	ip, fp, fp, asr #0x01
	ADD	ip, ip, ip, asr #0x04
	ADD	lr, sl, sl, asr #0x02
	ADD	lr, lr, lr, asr #0x02
\PatchLabel :
	SUB	sl, sl, ip
	ADD	fp, fp, lr
.endm

/**************************************/

ASM_DATA_BEG(Fourier_DCT4_InPlace_TwiddleTable, ASM_MODE_ARM;ASM_SECTION_RODATA;ASM_ALIGN(4))

@ Since we run two oscillators, we need both the first and last terms.
@ Table = 2^15*{E^(I*Pi*(0 + 1/8)/N),-Conjugate[E^(I*Pi*(N-1 + 1/8)/N)]}
Fourier_DCT4_InPlace_TwiddleTable:
	.hword 0x7FFF,0x00C9, 0x7FE2,0x0057F @ N = 64
	.hword 0x8000,0x0065, 0x7FF8,0x002C0 @ N = 128
	.hword 0x8000,0x0032, 0x7FFE,0x00160 @ N = 256
	.hword 0x8000,0x0019, 0x8000,0x000B0 @ N = 512
	.hword 0x8000,0x000D, 0x8000,0x00058 @ N = 1024
	.hword 0x8000,0x0006, 0x8000,0x0002C @ N = 2048

ASM_DATA_END(Fourier_DCT4_InPlace_TwiddleTable)

/**************************************/

@ r0: &Buf
@ r1:  N
@ NOTE: Must return to ARM code

ASM_FUNC_GLOBAL(Fourier_DCT4_InPlace)
ASM_FUNC_BEG   (Fourier_DCT4_InPlace, ASM_MODE_ARM;ASM_SECTION_IWRAM)

Fourier_DCT4_InPlace:
	STMFD	sp!, {r4-fp,lr}
	LDR	ip, =0x077CB531               @ Log2[N] -> ip
	LDR	r3, =ulc_Log2Table
	MUL	r2, ip, r1
	LDRB	ip, [r3, r2, lsr #0x20-5]
	LDR	r3, =Fourier_DCT4_InPlace_TwiddleTable - 0x08*6
	ADD	r3, r3, ip, lsl #0x03
	LDMIA	r3, {r2,sl}
	MOV	r3, r2, lsr #0x10             @ omega0 = E^(I*Pi*(0+1/8)/N) -> r2,r3
	BIC	r2, r2, r3, lsl #0x10
	MOV	fp, sl, lsr #0x10             @ omega1 = E^(I*Pi*(N-1+1/8)/N) -> sl,fp
	BIC	sl, sl, fp, lsl #0x10
	STMFD	sp!, {r0-r1,r2-r3,sl-fp}      @ Push {Buf,N,omega0,omega1}

.LPatchOscillators:
	ADR	lr, .LPatchOpcodes
	LDMIA	lr, {r4-r7}
	ADD	r4, r4, ip, lsl #0x07
	ADD	r5, r5, ip, lsl #0x07
	ADD	r6, r6, ip, lsl #0x07
	ADD	r7, r7, ip, lsl #0x07
	STR	r4, .LPreRotate_Patch0+0x00
	STR	r5, .LPreRotate_Patch0+0x04
	STR	r6, .LPreRotate_Patch1+0x00
	STR	r7, .LPreRotate_Patch1+0x04
	STR	r4, .LPostRotate_Patch0+0x00
	STR	r5, .LPostRotate_Patch0+0x04
	STR	r6, .LPostRotate_Patch1+0x00
	STR	r7, .LPostRotate_Patch1+0x04

@ Reverse the odd elements, then multiply with E^(-I*Pi*(k+1/8)/N)
@ Note that we must conjugate the twiddle factors!
@ Also note that the omega1 oscillator has Re/Im swapped!
@ Registers:
@  r0: &BufA (increasing)
@  r1: &BufB (decreasing)
@  r2:  omega0.Re
@  r3:  omega0.Im
@  r4:
@  r5:
@  r6:
@  r7:
@  r8:
@  r9:
@  sl:  omega1.Re
@  fp:  omega1.Im
@  ip:
@  lr:

.LPreRotate:
	ADD	r1, r0, r1, lsl #0x02         @ &BufEnd -> r1
1:	LDMIA	r0, {r4,r5}                   @ a0 -> r4, a1 -> r5
	LDMDB	r1, {r6,r7}                   @ b0 -> r6, b1 -> r7
	CPLXMUL	r8,r9, r2,r3, r4,r7, ip,lr    @ omega0*(a0 + I*b1) -> r8,r9
	CPLXMUL	r4,r7, fp,sl, r6,r5, ip,lr    @ omega1*(b0 + I*a1) -> r4,r7
	STMIA	r0!, {r8,r9}
	STMDB	r1!, {r4,r7}
	STEP_OSCILLATOR_0 .LPreRotate_Patch0
	STEP_OSCILLATOR_1 .LPreRotate_Patch1
	CMP	r0, r1
	BCC	1b

.LDoFFT:
	LDMFD	sp, {r0,r1}                   @ FFT(Z, N/2)
	MOV	r1, r1, lsr #0x01
	BL	Fourier_FFT_InPlace

@ Multiply with E^(-I*Pi*(k+1/8)/N), then reverse the odd elements again.
@ Same setup as pre-rotation.
@ PONDER: The original paper I got this implementation from did
@ not mention conjugation after the complex multiply, but it
@ seems to be necessary to get correct results?
.LPostRotate:
	LDMFD	sp!, {r0-r1,r2-r3,sl-fp}      @ Restore {Buf,N,omega0,omega1}
	ADD	r1, r0, r1, lsl #0x02         @ &BufEnd -> r1
1:	LDMIA	r0, {r4,r5}                   @ a0 -> r4, a1 -> r5
	LDMDB	r1, {r6,r7}                   @ b0 -> r6, b1 -> r7
	CPLXMUL	r8,ip, r2,r3, r4,r5, r9,lr, 1 @ Conjugate[omega0*(a0 + I*a1)] -> r8,ip
	CPLXMUL	r9,lr, fp,sl, r6,r7, r4,r5, 1 @ Conjugate[omega1*(b0 + I*b1)] -> r9,lr
	STMIA	r0!, {r8,lr}
	STMDB	r1!, {r9,ip}
	STEP_OSCILLATOR_0 .LPostRotate_Patch0
	STEP_OSCILLATOR_1 .LPostRotate_Patch1
	CMP	r0, r1
	BCC	1b

.LExit:
	LDMFD	sp!, {r4-fp,lr}
	BX	lr

.LPatchOpcodes:
	.word 0xE0421FCC @ SUB r2, r2, ip, asr #-1
	.word 0xE0832FCE @ ADD r3, r3, lr, asr #-1
	.word 0xE04A9FCC @ SUB sl, sl, ip, asr #-1
	.word 0xE08BAFCE @ ADD fp, fp, lr, asr #-1

ASM_FUNC_END(Fourier_DCT4_InPlace)

/**************************************/
#endif
/**************************************/
//! EOF
/**************************************/
