/**************************************/

.section .rodata
.balign 4

BgDesignSpeakerBass_Gfx: @ 8*2*64 tiles
	.incbin "source/res/BgDesignSpeakerBass.lz.bin"
.size   BgDesignSpeakerBass_Gfx, .-BgDesignSpeakerBass_Gfx
.global BgDesignSpeakerBass_Gfx

/**************************************/

.section .rodata
.balign 4

BgDesignSpeakerBass_Pal:
	.word 0x08620000,0x18C61084,0x21081CE7,0x254A2129,0x2D8C296B,0x35EF31AD,0x3E313A10,0x4A734252
.size   BgDesignSpeakerBass_Pal, .-BgDesignSpeakerBass_Pal
.global BgDesignSpeakerBass_Pal

/**************************************/
/* EOF                                */
/**************************************/
