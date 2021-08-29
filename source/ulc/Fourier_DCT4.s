/**************************************/
.include "source/ulc/ulc_Specs.inc"
/**************************************/
.section .iwram, "ax", %progbits
.balign 4
/**************************************/
.equ DCT4_LESS_STACK_USE, 0
/**************************************/

@ r0: &Buf
@ r1: &Tmp
@ r2:  N
@ NOTE: Must return to ARM code

.arm
Fourier_DCT4:
	CMP	r2, #0x08
	BEQ	.LDCT4_8

.LButterflies:
	STMFD	sp!, {r2,r4-fp,lr}
	LDR	fp, =Fourier_CosSin - 0x04*(16/2)
0:	ADD	r8, r0, r2, lsl #0x02   @ SrcHi = Tmp+N
	ADD	r9, r1, r2, lsl #0x02-1 @ DstHi = Tmp+N/2
	ADD	fp, fp, r2, lsl #0x01
1:
.rept 2
	LDMIA	fp!, {ip,lr}          @ cs -> ip,lr
	LDMIA	r0!, {r2-r3}          @ a = *SrcLo++
	LDMDB	r8!, {r4-r5}          @ b = *--SrcHi
	MOV	sl, ip, lsr #0x10     @ s -> sl
	BIC	ip, ip, sl, lsl #0x10 @ c -> ip
	SMULL	r6, r7, r2, ip        @ Lo0 = c*a + s*b -> r6,r7 [.16]
	SMLAL	r6, r7, r5, sl
	RSB	ip, ip, #0x00
	SMULL	r5, ip, r5, ip        @ Hi0 = s*a - c*b -> r5,ip [.16] <- GCC complains about this, but should be fine
	SMLAL	r5, ip, r2, sl
	MOVS	r2, r6, lsr #0x10     @ Lo0 -> r2 [.0 + Round]
	ADC	r2, r2, r7, lsl #0x10
	MOVS	r5, r5, lsr #0x10     @ Hi0 -> r5 [.0 + Round]
	ADC	r5, r5, ip, lsl #0x10
	MOV	ip, lr, lsr #0x10     @ s -> ip
	BIC	lr, lr, ip, lsl #0x10 @ c -> lr
	SMULL	r6, r7, r3, lr        @ Lo1 = c*a + s*b -> r6,r7 [.16]
	SMLAL	r6, r7, r4, ip
	RSB	r3, r3, #0x00
	SMULL	r4, lr, r4, lr        @ Hi1 = -s*a + c*b -> r4,lr [.16] <- GCC complains about this, but should be fine
	SMLAL	r4, lr, r3, ip
	MOVS	r3, r6, lsr #0x10     @ Lo1 -> r3 [.0 + Round]
	ADC	r3, r3, r7, lsl #0x10
	MOVS	r6, r4, lsr #0x10     @ Hi1 -> r6 [.0 + Round]
	ADC	r6, r6, lr, lsl #0x10
	STMIA	r1!, {r2,r3}
	STMIA	r9!, {r5,r6}
.endr
2:	CMP	r0, r8
	BNE	1b
	LDR	sl, [sp], #0x04
.if DCT4_LESS_STACK_USE
0:	LDMFD	sp!, {r4-r7}
.endif

@ r8: Buf+N/2
@ r9: Tmp+N
@ sl: N

.LRecurse:
	SUB	r0, r9, sl, lsl #0x02   @ Buf=Tmp
	SUB	r1, r8, sl, lsl #0x02-1 @ Tmp=Buf
	MOV	r2, sl, lsr #0x01       @ N=N/2
	BL	Fourier_DCT2
	SUB	r0, r9, sl, lsl #0x02-1 @ Buf=Tmp+N/2
	MOV	r1, r8                  @ Tmp=Buf+N/2
	MOV	r2, sl, lsr #0x01       @ N=N/2
	BL	Fourier_DCT2

.LMerge:
.if DCT4_LESS_STACK_USE
	STMFD	sp!, {r4-r7}
.endif
	SUB	ip, r8, sl, lsl #0x02-1 @ Dst=Buf -> ip
	SUB	r8, r9, sl, lsl #0x02   @ SrcLo=Tmp -> r8, SrcHi=Tmp+N -> r9
0:	LDR	r0, [r8], #0x04
	SUB	sl, sl, #0x08
	STR	r0, [ip], #0x04
1:	LDMIA	r8!, {r0-r3}
	LDMDB	r9!, {r4-r5,fp,lr}
	ADD	r6, r3, r4
	SUB	r7, r3, r4
	ADD	r4, r2, r5
	SUB	r5, r2, r5
	ADD	r2, r1, fp
	SUB	r3, r1, fp
	SUB	r1, r0, lr
	ADD	r0, r0, lr
	STMIA	ip!, {r0-r7}
	SUBS	sl, sl, #0x08
	BNE	1b
2:	LDMIA	r8!, {r0-r2,r6}
	LDMDB	r9!, {r5,fp,lr}
	ADD	r4, r2, r5
	SUB	r5, r2, r5
	ADD	r2, r1, fp
	SUB	r3, r1, fp
	SUB	r1, r0, lr
	ADD	r0, r0, lr
	STMIA	ip!, {r0-r6}
3:	LDMFD	sp!, {r4-fp,pc}

/**************************************/

@ r0: &Buf

@ Rotations performed via shear matrices.
@  s1_5:    (1+2^-2)(1+2^-2)(1+2^-8)*2^-4
@  t1_6:    (1+2^-5)(1+2^-6)(1-2^-2)*2^-4
@  s3_5:    (1+2^-3)(1+2^-6)(1+2^-6)*2^-2
@  t3_6:    (1+2^-3)(1+2^-3)(1-2^-4)*2^-3
@  s5_5:    (1-2^-4)(1+2^-7)(1-2^-9)*2^-1
@  t5_6:                    (1+2^-9)*2^-2
@  s7_5:    (1+2^-2)(1+2^-5)(1-2^-6)*2^-1
@  t7_6:    (1-2^-6)(1-2^-5)(1-2^-2)*2^-1
@  s1_3:    (1-2^-3)(1-2^-3)(1-2^-1)
@  t1_4:    (1-2^-5)(1-2^-4)(1-2^-3)*2^-2
@  sqrt1_2: (1-2^-2)(1-2^-4)(1+2^-7)
@ The factorizations were found using a joint
@ bruteforce method to minimize this metric:
@  CosApprox = 2 / (1 + TanApprox^2) - 1
@  NormError = (Sqrt[SinApprox^2 + CosApprox^2] - 1)^2
@  ((SinApprox-Sin)^2 + (CosApprox-Cos)^2) * (1 + NormError)
@ s5_5 and t5_6 were an exception, due to t5_6
@ being very accurate after just one operation.

.LDCT4_8:
	STMFD	sp!, {r4-fp,lr}
	LDMIA	r0, {r1-r8}
0:	SUB	ip, r5, r5, asr #0x06 @ t = x[3] + t7_6*x[4]
	SUB	ip, ip, ip, asr #0x05
	SUB	ip, ip, ip, asr #0x02
	ADD	ip, r4, ip, asr #0x01
	ADD	r4, ip, ip, asr #0x02 @ dy = x[4] - t*s7_5 -> r4
	ADD	r4, r4, r4, asr #0x05
	SUB	r4, r4, r4, asr #0x06
	SUB	r4, r5, r4, asr #0x01
	SUB	r5, r4, r4, asr #0x06 @ dx = t + dy*t7_6 -> r5
	SUB	r5, r5, r5, asr #0x05
	SUB	r5, r5, r5, asr #0x02
	ADD	r5, ip, r5, asr #0x01
0:	ADD	ip, r6, r6, asr #0x09 @ t = x[2] + t5_6*x[5]
	ADD	ip, r3, ip, asr #0x02
	SUB	r3, ip, ip, asr #0x04 @ cy = t*s5_5 - x[5] -> r3
	ADD	r3, r3, r3, asr #0x07
	SUB	r3, r3, r3, asr #0x09
	RSB	r3, r6, r3, asr #0x01
	ADD	r6, r3, r3, asr #0x09 @ cx = t - cy*t5_6 -> r6
	SUB	r6, ip, r6, asr #0x02
0:	ADD	ip, r7, r7, asr #0x03 @ t = x[1] + t3_6*x[6]
	ADD	ip, ip, ip, asr #0x03
	SUB	ip, ip, ip, asr #0x04
	ADD	ip, r2, ip, asr #0x03
	ADD	r2, ip, ip, asr #0x03 @ by = x[6] - t*s3_5 -> r2
	ADD	r2, r2, r2, asr #0x06
	ADD	r2, r2, r2, asr #0x06
	SUB	r2, r7, r2, asr #0x02
	ADD	r7, r2, r2, asr #0x03 @ bx = t + by*t3_6 -> r7
	ADD	r7, r7, r7, asr #0x03
	SUB	r7, r7, r7, asr #0x04
	ADD	r7, ip, r7, asr #0x03
0:	ADD	ip, r8, r8, asr #0x05 @ t = x[0] + t1_6*x[7]
	ADD	ip, ip, ip, asr #0x06
	SUB	ip, ip, ip, asr #0x02
	ADD	ip, r1, ip, asr #0x04
	ADD	r1, ip, ip, asr #0x02 @ ay = t*s1_5 - x[7] -> r1
	ADD	r1, r1, r1, asr #0x02
	ADD	r1, r1, r1, asr #0x08
	RSB	r1, r8, r1, asr #0x04
	ADD	r8, r1, r1, asr #0x05 @ ax = t - ay*t1_6 -> r8
	ADD	r8, r8, r8, asr #0x06
	SUB	r8, r8, r8, asr #0x02
	SUB	r8, ip, r8, asr #0x04
1:	ADD	r9, r8, r5            @ saxdx = ax+dx -> r9
	ADD	r8, r7, r6            @ sbxcx = bx+cx -> r8
	SUB	r7, r7, r6            @ dbxcx = bx-cx -> r7
	SUB	r6, r9, r5, lsl #0x01 @ daxdx = ax-dx -> r6
	ADD	r4, r4, r1            @ sdyay = dy+ay -> r4
	SUB	r1, r4, r1, lsl #0x01 @ ddyay = dy-ay -> r1
	ADD	r3, r3, r2            @ scyby = cy+by -> r3
	SUB	r2, r3, r2, lsl #0x01 @ dcyby = cy-by -> r2
2:	SUB	sl, r7, r7, asr #0x05 @ t = daxdx + t1_4*dbxcx
	SUB	sl, sl, sl, asr #0x04
	SUB	sl, sl, sl, asr #0x03
	ADD	sl, r6, sl, asr #0x02
	SUB	fp, sl, sl, asr #0x03 @ ty = t*s1_3 - dbxcx -> fp
	SUB	fp, fp, fp, asr #0x03
	SUB	fp, fp, fp, asr #0x01
	RSB	fp, r7, fp
	SUB	r7, fp, fp, asr #0x05 @ tx = t - ty*t1_4 -> sl
	SUB	r7, r7, r7, asr #0x04
	SUB	r7, r7, r7, asr #0x03
	SUB	sl, sl, r7, asr #0x02
	SUB	r6, r2, r2, asr #0x05 @ t = ddyay + t1_4*dcyby
	SUB	r6, r6, r6, asr #0x04
	SUB	r6, r6, r6, asr #0x03
	ADD	r6, r1, r6, asr #0x02
	SUB	r7, r6, r6, asr #0x03 @ vy = t*s1_3 - dcyby -> r7
	SUB	r7, r7, r7, asr #0x03
	SUB	r7, r7, r7, asr #0x01
	RSB	r7, r2, r7
	SUB	r2, r7, r7, asr #0x05 @ vx = t - vy*t1_4 -> r6
	SUB	r2, r2, r2, asr #0x04
	SUB	r2, r2, r2, asr #0x03
	SUB	r6, r6, r2, asr #0x02
	ADD	r1, r9, r8            @ sx = saxdx + sbxcx -> r1 = X0
	ADD	lr, r4, r3            @ ux = sdyay + scyby -> lr = X7
	SUB	r4, r4, r3            @ uy = sdyay - scyby -> r4
	SUB	r9, r9, r8            @ sy = saxdx - sbxcx -> r9
3:	ADD	r3, sl, r7            @ X2 = tx+vy -> r3
	SUB	r2, r3, r7, lsl #0x01 @ X1 = tx-vy -> r2
	ADD	r5, r9, r4            @ X3 = (sy+uy)*sqrt1_2 -> r5 -> r6
	SUB	r8, r9, r4            @ X4 = (sy-uy)*sqrt1_2 -> r8 -> r9
	ADD	ip, fp, r6            @ X6 = ty+vx -> ip
	SUB	sl, ip, r6, lsl #0x01 @ X5 = ty-vx -> sl
	SUB	r6, r5, r5, asr #0x02
	SUB	r6, r6, r6, asr #0x04
	ADD	r6, r6, r6, asr #0x07
	SUB	r9, r8, r8, asr #0x02
	SUB	r9, r9, r9, asr #0x04
	ADD	r9, r9, r9, asr #0x07
	STMIA	r0, {r1,r2,r3,r6,r9,sl,ip,lr}
2:	LDMFD	sp!, {r4-fp,pc}

/**************************************/
.size   Fourier_DCT4, .-Fourier_DCT4
.global Fourier_DCT4
/**************************************/
/* EOF                                */
/**************************************/
