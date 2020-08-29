/**************************************/
.section .rodata
.balign 4
/**************************************/

BgDesign_Gfx:
	.incbin "source/res/BgDesign.gfx.lz"
.size   BgDesign_Gfx, .-BgDesign_Gfx
.global BgDesign_Gfx

/**************************************/

BgDesign_Map:
	.incbin "source/res/BgDesign.map.lz"
.size   BgDesign_Map, .-BgDesign_Map
.global BgDesign_Map

/**************************************/

BgDesign_Pal:
	.incbin "source/res/BgDesign.pal"
.size   BgDesign_Pal, .-BgDesign_Pal
.global BgDesign_Pal

/**************************************/

BgDesignSprites_Gfx:
	.incbin "source/res/BgDesignSprites.gfx.lz"
.size   BgDesignSprites_Gfx, .-BgDesignSprites_Gfx
.global BgDesignSprites_Gfx

/**************************************/

BgDesignSprites_Pal:
	.incbin "source/res/BgDesignSprites.pal"
.size   BgDesignSprites_Pal, .-BgDesignSprites_Pal
.global BgDesignSprites_Pal

/**************************************/
/* EOF                                */
/**************************************/
