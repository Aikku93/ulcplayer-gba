/**************************************/
#include "AsmMacros.h"
/**************************************/
#include "ulc_Specs.h"
/**************************************/
#if ULC_USE_INPLACE_XFM
/**************************************/

@ Perform complex multiply:
@  Rn = Conjugate[Rm]*Rn
@ Notes:
@  * Rd can be Rn.
@  * Rm is expected to have smaller magnitude,
@    for faster MUL/SMULL execution.
@  * Without 64-bit math, Rd is left unscaled.
.macro CPLXMUL RdRe,RdIm, RmRe,RmIm, RnRe,RnIm, t0,t1,t2,t3
#if ULC_USE_64BIT_MATH
	SMULL	\t0, \t1, \RnRe, \RmRe
	SMULL	\t2, \t3, \RnIm, \RmRe
	RSB	\RdRe, \RnRe, #0x00
	SMLAL	\t0, \t1, \RnIm, \RmIm
	SMLAL	\t2, \t3, \RdRe, \RmIm
	MOVS	\RdRe, \t0, lsr #0x0F
	ADC	\RdRe, \RdRe, \t1, lsl #0x20-15
	MOVS	\RdIm, \t2, lsr #0x0F
	ADC	\RdIm, \RdIm, \t3, lsl #0x20-15
#else
	MUL	\t0, \RnRe, \RmRe
	MUL	\t1, \RnIm, \RmRe
	MUL	\t2, \RnRe, \RmIm
	MLA	\RdRe, \RnIm, \RmIm, \t0
	SUB	\RdIm, \t1, \t2
#endif
.endm

@ We use recursive multiplications of the form:
@  2^-m * Product[(1 +/- 2^-c[k]), k]
@ so we use a compact form to expand the definitions,
@ where we provide m, then n0, n1, n2... and so on.
.macro PolyOp Rd, Rm, Rn, i
	.if (\i < 0)
		SUB	\Rd, \Rm, \Rn, asr #-\i
	.else
		ADD	\Rd, \Rm, \Rn, asr #\i
	.endif
.endm

@ Oscillator implementation from:
@ "A New Recursive Quadrature Oscillator" by Martin Vicanek
#define PATCH_OFFS_A (0x04 * 2) @ "SUB r4, r2, r4, asr #..."
#define PATCH_OFFS_B (0x04 * 5) @ "ADD r3, r3, r5, asr #..."
#define PATCH_OFFS_C (0x04 * 8) @ "SUB r2, r4, r5, asr #..."
.macro MAKE_OSCILLATOR k1a_0,k1a_1,k1a_2, k2_0,k2_1,k2_2, k1b_0,k1b_1,k1b_2
	PolyOp	r4, r3, r3, \k1a_1
	PolyOp	r4, r4, r4, \k1a_2
	SUB	r4, r2, r4, asr #\k1a_0
	PolyOp	r5, r4, r4, \k2_1
	PolyOp	r5, r5, r5, \k2_2
	ADD	r3, r3, r5, asr #\k2_0
	PolyOp	r5, r3, r3, \k1b_1
	PolyOp	r5, r5, r5, \k1b_2
	SUB	r2, r4, r5, asr #\k1b_0
.endm
.macro MAKE_OSCILLATOR_SPACE
	.rept 9; NOP; .endr
.endm

/**************************************/

ASM_DATA_BEG(Fourier_FFT_TwiddleTable, ASM_MODE_ARM;ASM_SECTION_RODATA;ASM_ALIGN(4))

@ Parameters:
@  k1 = Tan[omega*(1/2)]
@  k2 = Sin[omega]
@ Operation:
@  w = c - k1a*s
@  s = s + k2*w
@  c = w - k1b*s
@ Note that N >= 32 has the same k1a/k2/k1b, up to scaling.
@ Therefore, we only patch for N <= 32, and then /update/
@ the shift factors for N > 32 inside the code.

Fourier_FFT_TwiddleTable:
0:	.hword 0x5A82,0x5A82
	MAKE_OSCILLATOR 1,-4,-3, 0,-4,-2, 1,+3,-2 @ N = 8
0:	.hword 0x7642,0x30FC
	MAKE_OSCILLATOR 2,+4,-2, 1,-3,-3, 2,+4,-2 @ N = 16
0:	.hword 0x7D8A,0x18F9
	MAKE_OSCILLATOR 4,+2,+2, 3,+2,+2, 3,+4,-2 @ N = 32
0:	.hword 0x7F62,0x0C8C
	@MAKE_OSCILLATOR 5,+2,+2, 4,+2,+2, 4,+4,-2 @ N = 64
0:	.hword 0x7FD9,0x0648
	@MAKE_OSCILLATOR 6,+2,+2, 5,+2,+2, 5,+4,-2 @ N = 128
0:	.hword 0x7FF6,0x0324
	@MAKE_OSCILLATOR 7,+2,+2, 6,+2,+2, 6,+4,-2 @ N = 256
0:	.hword 0x7FFE,0x0192
	@MAKE_OSCILLATOR 8,+2,+2, 7,+2,+2, 7,+4,-2 @ N = 512
0:	.hword 0x7FFF,0x00C9
	@MAKE_OSCILLATOR 9,+2,+2, 8,+2,+2, 8,+4,-2 @ N = 1024

ASM_DATA_END(Fourier_FFT_TwiddleTable)

/**************************************/

@ r0: &Buf
@ r1:  N
@ NOTE: Must return to ARM code

ASM_FUNC_GLOBAL(Fourier_FFT_InPlace)
ASM_FUNC_BEG   (Fourier_FFT_InPlace, ASM_MODE_ARM;ASM_SECTION_IWRAM)

Fourier_FFT_InPlace:
	STMFD	sp!, {r4-fp,lr}
	ADD	sl, r0, r1, lsl #0x03            @ &BufEnd -> sl

.LBitReversePermute:
	MOV	r2, #0x01                        @ i=1 [skip first entry]
	MOV	r3, #0x00                        @ j=0
#if 0 //! Standard bit-reverse permutation
1:	MOV	ip, r1, lsr #0x01                @ k = N/2, update bit-reversed counter j
0:	SUBS	r3, r3, ip                       @ while(j >= k) j -= k, k >>= 1
	MOVCS	ip, ip, lsr #0x01
	SUBCSS	r3, r3, ip                       @  * Unroll
	MOVCS	ip, ip, lsr #0x01
	BCS	0b
	ADD	r3, r3, ip, lsl #0x01            @ Restore j, then j += k
0:	CMP	r2, r3                           @ i < j?
	BCS	10f
	ADD	ip, r0, r2, lsl #0x03            @  Swap Buf[i],Buf[j]
	ADD	lr, r0, r3, lsl #0x03
	LDMIA	ip, {r4-r5}
	LDMIA	lr, {r6-r7}
	STMIA	lr, {r4-r5}
	STMIA	ip, {r6-r7}
10:	ADDS	r2, r2, #0x01                    @ i++ [C=0]
	SBCS	ip, r1, r2                       @ i < N-1? (via N > i+1)
	BHI	1b
#else //! "Algorithms for programmers", pg. 118
1:	ADD	r3, r3, r1, lsr #0x01            @ [x-odd] j += N/2
	ADD	ip, r0, r2, lsl #0x03            @ Swap Buf[i],Buf[j]
	ADD	lr, r0, r3, lsl #0x03
	LDMIA	ip, {r4-r5}
	LDMIA	lr, {r6-r7}
	STMIA	lr, {r4-r5}
	STMIA	ip, {r6-r7}
	ADD	r2, r2, #0x01                    @ ++i
2:	MOV	ip, r1, lsr #0x01                @ [x-even] k = N/2, update bit-reversed counter j
0:	SUBS	r3, r3, ip                       @ while(j >= k) j -= k, k >>= 1
	MOVCS	ip, ip, lsr #0x01
	SUBCSS	r3, r3, ip                       @  * Unroll
	MOVCS	ip, ip, lsr #0x01
	BCS	0b
	ADD	r3, r3, ip, lsl #0x01            @ Restore j, then j += k
0:	CMP	r2, r3                           @ i < j?
	BCS	3f
	ADD	ip, r0, r2, lsl #0x03            @  Swap Buf[i],Buf[j]
	ADD	lr, r0, r3, lsl #0x03
	LDMIA	ip, {r4-r5}
	LDMIA	lr, {r6-r7}
	STMIA	lr, {r4-r5}
	STMIA	ip, {r6-r7}
	SUB	ip, sl, r2, lsl #0x03            @  Swap Buf[N-1-i],Buf[N-1-j]
	SUB	lr, sl, r3, lsl #0x03
	LDMDB	ip, {r4-r5}
	LDMDB	lr, {r6-r7}
	STMDB	lr, {r4-r5}
	STMDB	ip, {r6-r7}
3:	ADD	r2, r2, #0x01                    @ i++
	CMP	r2, r1, lsr #0x01                @ i < N/2?
	BCC	1b
#endif

/**************************************/

@ Perform an initial 4-point FFT.
@ First stage is 2-point butterflies, second stage is 4-point butterflies.
.LFFT_4:
1:	LDMIA	r0, {r2-r9}                      @ {a0,b0,a1,b1} = Buf[n+{0..3}].{Re,Im}
0:	ADD	r2, r2, r4                       @ A0 = a0 + b0
	ADD	r3, r3, r5
	SUB	r4, r2, r4, lsl #0x01            @ B0 = a0 - b0 (=A0 - b0*2)
	SUB	r5, r3, r5, lsl #0x01
	ADD	r6, r6, r8                       @ A1 = a1 + b1
	ADD	r7, r7, r9
	SUB	ip, r6, r8, lsl #0x01            @ B1 = a1 - b1 (=A1 - b1*2) [NOTE: B1 in ip,lr]
	SUB	lr, r7, r9, lsl #0x01
0:	ADD	r2, r2, r6                       @ Buf[n+0] = A0 + A1
	ADD	r3, r3, r7
	SUB	r6, r2, r6, lsl #0x01            @ Buf[n+2] = A0 - A1 (=Buf[n+0] - A1*2)
	SUB	r7, r3, r7, lsl #0x01
	ADD	r4, r4, lr                       @ Buf[n+1] = B0 + B1*(0-I) = (B0.Re + B1.Im) + I*(B0.Im - B1.Re)
	SUB	r5, r5, ip
	SUB	r8, r4, lr, lsl #0x01            @ Buf[n+3] = B0 - B1*(0-I) = (B0.Re - B1.Im) + I*(B0.Im + B1.Re)
	ADD	r9, r5, ip, lsl #0x01
	STMIA	r0!, {r2-r9}
10:	CMP	r0, sl
	BCC	1b
#if 0 //! We always have N > 4, so no point to this
2:	CMP	r1, #0x04                        @ Currently have 4-point DFT. Finished?
	LDMEQFD	sp!, {r4-fp,pc}
#endif

/**************************************/

.LFFT_N:
	LDR	ip, =Fourier_FFT_TwiddleTable    @ &NextTwiddle -> ip (we always start at M=8)
	MOV	fp, #0x08                        @ M = 8 -> fp (currently have 4-point DFT)
	STR	ip, [sp, #-0x04]!

@ The first twiddle factor is always 1+0*I, and the second is
@ always equal to omega_m, so we optimize by doing the first
@ two elements separately, and then pre-step in a loop.
@ Note that the oscillator runs in the direction of E^(I*2Pi/N)
@ so we must conjugate the twiddle factors into E^(-I*2Pi/N)!
@ Registers:
@  r0: &Buf
@  r1: &Buf[M/2]
@  r2:  omega.Re
@  r3:  omega.Im
@  r4:
@  r5:
@  r6:
@  r7:
@  r8:
@  r9:
@  sl: &BufEnd
@  fp:  M | -M_Rem<<16
@  ip:
@  lr:

.LFFT_N_Restart:
	SUB	r0, r0, r1, lsl #0x03            @ Rewind Buf

.LFFT_N_Enter:
	CMP	fp, #0x20                        @ For M > 32, we only need to modify six instructions
	BHI	11f
10:	LDMIB	ip, {r3-r9,ip,lr}                @ M <= 32: Patch all oscillator instructions
	ADR	r2, .LFFT_N_OscillatorA          @          Note that incoming ip is destroyed!
	STMIA	r2, {r3-r9,ip,lr}
	ADR	r2, .LFFT_N_OscillatorB
	STMIA	r2, {r3-r9,ip,lr}
	LDR	ip, [sp, #0x00]                  @          Reload &NextTwiddle
	LDR	r2, [ip], #0x04*9+0x02*2         @          omega -> r2,r3 [.16fxp], and move to next twiddle
	B	2f
11:	LDR	r2, .LFFT_N_OscillatorA+PATCH_OFFS_A
	LDR	r3, .LFFT_N_OscillatorA+PATCH_OFFS_B
	LDR	r4, .LFFT_N_OscillatorA+PATCH_OFFS_C
	ADD	r2, r2, #0x01<<7                 @ M > 32: Increase shift count for ADD/SUB instructions
	ADD	r3, r3, #0x01<<7                 @         Note that incoming ip is NOT destroyed!
	ADD	r4, r4, #0x01<<7
	STR	r2, .LFFT_N_OscillatorA+PATCH_OFFS_A
	STR	r2, .LFFT_N_OscillatorB+PATCH_OFFS_A
	STR	r3, .LFFT_N_OscillatorA+PATCH_OFFS_B
	STR	r3, .LFFT_N_OscillatorB+PATCH_OFFS_B
	STR	r4, .LFFT_N_OscillatorA+PATCH_OFFS_C
	STR	r4, .LFFT_N_OscillatorB+PATCH_OFFS_C
	LDR	r2, [ip], #0x04                  @         omega -> r2,r3 [.16fxp], and move to next twiddle
2:	STR	ip, [sp, #0x00]                  @ Store updated &NextTwiddle
	MOV	r3, r2, lsr #0x10
	BIC	r2, r2, r3, lsl #0x10
	STMFD	sp!, {r1,r2-r3}                  @ Push {N,omega}

.LFFT_N_FirstTwoElements:
	ADD	r1, r0, fp, lsl #0x03-1          @ &Buf[M/2] -> r1
1:	LDMIA	r1, {r8,r9,ip,lr}                @ b0 = Buf[n+M/2] -> r8,r9, b1 = Buf[n+1+M/2] -> ip,lr
	CPLXMUL	ip,lr, r2,r3, ip,lr, r4,r5,r6,r7 @ t1 = omega * b1 -> ip,lr
	LDMIA	r0, {r4,r5,r6,r7}                @ a0 = Buf[n] -> r4,r5, a1 = Buf[n+1] -> r6,r7
	ADD	r4, r4, r8                       @ Buf[n]     = a0 + b0
	ADD	r5, r5, r9
	SUB	r8, r4, r8, lsl #0x01            @ Buf[n+M/2] = a0 - b0
	SUB	r9, r5, r9, lsl #0x01
#if ULC_USE_64BIT_MATH
	ADD	r6, r6, ip                       @ Buf[n+1]     = a1 + t
	ADD	r7, r7, lr
	SUB	ip, r6, ip, lsl #0x01            @ Buf[n+1+M/2] = a1 - t
	SUB	lr, r7, lr, lsl #0x01
#else
	ADD	r6, r6, ip, asr #0x0F
	ADD	r7, r7, lr, asr #0x0F
	SUB	ip, r6, ip, asr #0x0F-1
	SUB	lr, r7, lr, asr #0x0F-1
#endif
	STMIA	r0!, {r4,r5,r6,r7}
	STMIA	r1!, {r8,r9,ip,lr}

.LFFT_N_RemainingElements:
	SUB	fp, fp, fp, lsl #0x10-1          @ M | -M_Rem(=M/2-2)<<16 -> fp
	ADD	fp, fp, #0x02<<16
1:	LDMIA	r1, {r8,r9,ip,lr}                @ b0 = Buf[n+M/2] -> r8,r9, b1 = Buf[n+1+M/2] -> ip,lr
.LFFT_N_OscillatorA:
	MAKE_OSCILLATOR_SPACE
	CPLXMUL	r8,r9, r2,r3, r8,r9, r4,r5,r6,r7 @ t0 = omega * b0 -> r8,r9
.LFFT_N_OscillatorB:
	MAKE_OSCILLATOR_SPACE
	CPLXMUL	ip,lr, r2,r3, ip,lr, r4,r5,r6,r7 @ t1 = omega * b1 -> ip,lr
	LDMIA	r0, {r4,r5,r6,r7}                @ a0 = Buf[n] -> r4,r5, a1 = Buf[n+1] -> r6,r7
#if ULC_USE_64BIT_MATH
	ADD	r4, r4, r8                       @ Buf[n]       = a0 + t0
	ADD	r5, r5, r9
	ADD	r6, r6, ip                       @ Buf[n+1]     = a1 + t1
	ADD	r7, r7, lr
	SUB	r8, r4, r8, lsl #0x01            @ Buf[n+M/2]   = a0 - t0
	SUB	r9, r5, r9, lsl #0x01
	SUB	ip, r6, ip, lsl #0x01            @ Buf[n+1+M/2] = a1 - t1
	SUB	lr, r7, lr, lsl #0x01
#else
	ADD	r4, r4, r8, asr #0x0F
	ADD	r5, r5, r9, asr #0x0F
	ADD	r6, r6, ip, asr #0x0F
	ADD	r7, r7, lr, asr #0x0F
	SUB	r8, r4, r8, asr #0x0F-1
	SUB	r9, r5, r9, asr #0x0F-1
	SUB	ip, r6, ip, asr #0x0F-1
	SUB	lr, r7, lr, asr #0x0F-1
#endif
	STMIA	r0!, {r4,r5,r6,r7}
	STMIA	r1!, {r8,r9,ip,lr}
	ADDS	fp, fp, #0x02<<16                @ M_Rem -= 2?
	BCC	1b
2:	ADD	r0, r0, fp, lsl #0x03-1          @ Skip to end of M block
	CMP	r0, sl                           @ Reached the end?
	LDMCCIB	sp, {r2-r3}                      @  N: Reload omega and start next M block
	BCC	.LFFT_N_FirstTwoElements

.LFFT_N_NextM:
	LDR	r1, [sp], #0x0C                  @ N -> r1, pop {N,omega}
	ADD	fp, fp, fp                       @ M *= 2
	CMP	fp, r1                           @ M <= N?
	LDRLS	ip, [sp, #0x00]                  @  Restore &NextTwiddle -> ip, and start again
	BLS	.LFFT_N_Restart
0:	LDMFD	sp!, {r3-fp,pc}

ASM_FUNC_END(Fourier_FFT_InPlace)

/**************************************/
#endif
/**************************************/
//! EOF
/**************************************/
