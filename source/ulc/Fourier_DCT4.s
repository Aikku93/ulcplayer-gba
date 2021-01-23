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
.if ULC_64BIT_MATH
	STMFD	sp!, {r2,r4-fp,lr}
.else
	STMFD	sp!, {r4-fp,lr}
.endif
	LDR	fp, =Fourier_CosSin - 0x04*(16/2)
0:	ADD	r8, r0, r2, lsl #0x02   @ SrcHi = Tmp+N
	ADD	r9, r1, r2, lsl #0x02-1 @ DstHi = Tmp+N/2
.if !ULC_64BIT_MATH
	MOV	sl, r2
.endif
	ADD	fp, fp, r2, lsl #0x01
1:
.rept 2
	LDMIA	fp!, {ip,lr}          @ cs -> ip,lr
	LDMIA	r0!, {r2-r3}          @ a = *SrcLo++
	LDMDB	r8!, {r4-r5}          @ b = *--SrcHi
.if ULC_64BIT_MATH @ 56c
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
.else @ 42c
	MOV	r7, ip, lsr #0x10     @ s -> r7
	BIC	ip, ip, r7, lsl #0x10 @ c -> ip
	MUL	r6, ip, r2            @ *DstLo++ =  c*a + s*b -> r6
	MUL	r2, r7, r2            @ *DstHi++ =  s*a - c*b -> r2
	MLA	r6, r7, r5, r6
	MUL	r7, ip, r5
	MOV	ip, lr, lsr #0x10     @ s -> ip
	BIC	lr, lr, ip, lsl #0x10 @ c -> lr
	SUB	r2, r2, r7
	MUL	r7, lr, r3            @ *DstLo++ =  c*a + s*b -> r7
	MUL	r3, ip, r3            @ *DstHi++ = -s*a + c*b -> r3
	MLA	r7, ip, r4, r7
	MUL	ip, lr, r4
	MOV	r2, r2, asr #0x0F
	MOV	r6, r6, asr #0x0F
	MOV	r7, r7, asr #0x0F
	RSB	r3, r3, ip
	MOV	r3, r3, asr #0x0F
	STMIA	r1!, {r6-r7}
	STMIA	r9!, {r2-r3}
.endif
.endr
2:	CMP	r0, r8
	BNE	1b
.if ULC_64BIT_MATH
	LDR	sl, [sp], #0x04
.endif
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
	LDMDB	r9!, {r4-r7}
	ADD	r3, r3, r4
	ADD	r2, r2, r5
	ADD	r1, r1, r6
	ADD	r0, r0, r7
	SUB	r7, r0, r7, lsl #0x01
	SUB	r6, r1, r6, lsl #0x01
	SUB	r5, r2, r5, lsl #0x01
	SUB	r4, r3, r4, lsl #0x01
	STMIA	ip!, {r0,r7}
	STMIA	ip!, {r1,r6}
	STMIA	ip!, {r2,r5}
	STMIA	ip!, {r3,r4}
	SUBS	sl, sl, #0x08
	BNE	1b
2:	LDMIA	r8!, {r0-r2}
	LDMDB	r9!, {r4-r7}
	ADD	r2, r2, r5
	ADD	r1, r1, r6
	ADD	r0, r0, r7
	SUB	r7, r0, r7, lsl #0x01
	SUB	r6, r1, r6, lsl #0x01
	SUB	r3, r2, r5, lsl #0x01
	STMIA	ip!, {r0,r7}
	STMIA	ip!, {r1,r6}
	STMIA	ip!, {r2-r4}
3:	LDMFD	sp!, {r4-fp,pc}

/**************************************/

@ r0: &Buf

@ Rotations performed via shear matrices.
@ 32-bit coefficients:
@  s1_5:    C9h                    *2^-11
@  t1_6:    C9h                    *2^-12
@  s3_5:    (2^10+1)(2^5+1)(1+2^-3)*2^-17
@  t3_6:    13h                    *2^-7
@  s5_5:    (2^ 9-1)(2^4-1)(1+2^-7)*2^-14
@  t5_6:    01h                    *2^-2
@  s7_5:    (2^11-1)(2^2+1)(1+2^-6)*2^-14
@  t7_6:    B7h                    *2^-9
@  s1_3:    (2^12-1)(2^3-1)(1-2^-3)*2^-16
@  t1_4:    33h                    *2^-8
@  sqrt1_2: (2^ 8+1)(2^4-1)(1-2^-2)*2^-12
@ 64-bit coefficients:
@  s1_5:    (1+2^-2)(1+2^-2)(1+2^ -8)*2^-4
@  t1_6:    (1-2^-2)(1+2^-5)(1+2^ -6)*2^-4
@  s3_5:    (1+2^-3)(1+2^-5)(1+2^-10)*2^-2
@  t3_6:    (1+2^-3)(1+2^-3)(1-2^ -4)*2^-3
@  s5_5:    (1-2^-4)(1+2^-7)(1-2^ -9)*2^-1
@  t5_6:                    (1+2^ -9)*2^-2
@  s7_5:    (1+2^-2)(1+2^-6)(1-2^-11)*2^-1
@  t7_6:    (1-2^-2)(1-2^-5)(1-2^ -6)*2^-1
@  s1_3:    (1-2^-3)(1-2^-3)(1-2^-12)*2^-1
@  t1_4:    (1-2^-2)(1+2^-4)(1-2^ -9)*2^-2
@  sqrt1_2: (1-2^-2)(1-2^-4)(1+2^ -8)
@ 64bit mode uses high-precision coefficients,
@ so we must be careful to never scale >= 2.0.
@ Most coefficients have been factorized into
@ shift+add form as these worked out to be
@ more accurate (for the same execution time)
@ than the multiply+shift variations.
@ The factorizations were found using a
@ bruteforce method to minimize the error.

.LDCT4_8:
	STMFD	sp!, {r4-fp,lr}
	LDMIA	r0, {r1-r8}
.if ULC_64BIT_MATH
0:	SUB	r9, r8, r8, asr #0x02 @ t = x[0] + t1_6*x[7]
	ADD	r9, r9, r9, asr #0x05
	ADD	r9, r9, r9, asr #0x06
	ADD	r9, r1, r9, asr #0x04
	ADD	r1, r9, r9, asr #0x02 @ ay = t*s1_5 - x[7] -> r1
	ADD	r1, r1, r1, asr #0x02
	ADD	r1, r1, r1, asr #0x08
	RSB	r1, r8, r1, asr #0x04
	SUB	ip, r1, r1, asr #0x02 @ ax = t - ay*t1_6 -> r9
	ADD	ip, ip, ip, asr #0x05
	ADD	ip, ip, ip, asr #0x06
	SUB	r9, r9, ip, asr #0x04
0:	ADD	r8, r7, r7, asr #0x03 @ t = x[1] + t3_6*x[6]
	ADD	r8, r8, r8, asr #0x03
	SUB	r8, r8, r8, asr #0x04
	ADD	r8, r2, r8, asr #0x03
	ADD	r2, r8, r8, asr #0x03 @ by = x[6] - t*s3_5 -> r2
	ADD	r2, r2, r2, asr #0x05
	ADD	r2, r2, r2, asr #0x0A
	SUB	r2, r7, r2, asr #0x02
	ADD	r7, r2, r2, asr #0x03 @ bx = t + by*t3_6 -> r8
	ADD	r7, r7, r7, asr #0x03
	SUB	r7, r7, r7, asr #0x04
	ADD	r8, r8, r7, asr #0x03
0:	ADD	r7, r6, r6, asr #0x09 @ t = x[2] + t5_6*x[5]
	ADD	r7, r3, r7, asr #0x02
	SUB	r3, r7, r7, asr #0x04 @ cy = t*s5_5 - x[5] -> r3
	ADD	r3, r3, r3, asr #0x07
	SUB	r3, r3, r3, asr #0x09
	RSB	r3, r6, r3, asr #0x01
	ADD	r6, r3, r3, asr #0x09 @ cx = t - cy*t5_6 -> r7
	SUB	r7, r7, r6, asr #0x02
0:	SUB	r6, r5, r5, asr #0x02 @ t = x[3] + t7_6*x[4]
	SUB	r6, r6, r6, asr #0x05
	SUB	r6, r6, r6, asr #0x06
	ADD	r6, r4, r6, asr #0x01
	ADD	r4, r6, r6, asr #0x02 @ dy = x[4] - t*s7_5 -> r4
	ADD	r4, r4, r4, asr #0x06
	SUB	r4, r4, r4, asr #0x0B
	SUB	r4, r5, r4, asr #0x01
	SUB	r5, r4, r4, asr #0x02 @ dx = t + dy*t7_6 -> r6
	SUB	r5, r5, r5, asr #0x05
	SUB	r5, r5, r5, asr #0x06
	ADD	r6, r6, r5, asr #0x01
1:	ADD	r9, r9, r6            @ saxdx = ax+dx -> r9
	SUB	r6, r9, r6, lsl #0x01 @ daxdx = ax-dx -> r6
	ADD	r8, r8, r7            @ sbxcx = bx+cx -> r8
	SUB	r7, r8, r7, lsl #0x01 @ dbxcx = bx-cx -> r7
	ADD	r4, r4, r1            @ sdyay = dy+ay -> r4
	SUB	r1, r4, r1, lsl #0x01 @ ddyay = dy-ay -> r1
	ADD	r3, r3, r2            @ scyby = cy+by -> r3
	SUB	r2, r3, r2, lsl #0x01 @ dcyby = cy-by -> r2
2:	SUB	sl, r7, r7, asr #0x02 @ t = daxdx + t1_4*dbxcx
	ADD	sl, sl, sl, asr #0x04
	SUB	sl, sl, sl, asr #0x09
	ADD	sl, r6, sl, asr #0x02
	SUB	fp, sl, sl, asr #0x03 @ ty = t*s1_3 - dbxcx -> fp
	SUB	fp, fp, fp, asr #0x03
	SUB	fp, fp, fp, asr #0x0C
	RSB	fp, r7, fp, asr #0x01
	SUB	r7, fp, fp, asr #0x02 @ tx = t - ty*t1_4 -> sl
	ADD	r7, r7, r7, asr #0x04
	SUB	r7, r7, r7, asr #0x09
	SUB	sl, sl, r7, asr #0x02
	SUB	r6, r2, r2, asr #0x02 @ t = ddyay + t1_4*dcyby
	ADD	r6, r6, r6, asr #0x04
	SUB	r6, r6, r6, asr #0x09
	ADD	r6, r1, r6, asr #0x02
	SUB	r7, r6, r6, asr #0x03 @ vy = t*s1_3 - dcyby -> r7
	SUB	r7, r7, r7, asr #0x03
	SUB	r7, r7, r7, asr #0x0C
	RSB	r7, r2, r7, asr #0x01
	SUB	r2, r7, r7, asr #0x02 @ vx = t - vy*t1_4 -> r6
	ADD	r2, r2, r2, asr #0x04
	SUB	r2, r2, r2, asr #0x09
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
	ADD	r6, r6, r6, asr #0x08
	SUB	r9, r8, r8, asr #0x02
	SUB	r9, r9, r9, asr #0x04
	ADD	r9, r9, r9, asr #0x08
.else
0:	MOV	ip, #0xC9             @ s1_5[.11] -> ip (this is also t1_6[.12] by coincidence)
	MUL	r9, r8, ip            @ t = x[0] + t1_6*x[7]
	ADD	r9, r1, r9, asr #0x0C
	MUL	r1, r9, ip            @ ay = t*s1_5 - x[7] -> r1
	RSB	r1, r8, r1, asr #0x0B
	MUL	ip, r1, ip            @ ax = t - ay*t1_6 -> r9
	SUB	r9, r9, ip, asr #0x0C
0:	ADD	r8, r7, r7, lsl #0x01 @ t = x[1] + t3_6*x[6]
	ADD	r8, r8, r7, lsl #0x04
	ADD	r8, r2, r8, asr #0x07
	ADD	r2, r8, r8, lsl #0x0A @ by = x[6] - t*s3_5 -> r2
	ADD	r2, r2, r2, lsl #0x05
	ADD	r2, r2, r2, asr #0x03
	SUB	r2, r7, r2, asr #0x11
	ADD	r7, r2, r2, lsl #0x01 @ bx = t + by*t3_6 -> r8
	ADD	r7, r7, r2, lsl #0x04
	ADD	r8, r8, r7, asr #0x07
0:	ADD	r7, r3, r6, asr #0x02 @ t = x[2] + t5_6*x[5]
	RSB	r3, r7, r7, lsl #0x09 @ cy = t*s5_5 - x[5] -> r3
	RSB	r3, r3, r3, lsl #0x04
	ADD	r3, r3, r3, asr #0x07
	RSB	r3, r6, r3, asr #0x0E
	SUB	r7, r7, r3, asr #0x02 @ cx = t - cy*t5_6 -> r7
0:	MOV	ip, #0xB7
	MUL	r6, r5, ip            @ t = x[3] + t7_6*x[4]
	ADD	r6, r4, r6, asr #0x09
	RSB	r4, r6, r6, lsl #0x0B @ dy = x[4] - t*s7_5 -> r4
	ADD	r4, r4, r4, lsl #0x02
	ADD	r4, r4, r4, asr #0x06
	SUB	r4, r5, r4, asr #0x0E
	MUL	ip, r4, ip            @ dx = t + dy*t7_6 -> r6
	ADD	r6, r6, ip, asr #0x09
1:	ADD	r9, r9, r6            @ saxdx = ax+dx -> r9
	SUB	r6, r9, r6, lsl #0x01 @ daxdx = ax-dx -> r6
	ADD	r8, r8, r7            @ sbxcx = bx+cx -> r8
	SUB	r7, r8, r7, lsl #0x01 @ dbxcx = bx-cx -> r7
	ADD	r4, r4, r1            @ sdyay = dy+ay -> r4
	SUB	r1, r4, r1, lsl #0x01 @ ddyay = dy-ay -> r1
	ADD	r3, r3, r2            @ scyby = cy+by -> r3
	SUB	r2, r3, r2, lsl #0x01 @ dcyby = cy-by -> r2
2:	ADD	sl, r7, r7, lsl #0x01 @ t = daxdx + t1_4*dbxcx
	ADD	sl, sl, sl, lsl #0x04
	ADD	sl, r6, sl, asr #0x08
	RSB	fp, sl, sl, lsl #0x0C @ ty = t*s1_3 - dbxcx -> fp
	RSB	fp, fp, fp, lsl #0x03
	SUB	fp, fp, fp, asr #0x03
	RSB	fp, r7, fp, asr #0x10
	ADD	r6, fp, fp, lsl #0x01 @ tx = t - ty*t1_4 -> sl
	ADD	r6, r6, r6, lsl #0x04
	SUB	sl, sl, r6, asr #0x08
	ADD	r6, r2, r2, lsl #0x01 @ t = ddyay + t1_4*dcyby
	ADD	r6, r6, r6, lsl #0x04
	ADD	r6, r1, r6, asr #0x08
	RSB	r7, r6, r6, lsl #0x0C @ vy = t*s1_3 - dcyby -> r7
	RSB	r7, r7, r7, lsl #0x03
	SUB	r7, r7, r7, asr #0x03
	RSB	r7, r2, r7, asr #0x10
	ADD	r1, r7, r7, lsl #0x01 @ vx = t - vy*t1_4 -> r6
	ADD	r1, r1, r1, lsl #0x04
	SUB	r6, r6, r1, asr #0x08
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
	ADD	r9, r8, r8, lsl #0x08
	RSB	r9, r9, r9, lsl #0x04
	SUB	r9, r9, r9, asr #0x02
	MOV	r9, r9, asr #0x0C
	ADD	r6, r5, r5, lsl #0x08
	RSB	r6, r6, r6, lsl #0x04
	SUB	r6, r6, r6, asr #0x02
	MOV	r6, r6, asr #0x0C
.endif
	STMIA	r0, {r1,r2,r3,r6,r9,sl,ip,lr}
2:	LDMFD	sp!, {r4-fp,pc}

/**************************************/
.size   Fourier_DCT4, .-Fourier_DCT4
.global Fourier_DCT4
/**************************************/
/* EOF                                */
/**************************************/
