# ulcplayer-gba
Gameboy Advance player for [ulc-codec](https://github.com/Aikku93/ulc-codec).

## Details

As a proof of concept of the decoding complexity of ulc-codec, a Gameboy Advance demonstration was made. CPU usage is around 65% for 32768Hz @ 128kbps (M/S stereo). Note that this is entirely a proof of concept; decode time for N=4096 (default for encoding tools) is 2-3 frames, so usage in real applications would need some form of threading to avoid excessive lag.

To use this player, you must:
* Provide your own ```SoundData.ulc``` in the ```source/res``` folder
* Modify the ```PATH``` variable in the ```Makefile``` to point to your build tools
* Compile with a suitable ARM assembler+linker (wholly written in assembly; no compiler needed)

The player supports both mono and stereo files (requires a rebuild; mono/stereo(+M/S) toggle found in ```source/ulc/ulc_Specs.inc```). M/S stereo isn't the best quality (as the transform is performed on clipped 8-bit samples), but this doesn't appear to cause noticeable quality degradation.

### Pre-built tracks

[No!ze Freakz - Freedom (64kbps @ 32.768kHz, M/S stereo)](No!ze%20Freakz%20-%20Freedom%20(64k).gba)
