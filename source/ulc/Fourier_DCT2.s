/**************************************/
.include "source/ulc/ulc_Specs.inc"
/**************************************/
.section .iwram, "ax", %progbits
.balign 4
/**************************************/
.equ DCT2_LESS_STACK_USE, 0
/**************************************/

@ r0: &Buf
@ r1: &Tmp
@ r2:  N
@ NOTE: Must return to ARM code

.arm
Fourier_DCT2:
	CMP	r2, #0x08
	BEQ	.LDCT2_8

.LButterflies:
	STMFD	sp!, {r4-sl,lr}
0:	SUB	sl, r2, r2, lsl #0x10
	ADD	r9, r0, r2, lsl #0x02   @ SrcHi = Buf+N
	ADD	r8, r1, r2, lsl #0x02-1 @ DstHi = Tmp+N/2
1:
.rept 2
	LDMIA	r0!, {r4-r7}
	LDMDB	r9!, {r2,r3,ip,lr}
	ADD	r7, r7, r2
	ADD	r6, r6, r3
	ADD	r5, r5, ip
	ADD	r4, r4, lr
	STMIA	r1!, {r4-r7}
	SUB	r4, r4, lr, lsl #0x01
	SUB	r5, r5, ip, lsl #0x01
	SUB	r6, r6, r3, lsl #0x01
	SUB	r7, r7, r2, lsl #0x01
	STMIA	r8!, {r4-r7}
.endr
2:	ADDS	sl, sl, #0x10<<16
	BCC	1b
.if DCT2_LESS_STACK_USE
0:	LDMFD	sp!, {r4-r7}
.endif

@ r8: Tmp+N
@ r9: Buf+N/2
@ sl: N

.LRecurse:
	SUB	r0, r8, sl, lsl #0x02   @ Buf=Tmp
	SUB	r1, r9, sl, lsl #0x02-1 @ Tmp=Buf
	MOV	r2, sl, lsr #0x01       @ N=N/2
	BL	Fourier_DCT2
	SUB	r0, r8, sl, lsl #0x02-1 @ Buf=Tmp+N/2
	MOV	r1, r9                  @ Tmp=Buf+N/2
	MOV	r2, sl, lsr #0x01       @ N=N/2
	BL	Fourier_DCT4

.LMerge:
.if DCT2_LESS_STACK_USE
	STMFD	sp!, {r4-r7}
.endif
0:	SUB	r0, r9, sl, lsl #0x02-1 @ Dst=Buf
	SUB	r1, r8, sl, lsl #0x02   @ SrcLo=Tmp
	SUB	r2, r8, sl, lsl #0x02-1 @ SrcHi=Tmp+N/2
1:	LDMIA	r1!, {r3,r5,r7,r9}
	LDMIA	r2!, {r4,r6,r8,lr}
	STMIA	r0!, {r3-r9,lr}
	LDMIA	r1!, {r3,r5,r7,r9}
	LDMIA	r2!, {r4,r6,r8,lr}
	STMIA	r0!, {r3-r9,lr}
	SUBS	sl, sl, #0x10
	BNE	1b
2:	LDMFD	sp!, {r4-sl,pc}

/**************************************/

@ r0: &Buf

@ Rotations performed via shear matrices.
@  s1_4:    (1+2^-5)(1+2^-7)(1-2^-2)*2^-2
@  t1_5:    (1+2^-2)(1+2^-2)(1+2^-7)*2^-4
@  s3_4:    (1+2^-4)(1+2^-4)(1-2^-6)*2^-1
@  t3_5:    (1+2^-3)(1+2^-4)(1+2^-6)*2^-2
@  s6_4:    (1-2^-6)(1-2^-5)(1-2^-5)
@  t6_5:    (1+2^-2)(1+2^-4)(1+2^-7)*2^-1
@  sqrt1_2: (1-2^-2)(1-2^-4)(1+2^-7)
@ The factorizations were found using a joint
@ bruteforce method to minimize this metric:
@  CosApprox = 2 / (1 + TanApprox^2) - 1
@  NormError = (Sqrt[SinApprox^2 + CosApprox^2] - 1)^2
@  ((SinApprox-Sin)^2 + (CosApprox-Cos)^2) * (1 + NormError)

.LDCT2_8:
	STMFD	sp!, {r4-fp,lr}
	LDMIA	r0, {r1-r8}
0:	ADD	r4, r4, r5            @ s34 -> r4
	ADD	r3, r3, r6            @ s25 -> r3
	ADD	r2, r2, r7            @ s16 -> r2
	ADD	r1, r1, r8            @ s07 -> r1
	SUB	r8, r1, r8, lsl #0x01 @ d07 -> r8
	SUB	r7, r2, r7, lsl #0x01 @ d16 -> r7
	SUB	r6, r3, r6, lsl #0x01 @ d25 -> r6
	SUB	r5, r4, r5, lsl #0x01 @ d34 -> r5
0:	ADD	r1, r1, r4            @ ss07s34 -> r1
	ADD	r2, r2, r3            @ ss16s25 -> r2
	SUB	r3, r2, r3, lsl #0x01 @ ds16s25 -> r3
	SUB	r4, r1, r4, lsl #0x01 @ ds07s34 -> r4
1:	ADD	r9, r8, r8, asr #0x03 @ t = d34 + t3_5*d07
	ADD	r9, r9, r9, asr #0x04
	ADD	r9, r9, r9, asr #0x06
	ADD	r9, r5, r9, asr #0x02
	ADD	sl, r9, r9, asr #0x04 @ d34d07y = d07 - t*s3_4 -> sl
	ADD	sl, sl, sl, asr #0x04
	SUB	sl, sl, sl, asr #0x06
	SUB	sl, r8, sl, asr #0x01
	ADD	r8, sl, sl, asr #0x03 @ d34d07x = t + d34d07y*t3_5 -> r9
	ADD	r8, r8, r8, asr #0x04
	ADD	r8, r8, r8, asr #0x06
	ADD	r9, r9, r8, asr #0x02
1:	ADD	r5, r7, r7, asr #0x02 @ t = d25 + t1_5*d16
	ADD	r5, r5, r5, asr #0x02
	ADD	r5, r5, r5, asr #0x07
	ADD	r5, r6, r5, asr #0x04
	ADD	r8, r5, r5, asr #0x05 @ d25d16y = d16 - t*s1_4 -> r8
	ADD	r8, r8, r8, asr #0x07
	SUB	r8, r8, r8, asr #0x02
	SUB	r8, r7, r8, asr #0x03
	ADD	r7, r8, r8, asr #0x02 @ d25d16x = t + d25d16y*t1_5 -> r5
	ADD	r7, r7, r7, asr #0x02
	ADD	r7, r7, r7, asr #0x07
	ADD	r5, r5, r7, asr #0x04
2:	ADD	r1, r1, r2            @ a0 = ss07s34 + ss16s25 -> r1 = X0
	SUB	r7, r1, r2, lsl #0x01 @ b0 = ss07s34 - ss16s25 -> r7 = X4/sqrt1_2
	SUB	r7, r7, r7, asr #0x02 @ [X4 -> r7]
	SUB	r7, r7, r7, asr #0x04
	ADD	r7, r7, r7, asr #0x07
	ADD	sl, sl, r5            @ a1 = d34d07y + d25d16x -> sl
	SUB	r5, sl, r5, lsl #0x01 @ c1 = d34d07y - d25d16x -> r5 = X3
	ADD	r9, r9, r8            @ d1 = d34d07x + d25d16y -> r9
	SUB	r8, r9, r8, lsl #0x01 @ b1 = d34d07x - d25d16y -> r8 = X5
	ADD	r2, sl, r9            @ (a1+d1)*sqrt1_2 = X1 -> r2
	SUB	ip, sl, r9            @ (a1-d1)*sqrt1_2 = X7 -> ip
	SUB	r2, r2, r2, asr #0x02
	SUB	r2, r2, r2, asr #0x04
	ADD	r2, r2, r2, asr #0x07
	SUB	ip, ip, ip, asr #0x02
	SUB	ip, ip, ip, asr #0x04
	ADD	ip, ip, ip, asr #0x07
        SUB	r6, r4, r4, asr #0x02 @ t = ds16s25 + t6_5*ds07s34
        SUB	r6, r6, r6, asr #0x03
        ADD	r6, r6, r6, asr #0x06
        ADD	r6, r3, r6
        SUB	sl, r6, r6, asr #0x06 @ d0 = ds07s34 - t*s6_4 -> r9 = X6
        SUB	sl, sl, sl, asr #0x05
        SUB	sl, sl, sl, asr #0x05
        SUB	r9, r4, sl
	ADD	r4, r9, r9, asr #0x02 @ c0 = t + d0*t6_5      -> r4 = X2
	ADD	r4, r4, r4, asr #0x04
	ADD	r4, r4, r4, asr #0x07
	ADD	r4, r6, r4, asr #0x01
	STMIA	r0, {r1,r2,r4,r5,r7,r8,r9,ip}
2:	LDMFD	sp!, {r4-fp,pc}

/**************************************/
.size   Fourier_DCT2, .-Fourier_DCT2
.global Fourier_DCT2
/**************************************/
/* EOF                                */
/**************************************/
