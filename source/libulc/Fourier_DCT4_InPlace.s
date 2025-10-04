/**************************************/
#include "AsmMacros.h"
/**************************************/
#include "ulc_Specs.h"
/**************************************/
#if ULC_USE_INPLACE_XFM
/**************************************/
@ Original implementation from:
@  "Regular FFT-related Transform Kernels for DCT/DST-based Polyphase Filter Banks"
@  DOI: 10.1109/ICASSP.1991.150852
@ More ideas inspired by:
@  "A Low Complexity Transform: Evolved DCT"
@  DOI: 10.1109/CSE.2011.36
/**************************************/

@ Perform conjugated complex multiply:
@  Rn = Conjugate[Conjugate[Rm]*Rn] = Rm*Conjugate[Rn]
@ This arises because we need a conjugation on the output
@ after the complex multiply, but we also want to conjugate
@ the twiddle factor.
@ Notes:
@  * Rn is expected to have smaller amplitude than Rm.
.macro CPLXMUL RdRe,RdIm, RmRe,RmIm, RnRe,RnIm, t0,t1
#if ULC_USE_64BIT_MATH
	RSB	\RdRe, \RnIm, #0x00
	SMULL	\RdIm, \t1, \RdRe, \RmRe
	SMLAL	\RdIm, \t1, \RnRe, \RmIm
	SMULL	\RdRe, \t0, \RnRe, \RmRe
	SMLAL	\RdRe, \t0, \RnIm, \RmIm
	MOVS	\RdIm, \RdIm, lsr #0x0F
	ADC	\RdIm, \RdIm, \t1, lsl #0x20-15
	MOVS	\RdRe, \RdRe, lsr #0x0F
	ADC	\RdRe, \RdRe, \t0, lsl #0x20-15
#else
	MUL	\RdRe, \RnRe, \RmRe
	MUL	\RdIm, \RnIm, \RmRe
	MUL	\t0, \RnRe, \RmIm
	MLA	\RdRe, \RnIm, \RmIm, \RdRe
	RSB	\RdIm, \RdIm, \t0
	MOV	\RdIm, \RdIm, asr #0x0F
	MOV	\RdRe, \RdRe, asr #0x0F
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
.macro STEP_OSCILLATOR PatchLabel
	ADD	ip, r3, r3, asr #0x01 @ ks = s*k -> ip
	ADD	ip, ip, ip, asr #0x04
	ADD	lr, r2, r2, asr #0x02 @ kc = c*k -> lr
	ADD	lr, lr, lr, asr #0x02
\PatchLabel :
	SUB	r2, r2, ip         @ c -= ks (needs scaling by 2/N)
	ADD	r3, r3, lr         @ s += kc (needs scaling by 2/N)
.endm

/**************************************/

ASM_DATA_BEG(Fourier_DCT4_InPlace_TwiddleTable, ASM_SECTION_RODATA;ASM_ALIGN(4))

@ Table = 2^15*{E^(I*Pi*(0 + 1/2)/N), E^(I*Pi*(0 - 1/4)/N)}
@ Notes:
@  * For pre-rotation, we need one oscillator only - we step the
@    oscillator after processing the low half (but before the high
@    half), and transform via Conjugate[I*omega].
@  * For post-rotation, we can use the same setup, but rather than
@    re-using the oscillator directly, we have to do a half-sample
@    step by multiplying with E^(I*Pi*(1/2)/N).
@    The rotation can be approximated via:
@     omega2.Re = omega1.Re - (omega1.Im * (1 + 2^-2)(1 + 2^-2) / N)
@     omega2.Im = omega1.Im + (omega1.Re * (1 + 2^-2)(1 + 2^-2) / N)
@    ... and then Conjugate[I*omega2] as before.
@  * When using approximate DCT, we ignore the rotation step above,
@    since it becomes really minor for large N.
Fourier_DCT4_InPlace_TwiddleTable:
	.hword 0x7FF6,0x0324, 0x7FFE,-0x0192 @ N = 64
	.hword 0x7FFE,0x0192, 0x7FFF,-0x00C9 @ N = 128
	.hword 0x7FFF,0x00C9, 0x8000,-0x0065 @ N = 256
	.hword 0x8000,0x0065, 0x8000,-0x0032 @ N = 512
	.hword 0x8000,0x0032, 0x8000,-0x0019 @ N = 1024
	.hword 0x8000,0x0019, 0x8000,-0x000D @ N = 2048

#undef CREATE_ENTRY

ASM_DATA_END(Fourier_DCT4_InPlace_TwiddleTable)

/**************************************/

@ r0: &Buf
@ r1:  N
@ NOTE: Must return to ARM code

ASM_FUNC_GLOBAL(Fourier_DCT4_InPlace)
ASM_FUNC_BEG   (Fourier_DCT4_InPlace, ASM_MODE_ARM;ASM_SECTION_IWRAM)

Fourier_DCT4_InPlace:
	STMFD	sp!, {r4-fp,lr}
	LDR	ip, =0x077CB531            @ Log2[N] -> ip
	LDR	r3, =ulc_Log2Table
	MUL	r2, ip, r1
	LDRB	ip, [r3, r2, lsr #0x20-5]
	LDR	r3, =Fourier_DCT4_InPlace_TwiddleTable - 0x08*6
	ADD	r3, r3, ip, lsl #0x03
	LDMIA	r3, {r2,r4}
	STMFD	sp!, {r0-r1,r4}            @ Push {Buf,N,omega1}

.LPatchOscillators:
	ADR	lr, .LPatchOpcodes
#if ULC_PRECISE_DCT
	LDMIA	lr, {r4-r7}
#else
	LDMIA	lr, {r4-r5}
#endif
	ADD	r4, r4, ip, lsl #0x07
	ADD	r5, r5, ip, lsl #0x07
	STR	r4, .LPreRotate_Patch+0x00
	STR	r5, .LPreRotate_Patch+0x04
	STR	r4, .LPostRotate_Patch+0x00
	STR	r5, .LPostRotate_Patch+0x04
#if ULC_PRECISE_DCT
	ADD	r6, r6, ip, lsl #0x07
	ADD	r7, r7, ip, lsl #0x07
	STR	r6, .LPostRotate_RotatePatch+0x00
	STR	r7, .LPostRotate_RotatePatch+0x04
#endif

@ Reverse the odd elements, then multiply with E^(-I*Pi*(k+1/2)/N)
@ Note that we must conjugate the twiddle factors!
@ Notes:
@  -The original paper I followed used the same rotation factor
@   for both pre- and post-rotation. However, testing showed that
@   it is possible to use the current setup, which saves on the
@   second oscillator during pre-rotation.
@ Registers:
@  r0: &BufA (increasing)
@  r1: &BufB (decreasing)
@  r2:  omega1.Re
@  r3:  omega1.Im
@  r4:
@  r5:
@  r6:
@  r7:
@  r8:
@  r9:
@  sl:
@  fp:
@  ip:
@  lr:

.LPreRotate:
	ADD	r1, r0, r1, lsl #0x02      @ &BufEnd -> r1
	MOV	r3, r2, asr #0x10          @ omega = E^(I*Pi*(0+1/2)/N) -> r2,r3
	BIC	r2, r2, r3, lsl #0x10
1:	LDMIA	r0, {r4,r5}                @ a0 -> r4, a1 -> r5
	LDMDB	r1, {r6,r7}                @ b0 -> r6, b1 -> r7
#if ULC_USE_64BIT_MATH
	RSB	r8, r4, #0x00              @ omega*(a0 + I*b1) -> r8,r9
	SMULL	r9, lr, r7, r2
	SMLAL	r9, lr, r8, r3
	SMULL	r8, ip, r4, r2
	SMLAL	r8, ip, r7, r3
	MOVS	r8, r8, lsr #0x0F
	ADC	r8, r8, ip, lsl #0x20-15
	MOVS	r9, r9, lsr #0x0F
	ADC	r9, r9, lr, lsl #0x20-15
#else
	MUL	r8, r4, r2
	MUL	r9, r7, r2
	MUL	ip, r4, r3
	MLA	r8, r7, r3, r8
	SUB	r9, r9, ip
	MOV	r9, r9, asr #0x0F
	MOV	r8, r8, asr #0x0F
#endif
	STEP_OSCILLATOR .LPreRotate_Patch
#if ULC_USE_64BIT_MATH
	RSB	r4, r6, #0x00              @ Conjugate[I*omega]*(b0 + I*a1) -> r4,r7
	SMULL	r7, lr, r5, r3
	SMLAL	r7, lr, r4, r2
	SMULL	r4, ip, r6, r3
	SMLAL	r4, ip, r5, r2
	MOVS	r7, r7, lsr #0x0F
	ADC	r7, r7, lr, lsl #0x20-15
	MOVS	r4, r4, lsr #0x0F
	ADC	r4, r4, ip, lsl #0x20-15
#else
	MUL	r4, r6, r3
	MUL	r7, r5, r3
	MUL	ip, r6, r2
	MLA	r4, r5, r2, r4
	SUB	r7, r7, ip
	MOV	r7, r7, asr #0x0F
	MOV	r4, r4, asr #0x0F
#endif
	STMIA	r0!, {r8,r9}
	STMDB	r1!, {r4,r7}
	CMP	r0, r1
	BCC	1b

.LDoFFT:
	LDMFD	sp, {r0,r1}                @ FFT(Z, N/2)
	MOV	r1, r1, lsr #0x01
	BL	Fourier_FFT_InPlace

/**************************************/

@ Multiply with E^(-I*Pi*(k-1/4)/N), then reverse the odd elements again.
@ Same setup as pre-rotation, but with an optional rotation step.
@ PONDER: The original paper I got this implementation from did
@ not mention conjugation after the complex multiply, but it
@ seems to be necessary to get correct results?
.LPostRotate:
	LDMFD	sp!, {r0-r1,r2}            @ Restore {Buf,N,omega1}
0:	ADD	r1, r0, r1, lsl #0x02      @ &BufEnd -> r1
	MOV	r3, r2, asr #0x10          @ omega1 = E^(I*Pi*(0-1/4)/N) -> r2,r3
	BIC	r2, r2, r3, lsl #0x10
1:	LDMIA	r0, {r4,r5}                @ a0 -> r4, a1 -> r5
	LDMDB	r1, {r6,r7}                @ b0 -> r6, b1 -> r7
	CPLXMUL	r8,fp, r2,r3, r4,r5, ip,lr @ Conjugate[omega1*(a0 + I*a1)] -> r8,fp
	STEP_OSCILLATOR .LPostRotate_Patch
#if ULC_PRECISE_DCT
	ADD	ip, r3, r3, lsl #0x02      @ Rotate twiddle factor -> fp,sl
	ADD	ip, ip, ip, lsl #0x02
	ADD	lr, r2, r2, lsl #0x02
	ADD	lr, lr, lr, lsl #0x02
.LPostRotate_RotatePatch:
	SUB	ip, r2, ip, asr #0x04
	ADD	lr, r3, lr, asr #0x04
	CPLXMUL	r9,sl, lr,ip, r6,r7, r4,r5 @ Conjugate[omega1*(a0 + I*a1)] -> r9,sl
#else
	CPLXMUL	r9,sl, r3,r2, r6,r7, r4,r5
#endif
	STMIA	r0!, {r8,sl}
	STMDB	r1!, {r9,fp}
	CMP	r0, r1
	BCC	1b

.LExit:
	LDMFD	sp!, {r4-fp,lr}
	BX	lr

.LPatchOpcodes:
	.word 0xE0421FCC @ SUB r2, r2, ip, asr #-1
	.word 0xE0832FCE @ ADD r3, r3, lr, asr #-1
#if ULC_PRECISE_DCT
	SUB	ip, r2, ip, asr #0x04 @ Need to shift by Log2[N]
	ADD	lr, r3, lr, asr #0x04
#endif

ASM_FUNC_END(Fourier_DCT4_InPlace)

/**************************************/
#endif
/**************************************/
//! EOF
/**************************************/
