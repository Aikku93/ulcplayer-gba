/**************************************/
#include "AsmMacros.h"
/**************************************/
#include "ulc_Specs.h"
/**************************************/

ASM_DATA_GLOBAL(Fourier_DCT4_TwiddleTable)
ASM_DATA_BEG   (Fourier_DCT4_TwiddleTable, ASM_MODE_ARM;ASM_SECTION_RODATA;ASM_ALIGN(4))

@ 2^15*E^(I*Pi/2*(0 + 1/2)/N)
Fourier_DCT4_TwiddleTable:
	.hword 0x7FD9,0x0648 @ N = 16
	.hword 0x7FF6,0x0324 @ N = 32
	.hword 0x7FFE,0x0192 @ N = 64
	.hword 0x7FFF,0x00C9 @ N = 128
	.hword 0x8000,0x0065 @ N = 256
	.hword 0x8000,0x0032 @ N = 512
	.hword 0x8000,0x0019 @ N = 1024
	.hword 0x8000,0x000D @ N = 2048

ASM_DATA_END(Fourier_DCT4_TwiddleTable)

/**************************************/
//! EOF
/**************************************/
