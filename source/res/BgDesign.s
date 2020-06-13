/**************************************/

.section .rodata
.balign 4

BgDesign_Gfx: @ 172 (design) + 97 (glyph) tiles
	.incbin "source/res/BgDesign.img.lz.bin"
.size   BgDesign_Gfx, .-BgDesign_Gfx
.global BgDesign_Gfx

/**************************************/

BgDesign_Map:
	.incbin "source/res/BgDesign.map.lz.bin"
.size   BgDesign_Map, .-BgDesign_Map
.global BgDesign_Map

/**************************************/

.section .rodata
.balign 4

BgDesign_Pal:
	.word 0x04210000,0x0C630842,0x10A51084,0x1CE718C6,0x25292108,0x2D6B294A,0x35AD318C,0x46313DEF @ Design
	.word 0x04210000,0x210814A5,0x1D6E2529,0x0CA8150A,0x090C0864,0x19B30D4F,0x1E7A1E17,0x22DF229D
	.word 0x10420000,0x4CEE44AC,0x75566512,0x5D7071B4,0x24C6412B,0x416A2506,0x62306270,0x55CF69F2
	.word 0x08210000,0x28672046,0x3CAB3089,0x2CA838CA,0x10632085,0x20A51083,0x31083128,0x2CE734E9
	.word 0x08420000,0x10840C63,0x25292108,0x318C2D6B,0x4A5239CE,0x5AD64E73,0x67395EF7,0x7FFF7BDE @ Text
	.word 0x00000000,0x04210000,0x08420842,0x0C630C63,0x10840C63,0x14A514A5,0x18C614A5,0x21081CE7
	.word 0x18820000,0x49863104,0x662A6208,0x6A8E666C,0x6EF26ED0,0x77577315,0x7BBB7779,0x7FFF7FDD @ Graphs
	.word 0x10460000,0x30D2208C,0x45594118,0x51DA4D99,0x5E5B5A1B,0x6AFD62BC,0x777E6F3D,0x7FFF7BBF
.size   BgDesign_Pal, .-BgDesign_Pal
.global BgDesign_Pal

/**************************************/
/* EOF                                */
/**************************************/
