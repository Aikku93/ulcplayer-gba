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
  * [Rayvolt](https://music.youtube.com/channel/UCUCZojA3_kduHSK_-bmYSAA)
  * [Dr. Peacock](https://music.youtube.com/channel/UC3EjYttTVgJllvuttr6PzNw)
  * [Sefa](https://djsefa.com/)
  * [Irradiate](https://irradiate.nl/)
  * [Juju Rush](https://www.facebook.com/jujurush99/)
  * [Nosferatu](https://www.youtube.com/@nosferatuofficial)
  * [Nolz](https://www.youtube.com/channel/UCo7Oj3MhWKeBk08UN60lYhA)
  * [Re-Style](https://music.youtube.com/channel/UCL9cYAVYKKXubDZ-fXS4v4w)
  * [Runeforce](https://music.youtube.com/channel/UCkfDBzVQEOWKx2zX7Ul1Qcg)
  * [Vertex](https://music.youtube.com/channel/UCtRTO5SOpUJvfyZD43ZTxYQ)
  * [Cammie Robinson](https://www.youtube.com/channel/UC76cQD_opNq3sntp3hHNKEQ)
  * Lune
  * [Crypton](https://www.youtube.com/channel/UCvqH0bSFhwjzzW_fp2oVdXA)

## Pre-built Demo (Last update: 2023/06/04)

### **WARNING: Flashing lights.**

Files:
 * [~69kbps VBR (Q=64.0, 1h4m play time) @ 32.768kHz (M/S stereo, 31.9MiB)](https://www.mediafire.com/file/rjrdv9joq0558xq/file)

Featuring:
 * Damian Ray - In My Brain (Rayvolt Remix)
 * Dr. Peacock - Vive La Volta (Sefa Remix)
 * Irradiate - Edge of Infinity (In Our Blood)
 * Juju Rush - Catching Fire
 * Nosferatu & Nolz - Cosmic Conquest
 * Rayvolt - And We Run
 * Re-Style & Runeforce - A New Dawn
 * Re-Style & Vertex - Shadow World
 * Re-Style ft. Cammie Robinson - Feel Alive
 * Runeforce ft. Lune - Lonely Soldier
 * Sefa & Crypton - Lastig
 * Vertex - Collective Paranoia
 * Vertex - Let It Roll
 * Vertex - Radiance

## Nintendo DS Player

ulc-codec's decoding library has been ported to NDS. See [the project page](https://github.com/Aikku93/ulcplayer-nds) for more details.
