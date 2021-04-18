# ulcplayer-gba
Gameboy Advance player for [ulc-codec](https://github.com/Aikku93/ulc-codec).

![Screenshot](/Screenshot.png?raw=true)

## Details

As a proof of concept of the decoding complexity of ulc-codec, a Gameboy Advance demonstration was made. CPU usage is around 60% for 32768Hz @ 128kbps (M/S stereo) (or 65% in high-precision "64-bit" mode). Note that this is entirely a proof of concept; decode time for BlockSize=2048 (default for encoding tool) is 2-3 frames, so usage in real applications would need some form of threading to avoid excessive lag.

To use this player, you must:
 * Provide your own ```SoundData.ulc``` and modify ```ulcplayer.s``` to match.
 * Modify the ```PATH``` variable in the ```Makefile``` to point to your build tools
 * Compile with a suitable ARM assembler+linker (wholly written in assembly; no compiler needed)

The player supports both mono and stereo files and any block size up to 2048.

## Authors
 * **Ruben Nunez** - *Initial work* - [Aikku93](https://github.com/Aikku93)

## Acknowledgements
* Credit goes to the following artists for their tracks used as demos:
  * [Adaro](https://music.youtube.com/channel/UCs36BCtgc4NIlaH1CwqZNrw)
  * [Damian Ray](https://music.youtube.com/channel/UCmv071TnqPRRd5RrkrPh8Jw)
  * [Divide](https://music.youtube.com/channel/UC9hoh7Hnqj2dfoZS-nTriHA)
  * [Dr. Peacock](https://music.youtube.com/channel/UC3EjYttTVgJllvuttr6PzNw)
  * [Fury](https://music.youtube.com/channel/UC_S8_99gWKSex7VnolJSRoQ)
  * [Juju Rush](https://www.facebook.com/jujurush99/)
  * [Linkin Park](https://music.youtube.com/channel/UCxgN32UVVztKAQd2HkXzBtw)
  * [Mr. Ivex](https://music.youtube.com/channel/UCsrWJSnK1ZryH-92x00a4uA)
  * [Rayvolt](https://music.youtube.com/channel/UCUCZojA3_kduHSK_-bmYSAA)
  * [Re-Style](https://music.youtube.com/channel/UCL9cYAVYKKXubDZ-fXS4v4w)
  * [Sefa](https://djsefa.com/)
  * [Toto](https://music.youtube.com/channel/UCewH1MBbYlEZMWx3ZUNywyg)
  * [Vertex](https://music.youtube.com/channel/UCtRTO5SOpUJvfyZD43ZTxYQ)
  * [Vicetone](https://music.youtube.com/channel/UCBxPw3gBM65DpL64iD5kIiA) & [Tony Igy](https://music.youtube.com/channel/UCjW4TPq451IgyqBkDAmSdrw)
  * [Q-Dance](https://www.q-dance.com/)

## Pre-built tracks (Last update: 2021/04/18)

### Frenchcore Mix

Files:
 * [~64kbps VBR @ 32.768kHz (M/S stereo, 31.9MiB)](https://www.mediafire.com/file/rjrdv9joq0558xq/file)

Featuring:
 * Rayvolt - And We Run
 * Vertex - Get Down
 * Divide - Never Let Go
 * Fury - All I Want
 * Adaro - I'm Alive (Re-Style & Vertex Remix)
 * Damian Ray - In My Brain (Rayvolt Remix)
 * Vertex - Collective Paranoia
 * Re-Style & Vertex - Shadow World
 * Vertex - Breaking The Habit
 * Juju Rush - Catching Fire
 * Sefa & Mr. Ivex - LSD Problem
 * Sefa - Schopenhauer
 * Dr. Peacock - Vive La Volta (Sefa Remix)
 * Vertex - Let It Roll
 * Re-Style - Towards the Sun (Vertex & Rayvolt Remix)
 * Rayvolt - Wellerman
 * Toto - Africa (Rayvolt Remix)
 * Vicetone & Tony Igy - Astronomia (Rayvolt Remix)

### (Q-Dance) Defqon.1 Weekend Festival 2019 - Sefa

Files:
 * [~105kbps VBR @ 32.768kHz (M/S stereo, 31.9MiB)](https://www.mediafire.com/file/ve1xtc6e11ge09h/file)

### Rayvolt - Start The Revolt: Live Yearmix 2020

Files:
 * [~63kbps VBR @ 32.768kHz (M/S stereo, 31.8MiB)](https://www.mediafire.com/file/khi0dtx0ifgo9ql/file)
