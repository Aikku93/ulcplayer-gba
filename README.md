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
* Credit goes to [Da Tweekaz](http://datweekaz.com/) for their remix of Eiffel 65's track 'Blue', and their 10-years remix of 'People Against P*rn'
* Credit goes to [DJ S3RL](https://djs3rl.com/) for their track 'Ravers MashUp'
* Credit goes to [MANTIS](https://soundcloud.com/mantisdubstep) for their track 'Block Rocka'
* Credit goes to [Q-Dance](https://www.q-dance.com/) for their X-Qlusive 2019 set featuring [Da Tweekaz](http://datweekaz.com/) and [D-Block & S-te-Fan](https://www.dblock-stefan.com/)

## Pre-built tracks

### Da Tweekaz - People Against P\*rn (10 Years Mix)
* [64kbps @ 32.768kHz (M/S stereo, 1.8MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Da%20Tweekaz%20-%20People%20Against%20Porn%20(10%20Years%20Mix)%20(64kbps).gba)
* [96kbps @ 32.768kHz (M/S stereo, 2.6MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Da%20Tweekaz%20-%20People%20Against%20Porn%20(10%20Years%20Mix)%20(96kbps).gba)
* [128kbps @ 32.768kHz (M/S stereo, 3.5MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Da%20Tweekaz%20-%20People%20Against%20Porn%20(10%20Years%20Mix)%20(128kbps).gba)

### Da Tweekaz - Wodka
* [64kbps @ 32.768kHz (M/S stereo, 2.5MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Da%20Tweekaz%20-%20Wodka%20(64kbps).gba)
* [96kbps @ 32.768kHz (M/S stereo, 3.7MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Da%20Tweekaz%20-%20Wodka%20(96kbps).gba)
* [128kbps @ 32.768kHz (M/S stereo, 4.9MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Da%20Tweekaz%20-%20Wodka%20(128kbps).gba)

### Eiffel 65 - Blue (Team Blue Mix by Da Tweekaz)
* [64kbps @ 32.768kHz (M/S stereo, 2.0MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Eiffel%2065%20-%20Blue%20(Team%20Blue%20Mix)%20-%20Da%20Tweekaz%20(64kbps).gba)
* [96kbps @ 32.768kHz (M/S stereo, 3.0MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Eiffel%2065%20-%20Blue%20(Team%20Blue%20Mix)%20-%20Da%20Tweekaz%20(96kbps).gba)
* [128kbps @ 32.768kHz (M/S stereo, 4.0MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Eiffel%2065%20-%20Blue%20(Team%20Blue%20Mix)%20-%20Da%20Tweekaz%20(128kbps).gba)

### MANTIS - Block Rocka
* [64kbps @ 32.768kHz (M/S stereo, 2.2MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/MANTIS%20-%20Block%20Rocka%20(64kbps).gba)
* [96kbps @ 32.768kHz (M/S stereo, 3.3MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/MANTIS%20-%20Block%20Rocka%20(96kbps).gba)
* [128kbps @ 32.768kHz (M/S stereo, 4.4MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/MANTIS%20-%20Block%20Rocka%20(128kbps).gba)

### No!ze Freakz - Freedom
* [64kbps @ 32.768kHz (M/S stereo, 1.8MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/No!ze%20Freakz%20-%20Freedom%20(64kbps).gba)
* [96kbps @ 32.768kHz (M/S stereo, 2.6MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/No!ze%20Freakz%20-%20Freedom%20(96kbps).gba)
* [128kbps @ 32.768kHz (M/S stereo, 3.5MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/No!ze%20Freakz%20-%20Freedom%20(128kbps).gba)

### (Q-Dance) Reverze 2018 - Da Tweekaz
* [96kbps @ 32.768kHz (M/S stereo, 31.8MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Reverze%202018%20-%20Da%20Tweekaz%20(96kbps).gba)

### (Q-Dance) Reverze 2020 - D-Block & S-te-Fan
* [75kbps @ 32.768kHz (M/S stereo, 31.5MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/Reverze%202020%20-%20D-Block%20&%20S-te-Fan%20(75kbps).gba)

### (Q-Dance) X-Qlusive 2019 - Da Tweekaz, D-Block & S-te-Fan
* [79kbps @ 32.768Hz (M/S stereo, 31.8MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/X-Qlusive%202019%20-%20Da%20Tweekaz,%20D-Block%20&%20S-te-Fan%20(79kbps).gba)

### S3RL - Ravers MashUp
* [64kbps @ 32.768kHz (M/S stereo, 1.9MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/S3RL%20-%20Ravers%20MashUp%20(64kbps).gba)
* [96kbps @ 32.768kHz (M/S stereo, 2.9MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/S3RL%20-%20Ravers%20MashUp%20(96kbps).gba)
* [128kbps @ 32.768kHz (M/S stereo, 3.8MiB)](https://github.com/Aikku93/ulcplayer-gba-prebuilt/raw/master/S3RL%20-%20Ravers%20MashUp%20(128kbps).gba)
