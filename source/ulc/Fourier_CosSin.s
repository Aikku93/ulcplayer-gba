/**************************************/
.include "source/ulc/ulc_Specs.inc"
/**************************************/
.section .rodata
.balign 4
/**************************************/

@ Quarter sine table, shifted by a half sample, and interleaved as {Cos,Sin}
@  CosSinTable[N_] := Table[{Cos[(n+0.5)*Pi/2 / N], Sin[(n+0.5)*Pi/2 / N]}, {n,0,N/2-1}]
@  Table[CosSinTable[2^k], {k,4,11}]
@ Used for IMDCT window and DCT-IV routines
@ Note that this always includes windows for up to N=2048.

Fourier_CosSin:
.if ULC_64BIT_MATH
	.incbin "source/ulc/Fourier_CosSin16.bin" @ 16bit coefficients
.else
	.incbin "source/ulc/Fourier_CosSin15.bin" @ 15bit coefficients to avoid overflow
.endif

/**************************************/
.size   Fourier_CosSin, .-Fourier_CosSin
.global Fourier_CosSin
/**************************************/
/* EOF                                */
/**************************************/
