# ulcplayer-gba
Gameboy Advance player for [ulc-codec](https://github.com/Aikku93/ulc-codec).

![Screenshot](/Screenshot.png?raw=true)

## Details

As a proof of concept of the decoding complexity of ulc-codec, a Gameboy Advance demonstration was made. CPU usage is around 65% for 32768Hz @ 128kbps (M/S stereo) (or 70% when using LUT mode for [IM]DCT). Note that this is entirely a proof of concept; decode time for BlockSize=2048 (default for encoding tool) is 2-3 frames, so usage in real applications would need some form of threading to avoid excessive lag.

To use this player, you must:
 * Provide your own ```SoundData.ulc``` and modify ```ulcplayer.s``` to match.
 * Modify the ```PATH``` variable in the ```Makefile``` to point to your build tools
 * Compile with a suitable ARM assembler+linker (wholly written in assembly; no compiler needed)

By default, the player uses a quadrature oscillator for [IM]DCT routines, and supports both mono and stereo files and any block size up to 2048.

For stereo audio and a maximum block size of 2048 samples, memory usage is 3.1KiB IWRAM code, 24KiB IWRAM data, ~8KiB EWRAM data, and 236 bytes of ROM (or 8.2KiB when using LUT mode).

Note that the colour blending isn't perfect (due to GBA limitations). For best results, the backdrop should have high-contrast detail to mask blending artifacts.

## Authors
 * **Ruben Nunez** - *Initial work* - [Aikku93](https://github.com/Aikku93)

## Acknowledgements
* Credit goes to the following artists for their tracks used as demos:
  * [Damian Ray](https://music.youtube.com/channel/UCmv071TnqPRRd5RrkrPh8Jw)
  * [Death Punch](https://music.youtube.com/channel/UCXHpMpXp-omLq0wHYXmLsng)
  * [Dr. Peacock](https://music.youtube.com/channel/UC3EjYttTVgJllvuttr6PzNw)
  * [Juju Rush](https://www.facebook.com/jujurush99/)
  * [Korsakoff](https://music.youtube.com/channel/UCIw93jBDgd-hHhSJAtvQNRA)
  * Lune
  * [Mr. Ivex](https://music.youtube.com/channel/UCsrWJSnK1ZryH-92x00a4uA)
  * [Rayvolt](https://music.youtube.com/channel/UCUCZojA3_kduHSK_-bmYSAA)
  * [Re-Style](https://music.youtube.com/channel/UCL9cYAVYKKXubDZ-fXS4v4w)
  * [Runeforce](https://music.youtube.com/channel/UCkfDBzVQEOWKx2zX7Ul1Qcg)
  * [Sefa](https://djsefa.com/)
  * [Toto](https://music.youtube.com/channel/UCewH1MBbYlEZMWx3ZUNywyg)
  * [Vertex](https://music.youtube.com/channel/UCtRTO5SOpUJvfyZD43ZTxYQ)
  * [Vicetone](https://music.youtube.com/channel/UCBxPw3gBM65DpL64iD5kIiA) & [Tony Igy](https://music.youtube.com/channel/UCjW4TPq451IgyqBkDAmSdrw)
  * [Q-Dance](https://www.q-dance.com/)

## Pre-built Demo (Last update: 2022/05/22)

### **WARNING: Flashing lights.**

Files:
 * [~46kbps VBR (Q=43.8, 1h37m play time) @ 32.768kHz (M/S stereo, 31.9MiB)](https://www.mediafire.com/file/rjrdv9joq0558xq/file)

Featuring:
 * Vertex - Run It Up
 * Vertex - Get Down
 * Rayvolt - And We Run
 * Damian Ray - In My Brain (Rayvolt Remix)
 * Sefa & Crypton - Lastig
 * Vertex - Collective Paranoia
 * Sefa & Mr. Ivex - LSD Problem
 * Re-Style & Vertex - Shadow World
 * Sefa - Schopenhauer
 * Dr. Peacock - Vive La Volta (Sefa Remix)
 * Juju Rush - Catching Fire
 * Vertex - Let It Roll
 * Re-Style - Towards the Sun (Vertex & Rayvolt Remix)
 * Vertex - Radiance
 * Re-Style - Wildfire
 * Toto - Africa (Rayvolt Remix)
 * Rayvolt - Wellerman
 * Vicetone & Tony Igy - Astronomia (Rayvolt Remix)
 * Re-Style & Korsakoff - Leap of Faith
 * Runeforce ft. Lune - Lonely Soldier
 * Death Punch - Nowhere Warm
 * Dr. Peacock & Sefa - Incoming
 * Re-Style & Runeforce - A New Dawn

### NOTE: This is likely to be the last release of the GBA demo.

The player has been ported to NDS in a much cleaner implementation that is closer to the `ulcdecodetool` style of operation. However, the code will not be released on GitHub until my NDS library has been released (as this will allow the decoder to run in its own lower-priority thread, improving usability).

If you desperately wish to get your hands on the NDS version, feel free to message me (it is currently running on libnds). However, please note that it hasn't been fully debugged yet (due to real-life issues and focusing on other projects), and issues might arise in edge cases.

In the off chance that there is a syntax change, this demo will be updated so as to always have a reference ARM assembly decoder.
