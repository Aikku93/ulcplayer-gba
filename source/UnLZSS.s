/**************************************/

@ r0: &Dst
@ r1: &Src

.section .iwram, "ax", %progbits
.balign 4
.arm

UnLZSS:
	STMFD	sp!, {r4-r6,lr}

.LReadHeader:
	LDRB	r2, [r1], #0x01 @ Size -> r2
	LDRB	r3, [r1], #0x01
	ORR	r2, r2, r3, lsl #0x08
	LDRB	r3, [r1], #0x01
	ORR	r2, r2, r3, lsl #0x10
	LDRB	r3, [r1], #0x01
	ORR	r2, r2, r3, lsl #0x18
	ADD	r2, r2, r0 @ End=Dst+Size -> r2

@ r0: &Dst
@ r1: &Src
@ r2: &End (relative to Dst)
@ r3:  LZCnt

.LReadLoop_Main:
1:	LDRB	r3, [r1], #0x01     @ LZCnt -> r3
	MOVS	r3, r3, lsl #0x18+1 @ Shift up [+1 for C=x detection]
	BL	2f                  @ Bit7 [no SHL - done above]
	BL	1f                  @ Bit6
	BL	1f                  @ Bit5
	BL	1f                  @ Bit4
	BL	1f                  @ Bit3
	BL	1f                  @ Bit2
	BL	1f                  @ Bit1
	ADR	lr, 1b              @ Bit0
1:	MOVS	r3, r3, lsl #0x01   @ Byte read?
2:	BCC	.LReadLoop_Byte
	@BCS	.LReadLoop_Block

.LReadLoop_Block:
#if 0
	LDRB	ip, [r1], #0x01   @ MSB|Cnt<<4 -> ip
	LDRB	r5, [r1], #0x01   @ LSB -> r5
	ADDS	r4, ip, #(3-1)<<4 @ (Len+3 - 1)<<4 -> r4 [-1 for BCS loop] [C=0]
	AND	ip, ip, #0x0F     @ Src = (Dst - (LSB|MSB) - 1) -> r5
	ORR	r5, r5, ip, lsl #0x08
	RSC	r5, r5, r0
1:	LDRB	ip, [r5], #0x01 @ *Dst++ = *Src++
	SUBS	r4, r4, #0x01<<4
	STRB	ip, [r0], #0x01
	BCS	1b
	B	.LReadLoop_CheckEnd
#else
	LDRB	ip, [r1], #0x01   @ MSB|Cnt<<4 -> ip
	LDRB	r5, [r1], #0x01   @ LSB -> r5
	ADDS	r4, ip, #(3-1)<<4 @ (Len+3 - 1)<<4 -> r4 [-1 for BCS loop] [C=0]
	AND	ip, ip, #0x0F     @ Src = (Dst - (LSB|MSB) - 1) -> r5
	ORRS	r5, r5, ip, lsl #0x08
	BEQ	.LReadLoop_Block_ReptLast
	RSC	r5, r5, r0
	ORRS	r6, r0, r0, lsl #0x1F
	LDRMIB	ip, [r0, #-0x01]
	BIC	r0, r6, #0x01
1:	LDRB	r6, [r5], #0x01 @ *Dst++ = *Src++
	EORS	r0, r0, #0x80000000
	MOVMI	ip, r6
	ORRPL	ip, ip, r6, lsl #0x08
	STRPLH	ip, [r0], #0x02
	SUBS	r4, r4, #0x01<<4
	BCS	1b
2:	TST	r0, #0x80000000
	BICMI	r0, r0, #0x80000000
	LDRMIB	r6, [r0, #0x01]
	ORRMI	ip, ip, r6, lsl #0x08
	STRMIH	ip, [r0], #0x01
	B	.LReadLoop_CheckEnd

.LReadLoop_Block_ReptLast:
	LDRB	r6, [r0, #-0x01]
	ORR	r6, r6, r6, lsl #0x08
	TST	r0, #0x01
	STRNEH	r6, [r0, #-0x01]
	ADDNE	r0, r0, #0x01
	SUBNE	r4, r4, #0x01<<4
	BIC	r4, r4, #0x0F
1:	STRH	r6, [r0], #0x02
	SUBS	r4, r4, #0x02<<4
	BHI	1b
2:	LDREQB	ip, [r0, #0x01]
	MOVEQ	r6, r6, lsr #0x08
	ORREQ	r6, r6, ip, lsl #0x08
	STREQH	r6, [r0], #0x01
	B	.LReadLoop_CheckEnd
#endif

.LReadLoop_Byte:
	LDRB	ip, [r1], #0x01
	EOR	r6, r0, #0x01
	LDRB	r6, [r6]
	ANDS	r5, r0, #0x01
	ORREQ	r6, ip, r6, lsl #0x08
	ORRNE	r6, r6, ip, lsl #0x08
	STRH	r6, [r0, -r5]
	ADD	r0, r0, #0x01
	@B	.LReadLoop_CheckEnd

.LReadLoop_CheckEnd:
	CMP	r0, r2 @ End? [r0=0 on finished]
	MOVNE	pc, lr @  N: Continue
	@BEQ	.LExit @  Y: Exit

.LExit:
	LDMFD	sp!, {r4-r6,lr}
	BX	lr

.size   UnLZSS, .-UnLZSS
.global UnLZSS

/**************************************/
//! EOF
/**************************************/
