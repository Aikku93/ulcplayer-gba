# ulcplayer-gba
Gameboy Advance player for [ulc-codec](https://github.com/Aikku93/ulc-codec).

![Screenshot](/Screenshot.png?raw=true)

## Details

As a proof of concept of the decoding complexity of ulc-codec, a Gameboy Advance demonstration was made. CPU usage is around 60% for 32768Hz @ 128kbps (M/S stereo) (or 70% in high-precision "64-bit" mode). Note that this is entirely a proof of concept; decode time for BlockSize=2048 (default for encoding tool) is 2-3 frames, so usage in real applications would need some form of threading to avoid excessive lag.

To use this player, you must:
* Provide your own ```SoundData.ulc``` and modify ```ulcplayer.s``` to match.
* Modify the ```PATH``` variable in the ```Makefile``` to point to your build tools
* Compile with a suitable ARM assembler+linker (wholly written in assembly; no compiler needed)

The player supports both mono and stereo files and any block size up to 2048.

## Authors
* **Ruben Nunez** - *Initial work* - [Aikku93](https://github.com/Aikku93)

## Acknowledgements
* Credit goes to the following artists for their tracks used as demos:
  * [Massive Disorder](https://music.youtube.com/channel/UCh0Wpik492k20CGDdO-oMxw)
  * [Dj Rosell](https://music.youtube.com/channel/UCYtG8dK4NRvaO5qzJbD1_cg)
  * [Rayvolt](https://music.youtube.com/channel/UCUCZojA3_kduHSK_-bmYSAA)
  * [Divide](https://music.youtube.com/channel/UC9hoh7Hnqj2dfoZS-nTriHA)
  * [Fury](https://music.youtube.com/channel/UC_S8_99gWKSex7VnolJSRoQ)
  * [Broken Minds](https://music.youtube.com/channel/UCAGgywXWpRmXFP5bCSWr2Wg)
  * [D-Fence](https://music.youtube.com/channel/UCYWaI0YFInBINNgeKUeUgLg)
  * [Mr. Ivex](https://music.youtube.com/channel/UCsrWJSnK1ZryH-92x00a4uA)
  * [D-Attack](https://music.youtube.com/channel/UCX3df7M01uW8ET0554TdQeg)
  * [Sprinky](https://music.youtube.com/channel/UCYyRu41eHt787jvvgROnY9g)
  * [Death Faction](https://www.hardtunes.com/artists/death-faction)
  * [Vertex](https://music.youtube.com/channel/UCtRTO5SOpUJvfyZD43ZTxYQ)
  * [Q-Dance](https://www.q-dance.com/) for Defqon.1 Weekend Festival 2019 set featuring [Sefa](https://djsefa.com/)

## Pre-built tracks (Last update: 2021/01/29)

### Frenchcore Mix

Files:
* [128kbps ABR @ 32.768kHz (M/S stereo, 30.6MiB)](https://www.mediafire.com/file/rjrdv9joq0558xq/file)

Featuring:
* Massive Disorder & Rosell - Widifan
* Rayvolt - And We Run
* Divide - Never Let Go
* Fury - All I Want
* Korsakoff - Lyra (Broken Minds Remix)
* Linkin Park - In The End (D-Fence Remix)
* Mr. Ivex & D-Attack - OMG
* Sprinky & Death Faction - Disposable Humans
* Vertex - Let It Roll

### (Q-Dance) Defqon.1 Weekend Festival 2019 - Sefa

Files:
* [105kbps ABR @ 32.768kHz (M/S stereo, 31.8MiB)](https://www.mediafire.com/file/ve1xtc6e11ge09h/file)

### Rayvolt - Start The Revolt: Live Yearmix 2020

Files:
* [63kbps ABR @ 32.768kHz (M/S stereo, 31.8MiB)](https://www.mediafire.com/file/khi0dtx0ifgo9ql/file)
