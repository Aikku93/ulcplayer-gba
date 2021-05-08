.equ ULC_FILE_MAGIC, ('U' | 'L'<<8 | 'C'<<16 | '2'<<24)

@ This controls the maximum block size allowed for
@ decoding. A larger size uses more memory, but allows
@ higher coding gain. Note that on GBA, this is also
@ limited by the amount of IWRAM available, as the
@ IMDCT transform buffers are placed there instead of
@ EWRAM due to extremely poor waitstates.
.equ ULC_MAX_BLOCK_SIZE_LOG2, 11
.equ ULC_MAX_BLOCK_SIZE, (1 << ULC_MAX_BLOCK_SIZE_LOG2)

@ This controls support for stereo decoding.
@ Support for stereo audio requires double the memory
@ usage for the transform and playback buffers.
.equ ULC_STEREO_SUPPORT, 1

@ These options control IMDCT behaviour.
@  -ULC_64BIT_MATH uses 64bit math to work around overflow
@   in intermediate calculations. The downside is a large
@   increase in computation for 64bit multiplies. However,
@   this allows for more accurate calculations, as well as
@   allowing rounding during high-precision multiplication.
@   Note that this should not be necessary if the precision
@   is 15bit or lower (see ULC_COEF_PRECISION), as there is
@   no overflow at this level of precision.
@  -ULC_COEF_PRECISION controls the bitdepth of the audio,
@   excluding the sign bit (eg. 16bit audio would set this
@   to 15). It is strongly recommended to set this to at
@   least double the target bitdepth in order to minimize
@   rounding error during IMDCT, up to a maximum of 28.
@   This value must NOT be larger than 28. In theory, it's
@   possible to set this to 29, but this requires special
@   handling in ulc_BlockProcess() (the shift factor can
@   become 0, which requires clearing the LSR flag). If set
@   to anything larger, MDCT coefficients will overflow.
@   NOTE: This refers to the internal precision, not the
@   final audio output; this is always 8bit for GBA.
.equ ULC_64BIT_MATH,      1
.equ ULC_COEF_PRECISION, 28

@ This enables a crappy pitch-shift algorithm.
@ Fairly useless and poor quality, but fun to play with.
.equ ULC_ALLOW_PITCH_SHIFT, 1
