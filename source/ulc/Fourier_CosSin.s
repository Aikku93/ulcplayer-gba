/**************************************/
.include "source/ulc/ulc_Specs.inc"
/**************************************/
.section .rodata
.balign 4
/**************************************/

Fourier_CosSin:
.if ULC_USE_QUADRATURE_OSC
	@ Quadrature oscillator terms (.16fxp)
	@ struct { u32 cos:20, sin:12; } = {.cos=Floor[2^16*Cos[(0+0.5)*Pi/2/N]], .sin=Floor[2^16*Sin[(0+0.5)*Pi/2/N]]}
	@ The oscillator frequency's value is constant up to
	@ scaling and is ommitted here; it is instead hardcoded.
	@ The value is Tan[Pi/2/N] ~= 1.59375/N ~= (1+2^-4)(1-2^-2)/(N/2)
	@ 1.59375 is not the PSNR-optimal approximation to the Tan term,
	@ but is PSNR-optimal for the output of larger transforms.
	.word 0xC900FFB2 @ N=16
	.word 0x6490FFED @ N=32
	.word 0x3250FFFC @ N=64
	.word 0x1930FFFF @ N=128
	.word 0x0CA10000 @ N=256
	.word 0x06510000 @ N=512
	.word 0x03310000 @ N=1024
	.word 0x01A10000 @ N=2048
.else
	@ Quarter sine table, shifted by a half sample, and interleaved as {Cos,Sin}
	@  CosSinTable[N_] := Table[{Cos[(n+0.5)*Pi/2 / N], Sin[(n+0.5)*Pi/2 / N]}, {n,0,N/2-1}]
	@  Table[CosSinTable[2^k], {k,4,11}]
	@ Used for IMDCT window and DCT-IV routines
	@ Note that this always includes windows for up to N=2048.
	.incbin "source/ulc/Fourier_CosSin16.bin" @ 16bit coefficients
.endif

/**************************************/
.size   Fourier_CosSin, .-Fourier_CosSin
.global Fourier_CosSin
/**************************************/
/* EOF                                */
/**************************************/
