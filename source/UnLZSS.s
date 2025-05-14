/************************************************/

//! This is a "special" LZSS variant that operates
//! on 16bit data to work with VRAM memory access.

/************************************************/

@ r0: &Dst (must be 2-byte aligned)
@ r1: &Src (must be 4-byte aligned)

.section .iwram, "ax", %progbits
.balign 4
.arm

UnLZSS16:
	LDR	r2, [r1], #0x04       @ Size -> r2
	@B	UnLZSS16_FixedSize

.size   UnLZSS16, .-UnLZSS16
.global UnLZSS16

/************************************************/

@ r0: &Dst (must be 2-byte aligned)
@ r1: &Src (must be 2-byte aligned)
@ r2:  Size

.section .iwram, "ax", %progbits
.balign 4
.arm

UnLZSS16_FixedSize:
	STMFD	sp!, {r4-r5}
	ADD	r2, r0, r2, lsl #0x01 @ End = Dst+Size -> r2

@ r0: &Dst
@ r1: &Src
@ r2: &End (relative to Dst)
@ r3:  LZData

.LReadLoop_Reload:
	LDRH	r3, [r1], #0x02
	ORR	r3, r3, #0x01<<16
.LReadLoop_Main:
	MOVS	r3, r3, lsr #0x01     @ C=DictMatch?
	BEQ	.LReadLoop_Reload
.LReload_Return:
	BCS	.LReadLoop_Block
	@BCC	.LReadLoop_Single

.LReadLoop_Single:
	LDRH	ip, [r1], #0x02
	STRH	ip, [r0], #0x02
	CMP	r0, r2                @ End?
	BCC	.LReadLoop_Main       @  N: Continue
0:	B	.LExit

.LReadLoop_Block:
	LDRH	r5, [r1], #0x02       @ Offs|Len<<12 -> r5
	BIC	r4, r5, #0xF000       @ Offs -> r4
	SUB	r4, r0, r4, lsl #0x01 @ Src = (Dst - Offs - 1) -> r4
	LDRH	ip, [r4, #-0x02]!     @ Run the first iteration separately, so we can
	STRH	ip, [r0], #0x02       @ avoid setting up the pointer and counter
1:	LDRH	ip, [r4, #0x02]!      @ *Dst++ = *++Src
	SUBS	r5, r5, #0x01<<12
	STRH	ip, [r0], #0x02
	BCS	1b
2:	CMP	r0, r2                @ End?
	BCC	.LReadLoop_Main       @  N: Continue
0:	@B	.LExit

.LExit:
	LDMFD	sp!, {r4-r5}
	BX	lr

.size   UnLZSS16_FixedSize, .-UnLZSS16_FixedSize
.global UnLZSS16_FixedSize

/************************************************/
//! EOF
/************************************************/
