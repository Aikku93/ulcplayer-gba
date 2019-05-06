# ulcplayer-gba
Gameboy Advance player for [ulc-codec](https://github.com/Aikku93/ulc-codec).

## Details

As a proof of concept of the decoding complexity of ulc-codec, a Gameboy Advance demonstration was made. CPU usage is around 65% for 32768Hz @ 128kbps (M/S stereo). Note that this is entirely a proof of concept; decode time for N=4096 (default for encoding tools) is 2-3 frames, so usage in real applications would need some form of threading to avoid excessive lag.

To use this player, you must:
* Provide your own ```SoundData.ulc``` in the ```source/res``` folder
* Modify the ```PATH``` variable in the ```Makefile``` to point to your build tools
* Compile with a suitable ARM assembler+linker (wholly written in assembly; no compiler needed)

The player supports both mono and stereo files (requires a rebuild; mono/stereo(+M/S) toggle found in ```source/ulc/ulc_Specs.inc```). M/S stereo isn't the best quality (as the transform is performed on clipped 8-bit samples), but this doesn't appear to cause noticeable quality degradation.

## Authors
* **Ruben Nunez** - *Initial work* - [Aikku93](https://github.com/Aikku93)

## Acknowledgements
* Special thanks to [No!ze Freakz](https://soundcloud.com/user-462957379) for permission to use their track 'Freedom' for demonstration purposes
* Credit goes to [Da Tweekaz](https://soundcloud.com/datweekaz) for their remix of Eiffel 65's track 'Blue'
* Credit goes to [DJ S3RL](https://djs3rl.com/) for their track 'Ravers MashUp'

### Pre-built tracks

* [No!ze Freakz - Freedom (64kbps @ 32.768kHz, M/S stereo)](No!ze%20Freakz%20-%20Freedom%20(64k).gba)
* [Eiffel 65 - Blue (Team Blue Mix) (96kbps @ 32.768kHz, M/S stereo)](Eiffel%2065%20-%20Blue%20(Team%20Blue%20Mix)%20-%20Da%20Tweekaz%20(96k).gba)
* [S3RL - Ravers MashUp (64kbps @ 32.768kHz, M/S stereo)](S3RL%20-%20Ravers%20MashUp%20(64k).gba)
