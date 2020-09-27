# ulcplayer-gba
Gameboy Advance player for [ulc-codec](https://github.com/Aikku93/ulc-codec).

## Details

As a proof of concept of the decoding complexity of ulc-codec, a Gameboy Advance demonstration was made. CPU usage is around 60..65% for 32768Hz @ 128kbps (M/S stereo). Note that this is entirely a proof of concept; decode time for N=4096 (default for encoding tools) is 2-3 frames, so usage in real applications would need some form of threading to avoid excessive lag.

To use this player, you must:
* Provide your own ```SoundData.ulc``` in the ```source``` folder, and modify the sound files on lines 837 onwards of ```ulcplayer.s```
* Modify the ```PATH``` variable in the ```Makefile``` to point to your build tools
* Compile with a suitable ARM assembler+linker (wholly written in assembly; no compiler needed)

The player supports both mono and stereo files and any block size up to 2048.

## Authors
* **Ruben Nunez** - *Initial work* - [Aikku93](https://github.com/Aikku93)

## Acknowledgements
* Special thanks to [No!ze Freakz](https://www.youtube.com/user/SrPojallapimo) for permission to use their track 'Freedom' for demonstration purposes
* Credit goes to the following other artists:
  * [Adrenalize](https://www.adrenalizedj.com/)
  * [B-Front](https://www.djbfront.nl/)
  * [Da Tweekaz](http://datweekaz.com/)
  * [Code Black](http://codeblackmedia.nl)
  * [DJ S3RL](https://djs3rl.com/)
  * [MC Riddle](https://soundcloud.com/mc_riddle)
  * [Gl!tch](https://www.youtube.com/channel/UCT5X66gLr8K_f630x4W-hrA)
  * [Mark With a K](http://www.markwithak.be/)
  * [Noisecontrollers](https://www.noisecontrollers.com/)
  * [Andy Svge](https://soundcloud.com/djandysvge)
  * [Psyko Punks](http://psykopunkz.com/)
  * [K's Choice](http://www.kschoice.rocks/)
  * [The Script](https://www.thescriptmusic.com/)
  * [Dark Rehab](https://soundcloud.com/darkrehab)
  * [Eiffel 65](https://www.eiffel65.com/)
  * [Cranberries](https://www.cranberries.com/)
  * [Q-Dance](https://www.q-dance.com/) for:
    * Reverze 2018 set featuring [Da Tweekaz](http://datweekaz.com/)
    * Reverze 2018 set featuring [Ran-D](https://www.ran-d.com/)
    * Reverze 2020 set featuring [D-Block & S-te-Fan](https://www.dblock-stefan.com/)
    * X-Qlusive 2019 set featuring [Da Tweekaz](http://datweekaz.com/) and [D-Block & S-te-Fan](https://www.dblock-stefan.com/)

## Pre-built tracks

### Hardstyle Volume 1

Files:
* [64kbps @ 32.768kHz (M/S stereo, 15.3MiB)](http://www.mediafire.com/file/4i3jn05snafi8u0/file)
* [96kbps @ 32.768kHz (M/S stereo, 23.0MiB)](http://www.mediafire.com/file/6pf02oh3ki3he0u/file)
* [128kbps @ 32.768kHz (M/S stereo, 30.6MiB)](http://www.mediafire.com/file/vkhgx77vb7kthkj/file)

Featuring:
* B-Front & Adrenalize - Above Heaven
* Da Tweekaz - Jägermeister
* Da Tweekaz - People Against P\*rn (10 Years Mix)
* Da Tweekaz - Wodka
* Da Tweekaz & Code Black - Shake Ya Shimmy
* D-Block & S-te-Fan - Feel Inside
* D-Block & S-te-Fan - Primal Energy (Defqon.1 2020 Anthem)
* Eiffel 65 - Blue (Team Blue Radio Mix)

### Hardstyle Volume 2

Files:
* [64kbps @ 32.768kHz (M/S stereo, 15.1MiB)](http://www.mediafire.com/file/k1tpdtzahyczga8/file)
* [96kbps @ 32.768kHz (M/S stereo, 22.6MiB)](http://www.mediafire.com/file/d3lol2s6z4jdri0/file)
* [128kbps @ 32.768kHz (M/S stereo, 30.2MiB)](http://www.mediafire.com/file/05hryp4dv3brkyh/file)

Featuring:
* Mark With a K - See Me Now (Da Tweekaz Extended Remix)
* No!ze Freakz - Freedom
* Noisecontrollers - Crump (Ran-D Remix)
* Noisecontrollers - Revolution Is Here (Original Mix)
* Ran-D - Zombie
* Ran-D & ANDY SVGE - Armageddon
* Ran-D & Psyko Punkz Ft. K's Choice - Not An Addict

### Hardstyle Volume 3

Files:
* [64kbps @ 32.768kHz (M/S stereo, 14.3MiB)](http://www.mediafire.com/file/391mpb9k2sy2gcn/file)
* [96kbps @ 32.768kHz (M/S stereo, 21.4MiB)](http://www.mediafire.com/file/uz4v86goll9d5mc/file)
* [128kbps @ 32.768kHz (M/S stereo, 28.6MiB)](http://www.mediafire.com/file/oj9zobmzlqkouam/file)

Featuring:
* S3RL - Fan Service
* S3RL - Hentai
* S3RL - MTC
* S3RL - MTC2
* S3RL - Ravers MashUp
* S3RL feat Kayliana & MC Riddle - All That I Need
* S3RL ft. Gl!tch - Cherry Pop
* S3RL vs Auscore - Green Hills 2017
* The Script - Hall Of Fame (Dark Rehab Hardstyle Bootleg)

### S3RL - S3RL Always Presents...

Files:
* [96kbps @ 32.768kHz (M/S stereo, 30.6MiB)](http://www.mediafire.com/file/q80g8h9iuppwczl/file)

### (Q-Dance) Reverze 2018 - Da Tweekaz

Files:
* [96kbps @ 32.768kHz (M/S stereo, 31.8MiB)](http://www.mediafire.com/file/03rwmaz4t8vorp6/file)

### (Q-Dance) Reverze 2018 - Ran-D

Files:
* [96kbps @ 32.768kHz (M/S stereo, 29.1MiB)](http://www.mediafire.com/file/ptny43ma3sibrjq/file)

### (Q-Dance) Reverze 2020 - D-Block & S-te-Fan

Files:
* [75kbps @ 32.768kHz (M/S stereo, 31.5MiB)](http://www.mediafire.com/file/aotfs28rbv8t1vx/file)

### (Q-Dance) X-Qlusive 2019 - Da Tweekaz, D-Block & S-te-Fan

Files:
* [79kbps @ 32.768Hz (M/S stereo, 31.8MiB)](http://www.mediafire.com/file/oh6b7lw274bkldc/file)

