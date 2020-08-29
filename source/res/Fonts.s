/**************************************/
.section .rodata
/**************************************/

.balign 4
.equ TIMEDISPLAYFONT_CELLH, 5
TimeDisplayFont:
	.word 0x00075557 @ 0
	.word 0x00072232 @ 1
	.word 0x00071747 @ 2
	.word 0x00074747 @ 3
	.word 0x00044755 @ 4
	.word 0x00074717 @ 5
	.word 0x00075717 @ 6
	.word 0x00044447 @ 7
	.word 0x00075757 @ 8
	.word 0x00074757 @ 9
	.word 0x00001010 @ :
	.word 0x00000700 @ -
.size   TimeDisplayFont, .-TimeDisplayFont
.global TimeDisplayFont

/**************************************/

.balign 4
.equ MAINFONT_CELLH, 9
MainFont:
1:	.word 0x26866433,0x43536633,0x66666666,0x63433366 @ Glyph widths (1 nybble per glyph)
	.word 0x55555558,0x56655525,0x65565555,0x54343566
	.word 0x55555553,0x55625325,0x65555455,0x66424555
	.word 0x99998888
2:	.incbin "source/res/MainFont.gfx"
.size   MainFont, .-MainFont
.global MainFont

/**************************************/
/* EOF                                */
/**************************************/
