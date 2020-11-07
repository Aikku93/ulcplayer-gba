/**************************************/
.include "source/ulc/ulc_Specs.inc"
/**************************************/
@ Design to BG1
@ Glyphs to BG0
@ Graphs to OBJ
/**************************************/
.equ GRAPH_X,   0 @ Pixels
.equ GRAPH_Y,  40 @ Pixels
.equ GRAPH_W, 240 @ Pixels
.equ GRAPH_H,  64 @ Pixels
.equ GRAPH_H_LOG2, 6
.equ GRAPH_TILEOFS, 82
.equ GRAPH_SMPSTRIDE_RCP, 37453 @ 2^29 / (VBlankRate * GRAPH_W)
/**************************************/
.equ SONGDISPLAY_WIDTH,  224 @ Pixels
.equ SONGDISPLAY_HEIGHT,  10 @ Pixels
.equ SONGDISPLAY_X,        8 @ Pixels
.equ SONGDISPLAY_Y,       93 @ Pixels
.equ SONGDISPLAY_DELAYRATE,  0x00800000 @ Reciprocal of frames to delay (.31fxp, approximately 4.29 seconds)
.equ SONGDISPLAY_SCROLLRATE, 0x00200000 @ Pixels per frame (.31fxp - .9fxp (512px max scroll) = .22fxp)
.equ TIMEDISPLAY_WIDTH,   24 @ Pixels
.equ TIMEDISPLAY_HEIGHT,   5 @ Pixels
.equ TIMEDISPLAY_CUR_X,  104 @ Pixels
.equ TIMEDISPLAY_CUR_Y,  127 @ Pixels
.equ TIMEDISPLAY_END_X,  216 @ Pixels
.equ TIMEDISPLAY_END_Y,  127 @ Pixels
.equ TIMEDISPLAY_NULL,   0xBBBB @ "--:--"
/**************************************/
.equ BUTTON_PREVSONG_X,      9 @ Sprite offset (Pixels)
.equ BUTTON_PREVSONG_Y,    123
.equ BUTTON_PREVSONG_TILE,   0
.equ BUTTON_PREVSONG_NTILES, 8
.equ BUTTON_PREVSONG_PAL,   14
.equ BUTTON_PREVSONG_OBJ,    8 @ <- Hardcoded, do not change
.equ BUTTON_PLAY_X,         31 @ Sprite offset (Pixels)
.equ BUTTON_PLAY_Y,        117
.equ BUTTON_PLAY_TILE,      16
.equ BUTTON_PLAY_NTILES,    16
.equ BUTTON_PLAY_PAL,       15
.equ BUTTON_PLAY_OBJ,        9 @ <- Hardcoded, do not change
.equ BUTTON_PAUSE_X,        55 @ Sprite offset (Pixels)
.equ BUTTON_PAUSE_Y,       123
.equ BUTTON_PAUSE_TILE,     48
.equ BUTTON_PAUSE_NTILES,    8
.equ BUTTON_PAUSE_PAL,      14
.equ BUTTON_PAUSE_OBJ,      10 @ <- Hardcoded, do not change
.equ BUTTON_NEXTSONG_X,     78 @ Sprite offset (Pixels)
.equ BUTTON_NEXTSONG_Y,    123
.equ BUTTON_NEXTSONG_TILE,  64
.equ BUTTON_NEXTSONG_NTILES, 8
.equ BUTTON_NEXTSONG_PAL,   14
.equ BUTTON_NEXTSONG_OBJ,   11 @ <- Hardcoded, do not change
.equ BUTTON_SLIDER_X0,     122 @ Sprite offset (Pixels, min)
.equ BUTTON_SLIDER_X1,     211 @ Sprite offset (Pixels, max)
.equ BUTTON_SLIDER_Y,      126
.equ BUTTON_SLIDER_TILE,    80
.equ BUTTON_SLIDER_NTILES,   1
.equ BUTTON_SLIDER_PAL,     14
.equ BUTTON_SLIDER_OBJ,     12 @ <- Hardcoded, do not change
/**************************************/
.equ DESIGN_CHARMAP,   0
.equ DESIGN_TILEMAP,  31
.equ DESIGN_TILEOFS,   0
.equ GLYPHS_CHARMAP,   0
.equ GLYPHS_TILEMAP,  30
.equ GLYPHS_TILEOFS, (58 + 0x0000) @ Set palette here
/**************************************/
.equ SONGDISPLAY_TILEOFS,          GLYPHS_TILEOFS
.equ SONGDISPLAY_TILEADR,          (0x06000000 + 0x20*(SONGDISPLAY_TILEOFS & 0x03FF))
.equ SONGDISPLAY_WIDTH_TILES,      ((SONGDISPLAY_X     + SONGDISPLAY_WIDTH  + 7) / 8 - SONGDISPLAY_X/8)
.equ SONGDISPLAY_HEIGHT_TILES,     ((SONGDISPLAY_Y     + SONGDISPLAY_HEIGHT + 7) / 8 - SONGDISPLAY_Y/8)
.equ TIMEDISPLAY_CUR_TILEOFS,      (SONGDISPLAY_TILEOFS + SONGDISPLAY_WIDTH_TILES*SONGDISPLAY_HEIGHT_TILES)
.equ TIMEDISPLAY_CUR_TILEADR,      (0x06000000 + 0x20*(TIMEDISPLAY_CUR_TILEOFS & 0x03FF))
.equ TIMEDISPLAY_CUR_WIDTH_TILES,  ((TIMEDISPLAY_CUR_X + TIMEDISPLAY_WIDTH  + 7) / 8 - TIMEDISPLAY_CUR_X/8)
.equ TIMEDISPLAY_CUR_HEIGHT_TILES, ((TIMEDISPLAY_CUR_Y + TIMEDISPLAY_HEIGHT + 7) / 8 - TIMEDISPLAY_CUR_Y/8)
.equ TIMEDISPLAY_END_TILEOFS,      (TIMEDISPLAY_CUR_TILEOFS + TIMEDISPLAY_CUR_WIDTH_TILES*TIMEDISPLAY_CUR_HEIGHT_TILES)
.equ TIMEDISPLAY_END_TILEADR,      (0x06000000 + 0x20*(TIMEDISPLAY_END_TILEOFS & 0x03FF))
.equ TIMEDISPLAY_END_WIDTH_TILES,  ((TIMEDISPLAY_END_X + TIMEDISPLAY_WIDTH  + 7) / 8 - TIMEDISPLAY_END_X/8)
.equ TIMEDISPLAY_END_HEIGHT_TILES, ((TIMEDISPLAY_END_Y + TIMEDISPLAY_HEIGHT + 7) / 8 - TIMEDISPLAY_END_Y/8)
/**************************************/
.text
.balign 2
/**************************************/

.thumb
.thumb_func
main:
	LDR	r0, =0x04000204 @ Setup for better waitstates (not needed in emulation, but might be necessary on hardware?)
	LDR	r1, =0x4017
	STRH	r1, [r0]

.Lmain_LoadDesign:
0:	LDR	r0, =0x06000000 + DESIGN_TILEOFS*0x20
	LDR	r1, =BgDesign_Gfx
	BL	UnLZSS
0:	LDR	r0, =0x06000000 + DESIGN_TILEMAP*0x0800
	LDR	r1, =BgDesign_Map
	BL	UnLZSS
0:	LDR	r0, =BgDesign_Pal
	LDR	r1, =0x05000000
	LDR	r2, =(0x02 * 48 / 0x04)
	SWI	0x0C
0:	LDR	r0, =0x06010000
	LDR	r1, =BgDesignSprites_Gfx
	BL	UnLZSS
0:	LDR	r0, =BgDesignSprites_Pal
	LDR	r1, =0x05000200
	LDR	r2, =(0x02 * 16*16 / 0x04)
	SWI	0x0C
0:	LDR	r0, =.LBgDesignSprites_OAMData
	LDR	r1, =0x07000000 @ Setup sprites
	LDR	r2, =(0x08 * 13 / 0x04) | 1<<26 @ 13 sprites
	SWI	0x0B
0:	LDR	r0, =.Lmain_SpriteDisableWord
	LDR	r1, =0x07000000 + 0x08*13
	LDR	r2, =(0x08 * (128-13) / 0x04) | 1<<24 | 1<<26 @ Disable remaining sprites
	SWI	0x0B

.Lmain_InitTextTilemaps:
	LDR	r0, =0x06000000 + 0x0800*GLYPHS_TILEMAP + 0x02*(SONGDISPLAY_X/8 + 32*(SONGDISPLAY_Y/8))
	LDR	r1, =SONGDISPLAY_TILEOFS
	LDR	r2, =SONGDISPLAY_WIDTH_TILES
	LDR	r3, =SONGDISPLAY_HEIGHT_TILES
	BL	.Lmain_SetupRawTilemap
	LDR	r0, =0x06000000 + 0x0800*GLYPHS_TILEMAP + 0x02*(TIMEDISPLAY_CUR_X/8 + 32*(TIMEDISPLAY_CUR_Y/8))
	LDR	r1, =TIMEDISPLAY_CUR_TILEOFS
	LDR	r2, =TIMEDISPLAY_CUR_WIDTH_TILES
	LDR	r3, =TIMEDISPLAY_CUR_HEIGHT_TILES
	BL	.Lmain_SetupRawTilemap
	LDR	r0, =0x06000000 + 0x0800*GLYPHS_TILEMAP + 0x02*(TIMEDISPLAY_END_X/8 + 32*(TIMEDISPLAY_END_Y/8))
	LDR	r1, =TIMEDISPLAY_END_TILEOFS
	LDR	r2, =TIMEDISPLAY_END_WIDTH_TILES
	LDR	r3, =TIMEDISPLAY_END_HEIGHT_TILES
	BL	.Lmain_SetupRawTilemap

.Lmain_InitSetup:
	LDR	r0, =0x04000000
	LDR	r1, =(GLYPHS_TILEMAP<<8) | (DESIGN_TILEMAP<<8)<<16 @ BG0CNT, BG1CNT
	STR	r1, [r0, #0x08]
	MOV	r1, #0x00
	STR	r1, [r0, #0x10]   @ BG0HOFS,BG0VOFS
	STR	r1, [r0, #0x14]   @ BG1HOFS,BG1VOFS
	LDR	r1, =0x10102340
	STR	r1, [r0, #0x50]   @ Null over BG0,BG1,BD (additive blend, OBJ is added via AlphaBlend flag)
	LDR	r1, =_IRQTable
	LDR	r0, =VBlankIRQ
	STR	r0, [r1, #0x04*0] @ Set VBlank interrupt
	LDR	r1, =0x04000004
	LDR	r0, =1<<3
	STRH	r0, [r1]          @ Enable VBlank IRQ triggers
	LDR	r1, =0x04000200
	LDRH	r0, [r1]
	ADD	r0, #0x01         @ Enable VBlank IRQ
	STRH	r0, [r1]
0:	LDR	r4, =ulc_State
	MOV	r5, #0x00         @ CurrentSoundFile = NULL -> r5
	LDR	r6, =.LVBlankIRQ_MinsSecs
	LDR	r7, =TIMEDISPLAY_NULL
	MOV	r8, r5            @ KeysLastUpdate = 0 -> r8
	MOV	r9, r5            @ CurSongIdx = 0 -> r9

@ r4: &State
@ r5:  CurrentSoundFile
@ r6: &MinsSecs
@ r7:  TIMEDISPLAY_NULL
@ r8:  KeysLastUpdate
@ r9:  CurSongIdx

.LMainLoop:
	BL	ulc_BlockProcess
0:	LDR	r0, =0x04000130
	BL	.Lmain_DisableIRQTHUMB @ <- Lock to avoid VBlankIRQ() changing the values we modify here
	LDRH	r0, [r0] @ KeysThisUpdate -> r0
	MOV	r2, r8   @ KeysLastUpdate -> r2
	MVN	r0, r0   @ [invert low-active input to high-active]
	MOV	r8, r0
	MOV	r1, r0   @ KeysThisUpdate -> r1
	BIC	r0, r2   @ KeysTapped = KeysThisUpdate &~ KeysLastUpdate -> r0

.LMainLoop_UpdateButtons:
	LDR	r2, =0x07000000
1:	LSR	r3, r1, #0x09+1 @ Previous song? (SL)
	LDR	r3, =BUTTON_PREVSONG_TILE | BUTTON_PREVSONG_PAL<<12
	BCC	0f
	ADD	r3, #BUTTON_PREVSONG_NTILES
0:	STR	r3, [r2, #0x08*BUTTON_PREVSONG_OBJ + 0x04]
1:	LSR	r3, r1, #0x08+1 @ Next song? (SR)
	LDR	r3, =BUTTON_NEXTSONG_TILE | BUTTON_NEXTSONG_PAL<<12
	BCC	0f
	ADD	r3, #BUTTON_NEXTSONG_NTILES
0:	STR	r3, [r2, #0x08*BUTTON_NEXTSONG_OBJ + 0x04]
1:	LSR	r3, r1, #0x01+1 @ Pause? (B)
	LDR	r3, =BUTTON_PAUSE_TILE | BUTTON_PAUSE_PAL<<12
	BCC	0f
	ADD	r3, #BUTTON_PAUSE_NTILES
0:	STR	r3, [r2, #0x08*BUTTON_PAUSE_OBJ + 0x04]
1:	LSR	r3, r1, #0x00+1 @ Play? (A)
	LDR	r3, =BUTTON_PLAY_TILE | BUTTON_PLAY_PAL<<12
	BCC	0f
	ADD	r3, #BUTTON_PLAY_NTILES
0:	STR	r3, [r2, #0x08*BUTTON_PLAY_OBJ + 0x04]

.LMainLoop_ProcessButtons:
.if ULC_ALLOW_PITCH_SHIFT
	LSR	r1, r0, #0x06+1 @ Pitch up? (Up)
	BCS	.LMainLoop_PitchUp
	LSR	r1, r0, #0x07+1 @ Pitch down? (Down)
	BCS	.LMainLoop_PitchDown
.endif
	LSR	r1, r0, #0x09+1 @ Previous song? (SL)
	BCS	.LMainLoop_PreviousSong
	LSR	r1, r0, #0x08+1 @ Next song? (SR)
	BCS	.LMainLoop_NextSong
	LSR	r1, r0, #0x01+1 @ Pause? (B)
	BCS	.LMainLoop_PauseSong
	LSR	r1, r0, #0x00+1 @ Play? (A)
	BCS	.LMainLoop_PlaySong

.LMainLoop_ProcessState:
	LDR	r0, [r4, #0x08] @ File has changed?
	CMP	r0, r5
	BEQ	2f
10:	MOV	r5, r0          @ Set CurrentSoundFile. Playing music (ie. not stopped)?
	BEQ	12f
11:	LDR	r2, [r5, #0x10] @ File.BlockSize -> r2
	LDR	r0, [r5, #0x08] @ File.nSamp -> r0
	LDR	r1, [r5, #0x0C] @ File.RateHz -> r1
	ADD	r0, r2          @ Pad nSamp with 2*BlockSize to account for coding delays
	ADD	r0, r2
	BL	__aeabi_uidiv   @ nSeconds -> r0
	LDR	r2, =0x88888889 @ 1/60 [.37fxp] -> r2
	LDR	r3, =0xCCCCCCCD @ 1/10 [.35fxp] -> r3
	BL	.Lmain_GetMinsSecsTHUMB
	MOV	r0, #0x00       @ Playing:
	LDR	r2, =-SONGDISPLAY_SCROLLRATE
	STR	r0, [r6, #0x00] @  Reset 'elapsed' time = 0
	STR	r1, [r6, #0x04] @  Set 'end' time
	STR	r0, [r6, #0x08] @  Reset MinsSecsLastUpdateSample = 0
	STR	r2, [r6, #0x10] @  Reset Scroll = -ScrollRate (forces a track name redraw)
	B	2f
12:	LDR	r0, =-SONGDISPLAY_SCROLLRATE
	STR	r7, [r6, #0x00] @ Not playing: Display "--:--" for 'elapsed' and 'end'
	STR	r7, [r6, #0x04]
	STR	r0, [r6, #0x10] @  Reset Scroll = -ScrollRate (as above, forces a redraw to remove the 'playing' symbol)
2:

.LMainLoop_Tail:
	BL	.Lmain_EnableIRQTHUMB
	MOV	r0, #0x00 @ IntrWait (return if already set)
	MVN	r1, r0    @ Any interrupt
	SWI	0x04
	B	.LMainLoop

.LMainLoop_PitchUp:
	LDR	r0, =ulc_PitchShiftKey
	LDR	r1, [r0]
	CMP	r1, #0x0C
	BGE	.LMainLoop_ProcessState
	ADD	r1, #0x01
	STR	r1, [r0]
	B	.LMainLoop_ProcessState

.LMainLoop_PitchDown:
	LDR	r0, =ulc_PitchShiftKey
	LDR	r1, [r0]
	ADD	r1, #0x0C-1
	BLT	.LMainLoop_ProcessState
	SUB	r1, #0x0C
	STR	r1, [r0]
	B	.LMainLoop_ProcessState

.LMainLoop_PauseSong:
	LDR	r0, [r4, #0x04] @ Toggle Pause flag
	MOV	r1, #0x01<<1
	EOR	r0, r1
	STR	r0, [r4, #0x04]
	B	.LMainLoop_ProcessState

.LMainLoop_PreviousSong:
	LDR	r0, =SoundFiles
	LDR	r0, [r0]
	MOV	r1, #0x00
	CMP	r9, r1 @ if(Idx == 0) Idx = nSongs-1
	BHI	1f
0:	SUB	r0, #0x01
	MOV	r9, r0
	B	.LMainLoop_PlaySong
1:	MVN	r1, r1
	ADD	r9, r1
	B	.LMainLoop_PlaySong

.LMainLoop_NextSong:
	LDR	r0, =SoundFiles
	LDR	r0, [r0]
	MOV	r1, #0x01
	ADD	r9, r1 @ if(++Idx >= nSongs) Idx = 0
	CMP	r9, r0
	BCC	.LMainLoop_PlaySong
1:	MOV	r0, #0x00
	MOV	r9, r0
	@B	.LMainLoop_PlaySong

.LMainLoop_PlaySong:
	MOV	r5, #0x00 @ Force reset by clearing CurrentSoundFile
	LDR	r1, =SoundFiles
	MOV	r0, r9 @ Seek to song data, then &Data -> r0, &Name -> r1
	LSL	r0, #0x03
	ADD	r1, #0x04
	ADD	r1, r0
	LDR	r2, =.LVBlankIRQ_TrackName
	LDMIA	r1, {r0-r1}
	STR	r1, [r2] @ Store new song name, and play it
	BL	ulc_Init
	B	.LMainLoop_ProcessState

/**************************************/

@ r0: &Tilemap
@ r1:  TileOfs
@ r2:  TilesX
@ r3:  TilesY
@ r4: [Temp]
@ r5: [Temp]

.Lmain_SetupRawTilemap:
	LSL	r4, r3, #0x06
	SUB	r4, #0x02
0:	MOV	r5, r3
1:	STRH	r1, [r0]     @ Store tile
	ADD	r0, #0x02*32 @ Move down
	ADD	r1, #0x01
	SUB	r5, #0x01
	BNE	1b
2:	SUB	r0, r4       @ Rewind tilemap, next column
	SUB	r2, #0x01
	BNE	0b
3:	BX	lr

/**************************************/
.balign 4
/**************************************/

@ r0: nSeconds
@ r1: Digits
@ r2: 1/60 [.37fxp]
@ r3: 1/10 [.35fxp]
@ ip: [Temp]
.thumb
.Lmain_GetMinsSecsTHUMB:
	BX	pc
	NOP
.arm
.Lmain_GetMinsSecs:
	UMULL	r1, ip, r2, r0        @ nMins -> ip [r2 free]
	MOV	ip, ip, lsr #0x05
	RSB	r1, ip, ip, lsl #0x04 @ nSeconds%60 -> r0
	SUB	r0, r0, r1, lsl #0x02
	CMP	ip, #99               @ Cap at 99:59
	UMULLLS	r2, r1, r3, ip        @ nMins/10 -> r1
	LDRHI	r1, =0x9959           @  NOTE: Invert the condition of everything else instead of branching. Should be VERY rare
	MOVLS	r1, r1, lsr #0x03
	ADDLS	r2, r1, r1, lsl #0x02 @ nMins%10 -> ip
	SUBLS	ip, ip, r2, lsl #0x01
	ORRLS	r1, ip, r1, lsl #0x04 @ MinsHi<<4 | MinsLo
	UMULLLS	r2, ip, r3, r0        @ nSecs/10 -> ip
	MOVLS	ip, ip, lsr #0x03
	ADDLS	r2, ip, ip, lsl #0x02 @ nSecs%10 -> r0
	SUBLS	r0, r0, r2, lsl #0x01
	ORRLS	r1, ip, r1, lsl #0x04 @ MinsHi<<12 | MinsLo<<8 | SecsHi<<4 | SecsLo
	ORRLS	r1, r0, r1, lsl #0x04
	BX	lr

/**************************************/

@ IRQ|FIQ disable. Uses fp to store cpsr

.thumb
.Lmain_DisableIRQTHUMB:
	BX	pc
	NOP
.arm
.Lmain_DisableIRQ:
	MRS	fp, cpsr
	ORR	ip, fp, #0xC0 @ Disable IRQ|FIQ
	MSR	cpsr, ip
	BX	lr
.thumb
.Lmain_EnableIRQTHUMB:
	BX	pc
	NOP
.arm
.Lmain_EnableIRQ:
	MSR	cpsr, fp @ Restore cpsr
	BX	lr

/**************************************/

@ RotMat[0] = {{0,-1},{+1,0}} (rotate 90deg, vertical flip)
@ RotMat[1] = {{0,+1},{+1,0}} (rotate 90deg)

.LBgDesignSprites_OAMData:
0:	.hword ((GRAPH_Y-32/2-GRAPH_H/2-1) & 0xFF) | 1<<8 | 1<<9 | 1<<10 | 1<<13 | 2<<14 @ Affine, Double, AlphaBlend, 8bpp, Tall
	.hword GRAPH_X | 3<<14 @ RotMat[0], 32x64
	.hword GRAPH_TILEOFS
	.hword 0
	.hword ((GRAPH_Y-32/2-GRAPH_H/2-1) & 0xFF) | 1<<8 | 1<<9 | 1<<10 | 1<<13 | 2<<14 @ Affine, Double, AlphaBlend, 8bpp, Tall
	.hword (GRAPH_X+64) | 3<<14 @ RotMat[0], 32x64
	.hword GRAPH_TILEOFS + 2*(32*64 / (8*8))
	.hword -0x0100
	.hword ((GRAPH_Y-32/2-GRAPH_H/2-1) & 0xFF) | 1<<8 | 1<<9 | 1<<10 | 1<<13 | 2<<14 @ Affine, Double, AlphaBlend, 8bpp, Tall
	.hword (GRAPH_X+128) | 3<<14 @ RotMat[0], 32x64
	.hword GRAPH_TILEOFS + 4*(32*64 / (8*8))
	.hword 0x0100
	.hword ((GRAPH_Y-32/2-GRAPH_H/2-1) & 0xFF) | 1<<8 | 1<<9 | 1<<10 | 1<<13 | 2<<14 @ Affine, Double, AlphaBlend, 8bpp, Tall
	.hword (GRAPH_X+192) | 3<<14 @ RotMat[0], 32x64
	.hword GRAPH_TILEOFS + 6*(32*64 / (8*8))
	.hword 0
0:	.hword (GRAPH_Y-32/2) | 1<<8 | 1<<9 | 1<<10 | 1<<13 | 2<<14 @ Affine, Double, AlphaBlend, 8bpp, Tall
	.hword GRAPH_X | 1<<9 | 3<<14 @ RotMat[1], 32x64
	.hword GRAPH_TILEOFS
	.hword 0
	.hword (GRAPH_Y-32/2) | 1<<8 | 1<<9 | 1<<10 | 1<<13 | 2<<14 @ Affine, Double, AlphaBlend, 8bpp, Tall
	.hword (GRAPH_X+64) | 1<<9 | 3<<14 @ RotMat[1], 32x64
	.hword GRAPH_TILEOFS + 2*(32*64 / (8*8))
	.hword 0x0100
	.hword (GRAPH_Y-32/2) | 1<<8 | 1<<9 | 1<<10 | 1<<13 | 2<<14 @ Affine, Double, AlphaBlend, 8bpp, Tall
	.hword (GRAPH_X+128) | 1<<9 | 3<<14 @ RotMat[1], 32x64
	.hword GRAPH_TILEOFS + 4*(32*64 / (8*8))
	.hword 0x0100
	.hword (GRAPH_Y-32/2) | 1<<8 | 1<<9 | 1<<10 | 1<<13 | 2<<14 @ Affine, Double, AlphaBlend, 8bpp, Tall
	.hword (GRAPH_X+192) | 1<<9 | 3<<14 @ RotMat[1], 32x64
	.hword GRAPH_TILEOFS + 6*(32*64 / (8*8))
	.hword 0
0:	.hword BUTTON_PREVSONG_Y    | 1<<14
	.hword BUTTON_PREVSONG_X    | 2<<14                   @ 32x16
	.hword BUTTON_PREVSONG_TILE | BUTTON_PREVSONG_PAL<<12
	.hword 0
	.hword BUTTON_PLAY_Y
	.hword BUTTON_PLAY_X        | 2<<14                   @ 32x32 (selected)
	.hword BUTTON_PLAY_TILE     | BUTTON_PLAY_PAL<<12
	.hword 0
	.hword BUTTON_PAUSE_Y       | 1<<14
	.hword BUTTON_PAUSE_X       | 2<<14                   @ 32x16
	.hword BUTTON_PAUSE_TILE    | BUTTON_PAUSE_PAL<<12
	.hword 0
	.hword BUTTON_NEXTSONG_Y    | 1<<14
	.hword BUTTON_NEXTSONG_X    | 2<<14                   @ 32x16
	.hword BUTTON_NEXTSONG_TILE | BUTTON_NEXTSONG_PAL<<12
	.hword 0
	.hword BUTTON_SLIDER_Y
	.hword BUTTON_SLIDER_X0                               @ 8x8
	.hword BUTTON_SLIDER_TILE   | BUTTON_SLIDER_PAL<<12
	.hword 0

.Lmain_ZeroWord: .word 0
.Lmain_SpriteDisableWord: .word 0x00000200

/**************************************/
.size   main, .-main
.global main
/**************************************/
.section .iwram, "ax", %progbits
.balign 4
/**************************************/

.arm
VBlankIRQ:
	MRS	ip, spsr
	STR	lr, [sp, #-0x04]! @ Save lr_irq
	MSR	cpsr, #0x1F       @ SYS mode, free to interrupt (TM1 interrupt is very important)
0:	STMFD	sp!, {r4-fp,ip,lr}
	LDR	r4, =ulc_State
0:	MOV	r0, #0x04000000
	MOV	r1, #0x1300
	ORR	r1, r1, #0x40          @ OBJ1D | BG0 | BG1 | OBJ
	STRH	r1, [r0], #0xF0
0:	LDR	fp, [r4, #0x08]        @ SoundFile -> r5+fp?
	LDRB	ip, [r4, #0x00]        @ RdBufIdx -> ip
	MOVS	r5, fp                 @  N: SrcOffs = 0 -> r5, SliderOffset = 0 -> fp
	MOVEQ	sl, #0x00
	BEQ	2f
1:	LDRH	r5, [r0, #0x0104-0xF0] @ Get SmpPos from timer -> r5
	ADD	fp, fp, #0x08
	LDMIA	fp, {r1,r8,sl}         @ nSmp = File.nSamp -> r1, RateHz -> r8, BlockSize -> sl
	LDR	r2, [r4, #0x04]        @ WrBufIdx | Pause<<1 | (nBlkRem-1)<<2 -> r2
	RSB	r5, r5, #0x010000      @ SmpPos = BlockSize - ((1<<16)-TimerVal)
	RSB	r5, r5, sl
	MLA	r5, sl, ip, r5         @ SmpPos += RdBufIdx*BlockSize (adjust for double buffer)
	MVN	r2, r2, lsr #0x02      @ -SmpRem = -nBlkRem*BlockSize + SmpPos -> r3 (nBlkRem is pre-decremented, so add 1)
	MLA	r3, r2, sl, r5
	ADD	r1, r1, sl, lsl #0x01  @ (nSmp += 2*BlockSize, for coding delays)
	SUB	r6, sl, #0x01          @ Add BlockSize rounding
	ADD	r1, r1, r6
	BIC	r1, r1, r6
	ADD	r6, r1, r3             @ SmpOfs = nSmp - SmpRem -> r6
.if 0 @ This overflows on long tracks
	MOV	r2, #BUTTON_SLIDER_X1+1 - BUTTON_SLIDER_X0
	MUL	r0, r6, r2
	BL	__aeabi_uidiv
	MOV	fp, r0                 @ Slider offset -> fp
.else
	MOV	r2, #BUTTON_SLIDER_X1+1 - BUTTON_SLIDER_X0
	UMULL	ip, lr, r6, r2         @ Lo -> ip, Hi -> lr
	MOV	fp, #0x00              @ SmpOfs*WIDTH/nSmp -> fp
.irp x, 6,5,4,3,2,1,0 @ Max quotient of 127
	SUBS	r2, ip, r1, lsl #\x    @ Inlined 64/32 division
	SBCS	r3, lr, r1, lsr #0x20 - \x
.if \x != 0 @ Remainder is not needed after we have the quotient
	MOVCS	ip, r2
	MOVCS	lr, r3
.endif
	ADDCS	fp, fp, #0x01 << \x
.endr
.endif
2:	MOV	r0, #0x07000000        @ Adjust time slider
	LDRH	r1, [r0, #0x08*BUTTON_SLIDER_OBJ + 0x02]
	ADD	fp, fp, #BUTTON_SLIDER_X0
	AND	r1, r1, #0xFE00
	ORR	r1, r1, fp
	STRH	r1, [r0, #0x08*BUTTON_SLIDER_OBJ + 0x02]

@ r4: &State
@ r5:  SmpPos    (No audio: 0)
@ r6:  SmpOfs    (No audio: Undefined)
@ r8:  RateHz    (No audio: Undefined)
@ sl:  BlockSize (No audio: 0)

.LVBlankIRQ_UpdateDisplayTime:
	LDR	r1, .LVBlankIRQ_MinsSecsLastUpdateSample
	LDR	r7, .LVBlankIRQ_MinsSecs
	CMP	sl, #0x00                   @ If we have a file, sl will contain the block size (which can never be 0)
	BEQ	.LVBlankIRQ_UpdateDisplayTime_NoUpdate
0:	SUBS	r3, r6, r1                  @ Get difference (in samples) since last update
	BCC	.LVBlankIRQ_UpdateDisplayTime_NoUpdate @ <- Race condition prevention where the sound buffer timer bursts in the middle of this update
	SUBS	r3, r3, r8                  @ Less than a second elapsed?
	BCC	.LVBlankIRQ_UpdateDisplayTime_NoUpdate
1:	ADD	r1, r1, r8                  @ Advance last update time by one second
	ADD	r7, r7, #0x01               @ Tick seconds (lo digit)
	AND	ip, r7, #0x0F
	CMP	ip, #0x09
	BLS	12f                         @ <- Happens 9/10 times, so take the branch when we can
11:	ADD	r7, r7, #(1<<4) - (10<<0)   @ Tick seconds (hi digit)
	AND	ip, r7, #0x0F<<4
	CMP	ip, #0x05<<4
	ADDHI	r7, r7, #(1<<8) - (6<<4)    @ Tick minutes (lo digit)
	AND	ip, r7, #0x0F<<8
	CMP	ip, #0x09<<8
	ADDHI	r7, r7, #(1<<12) - (10<<8)  @ Tick minutes (hi digit)
12:	SUBS	r3, r3, r8                  @ Update again? (should rarely - if ever - happen, but just in case)
	BCS	1b
2:	CMP	r7, #0x0A<<12               @ Overflow?
	LDRCS	r7, =0x9959                 @  Overflowed 99:59: MinsSecs="99:59"
	STR	r1, .LVBlankIRQ_MinsSecsLastUpdateSample
.LVBlankIRQ_UpdateDisplayTime_NoUpdate:

.LVBlankIRQ_DrawDisplayTime:
	LDR	r6, .LVBlankIRQ_MinsSecsLastUpdate @ Display time has not changed? Leave it alone
	STR	r7, .LVBlankIRQ_MinsSecs
	CMP	r6, r7
	BEQ	.LVBlankIRQ_DrawDisplayTime_NoRedraw
	STR	r7, .LVBlankIRQ_MinsSecsLastUpdate
0:	LDR	r0, =.Lmain_ZeroWord
	LDR	r1, =TIMEDISPLAY_CUR_TILEADR @ Clear Cur and End tiles
	LDR	r2, =(0x20*(TIMEDISPLAY_CUR_WIDTH_TILES*TIMEDISPLAY_CUR_HEIGHT_TILES + TIMEDISPLAY_END_WIDTH_TILES*TIMEDISPLAY_END_HEIGHT_TILES) / 4) | 1<<24
	SWI	0x0C0000
1:	MOV	r0, r7
	LDR	r1, =TIMEDISPLAY_CUR_TILEADR + 0x04*(TIMEDISPLAY_CUR_Y & 7)
	LDR	r2, =(TIMEDISPLAY_CUR_X & 7)
	BL	.LVBlankIRQ_DrawTimeDisplayData
	LDR	r0, .LVBlankIRQ_MinsSecs_End
	LDR	r1, =TIMEDISPLAY_END_TILEADR + 0x04*(TIMEDISPLAY_END_Y & 7)
	LDR	r2, =(TIMEDISPLAY_END_X & 7)
	BL	.LVBlankIRQ_DrawTimeDisplayData
.LVBlankIRQ_DrawDisplayTime_NoRedraw:

.LVBlankIRQ_DrawTrackName:
	LDR	ip, .LVBlankIRQ_TrackScroll
	LDR	r6, .LVBlankIRQ_TrackName
	LDR	r7, .LVBlankIRQ_TrackNameLastUpdate
	TST	ip, #0x80000000
	ADDEQ	r8, ip, #SONGDISPLAY_DELAYRATE @ Update delay or scroll as needed
	ADDNE	r8, ip, #SONGDISPLAY_SCROLLRATE
	STR	r8, .LVBlankIRQ_TrackScroll
.if SONGDISPLAY_SCROLLRATE < 0x400000 @ < 1px/frame means some frames will skip scrolling, meaning we do not need to redraw as often
	MOVNE	lr, ip, asr #0x1F-9   @ If in scroll mode, check for position changes
	CMPNE	lr, r8, asr #0x1F-9
.endif
	CMPEQ	r6, r7                @ If in delay mode (or scroll amount is the same), check for new track name
	BEQ	.LVBlankIRQ_DrawTrackName_NoRedraw
	STR	r6, .LVBlankIRQ_TrackNameLastUpdate
0:	LDR	r0, =.Lmain_ZeroWord
	LDR	r1, =SONGDISPLAY_TILEADR @ Clear tiles
	LDR	r2, =(0x20*(SONGDISPLAY_WIDTH_TILES*SONGDISPLAY_HEIGHT_TILES) / 4) | 1<<24
	SWI	0x0C0000
2:	SUBS	r8, r8, #0x80000000
	LDR	r0, =SONGDISPLAY_TILEADR + 0x04*(SONGDISPLAY_Y & 7)
	MOV	r1, #SONGDISPLAY_X & 7  @ x - Scroll -> r1
	SUBCS	r1, r1, r8, lsr #0x1F-9 @ Max scroll width of 512px before restarting
	LDR	r2, =MainFont           @ &Widths -> r2
	CMP	sl, #0x00               @ If playing, draw the 'playing' symbol at the start
	MOVNE	r3, #0x86-0x20
	BLNE	.LVBlankIRQ_DrawTrackName_DrawGlyph
3:	LDRB	r3, [r6], #0x01         @ Chr -> r3?
	CMP	r3, #0x00
	BEQ	4f
	SUB	r3, r3, #0x20
	CMP	r3, #0x83-0x20          @ Replace unknown characters with '?'
	MOVHI	r3, #'?'-0x20
	ADR	lr, 3b
	B	.LVBlankIRQ_DrawTrackName_DrawGlyph
4:	ADD	r1, r1, #0x40         @ Give the text an extra 64px of scroll before restarting
	BICS	r1, r1, r1, asr #0x1F @ Finished drawing the text? Restart
	SUBEQ	r1, r1, #SONGDISPLAY_SCROLLRATE
	STREQ	r1, .LVBlankIRQ_TrackScroll
.LVBlankIRQ_DrawTrackName_NoRedraw:

@ r4: &State
@ r5:  SmpOfs
@ sl:  BlockSize
.LVBlankIRQ_DrawGraph:
	CMP	sl, #0x00         @ On no file, just set the maximum block size
	MOVEQ	sl, #MAX_BLOCK_SIZE
	STR	sl, [sp, #-0x04]! @ BlockSize needs to be saved to wrap the buffer around
0:	ADR	r0, .LVBlankIRQ_GraphDataL
	LDR	r3, =ulc_OutputBuffer
	LDR	ip, =GRAPH_SMPSTRIDE_RCP
	MOV	r1, #(-GRAPH_W)<<24
	ADD	r2, r3, r5              @ Src -> r2
	ADD	r3, r3, sl, lsl #0x01   @ End -> r3
	LDR	r4, [r4, #0x08]
	MOVS	r5, r4
.if ULC_STEREO_SUPPORT
	LDRNEB	r5, [r4, #0x14]         @ nChan -> r5
.endif
	LDRNE	r4, [r4, #0x0C]         @ RateHz -> r4
.if ULC_STEREO_SUPPORT
	CMP	r5, #0x02
	ADDEQ	r1, r1, #0x01*MAX_BLOCK_SIZE*2 >> 8 @ Distance to right channel
.endif
	MUL	r4, ip, r4              @ Step = RateHz * SmpStrideReciprocal [.29fxp]
	MOV	r5, #0x00               @ PosMu (not important to track accurately across frames)
	ADR	r6, .LVBlankIRQ_DrawGraphsLUT_L
	ADD	r7, r6, #.LVBlankIRQ_DrawGraphsLUT_R - .LVBlankIRQ_DrawGraphsLUT_L
	LDR	r8, =0x06010000 + 0x20*GRAPH_TILEOFS
1:	ADD	r5, r5, r4              @ [PosMu += Step]
10:	LDRB	sl, [r2, r1, lsl #0x08] @ Abs[xR] -> sl
	LDRB	ip, [r0, #GRAPH_W]      @ Combine with old (nicer effect)
	MOVS	sl, sl, lsl #0x18
	EORMI	sl, sl, #0xFF<<24
	RSB	sl, ip, sl, lsr #0x17
	ADD	sl, ip, sl, asr #0x02
	STRB	sl, [r0, #GRAPH_W]
10:	LDRB	fp, [r2], r5, lsr #0x1D @ Abs[xL] -> fp, update position
	LDRB	ip, [r0]                @ Combine with old
	MOVS	fp, fp, lsl #0x18
	EORMI	fp, fp, #0xFF<<24
	RSB	fp, ip, fp, lsr #0x17
	ADD	fp, ip, fp, asr #0x02
	STRB	fp, [r0], #0x01
2:	BIC	r5, r5, #0x07<<29       @ Clear integer part
	CMP	r2, r3                  @ Wrap (happens rarely, so use a BL instead of inlining conditionals)
	BLCS	.LVBlankIRQ_DrawGraph_WrapBuffer
20:	RSB	sl, sl, sl, lsl #0x02   @ Normalization rescaling (3/16)
	RSB	fp, fp, fp, lsl #0x02
	MOV	sl, sl, lsr #0x04
	MOV	fp, fp, lsr #0x04
	CMP	sl, #GRAPH_H/2-1 + 16   @ The LUT includes 16 'extra' levels to clip without fading
	MOVHI	sl, #GRAPH_H/2-1 + 16
	CMP	fp, #GRAPH_H/2-1 + 16
	MOVHI	fp, #GRAPH_H/2-1 + 16
21:	LDR	ip, [r6, sl, lsl #0x02] @ Get 4 pixels
	LDR	lr, [r7, fp, lsl #0x02]
	SUBS	sl, sl, #0x04
	MOVCC	sl, #0x00
	SUBS	fp, fp, #0x04
	MOVCC	fp, #0x00
	ADD	r9, ip, lr, lsl #0x04   @ Combine Red + Blue*16
	LDR	ip, [r6, sl, lsl #0x02] @ Get next 4 pixels
	LDR	lr, [r7, fp, lsl #0x02]
	SUBS	sl, sl, #0x04
	MOVCC	sl, #0x00
	SUBS	fp, fp, #0x04
	MOVCC	fp, #0x00
	ADD	ip, ip, lr, lsl #0x04   @ Combine Red + Blue*16
	STMIA	r8, {r9,ip}             @ Store tile row
	ADD	r8, r8, #0x40           @ Next tile across
	ADDS	r5, r5, #0x01<<(32-(GRAPH_H_LOG2-1 - 3)) @ Half the graph is reflected, and we just did 8 pixels
	BCC	21b
3:	ADD	r8, r8, #0x08-0x40*(GRAPH_H/2/8) @ Rewind and move to next row
	TST	r8, #0x3F                        @ Wrap to next tile when crossing the boundary
	ADDEQ	r8, r8, #(GRAPH_H/2)*8-8*8
	ADDS	r1, r1, #0x01<<24                @ Next sample?
	BCC	1b

.LVBlankIRQ_Exit:
	LDMFD	sp!, {r3-fp,ip,lr} @ Pop BlockSize (into r3) from .LVBlankIRQ_DrawGraph. Saves having to "ADD sp, sp, #4"
	MSR	cpsr, #0x92     @ IRQ mode, IRQ-block (this is how we started this routine, saves having to push/pop cpsr)
	MSR	spsr, ip        @ Restore spsr
	LDR	pc, [sp], #0x04 @ Return to BIOS

.LVBlankIRQ_DrawGraph_WrapBuffer:
	LDR	ip, [sp, #0x00]
	SUB	r2, r2, ip, lsl #0x01 @ Rewind to start of buffer
	BX	lr

@ r0:  Data (SecLo | SecHi<<8 | MinLo<<16 | MinHi<<24)
@ r1: &TileData
@ r2:  x

.LVBlankIRQ_DrawTimeDisplayData:
	STMFD	sp!, {r4-r9,lr}
	LDR	r4, =TimeDisplayFont
	ADR	r7, .LVBlankIRQ_DrawTimeDisplayData_DrawGlyph_1bppUnpackLUT
0:	MOVS	r3, r0, lsr #0x0C     @ MinHi (only draw when not 0)
	LDRNE	r3, [r4, r3, lsl #0x02]
	BLNE	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x04
1:	MOV	r3, r0, lsr #0x08     @ MinLo
	AND	r3, r3, #0x0F
	LDR	r3, [r4, r3, lsl #0x02]
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x04
2:	LDR	r3, [r4, #0x04*10]    @ Colon
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x02
3:	MOV	r3, r0, lsr #0x04     @ SecHi
	AND	r3, r3, #0x0F
	LDR	r3, [r4, r3, lsl #0x02]
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x04
3:	AND	r3, r0, #0x0F         @ SecLo
	LDR	r3, [r4, r3, lsl #0x02]
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
4:	LDMFD	sp!, {r4-r9,pc}

@ r0: [Reserved]
@ r1: &TileData [read-only]
@ r2: x [read-only]
@ r3: PxData
@ r4: [Reserved]
@ r5: sL
@ r6: sR
@ r7: &PxLUT
@ r8: &TileData (access)
@ r9: [Scratch]
@ ip: [Scratch]
@ NOTE: Assumes cell dimensions of {4,5}

.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph:
	AND	r5, r2, #0x07 @ sL
	MOV	r5, r5, lsl #0x02
	RSB	r6, r5, #0x20 @ sR
	SUB	r5, r5, #0x05<<24
	MOV	r8, r2, lsr #0x03
	MOV	ip, #0x20*TIMEDISPLAY_CUR_HEIGHT_TILES
	MLA	r8, ip, r8, r1
1:	AND	ip, r3, #0x0F
	LDR	ip, [r7, ip, lsl #0x02]
	CMP	r6, #0x20
	LDRCC	r9, [r8, #0x20*TIMEDISPLAY_CUR_HEIGHT_TILES]
	MOV	r3, r3, lsr #0x04
	ORRCC	r9, r9, ip, lsr r6
	STRCC	r9, [r8, #0x20*TIMEDISPLAY_CUR_HEIGHT_TILES]
	LDR	r9, [r8]
	ADDS	r5, r5, #0x01<<24
	ORR	r9, r9, ip, lsl r5
	STR	r9, [r8], #0x04
	BCC	1b
2:	BX	lr

@ r0: &TileData
@ r1:  x [Width added on return]
@ r2: &Widths
@ r3:  Chr
@ r4: [Reserved]
@ r5: [Reserved]
@ r6: [Reserved]
@ r7:
@ r8:
@ r9:
@ sl: [Reserved]
@ fp:

.LVBlankIRQ_DrawTrackName_DrawGlyph:
	MOV	fp, r1, asr #0x03       @ Adjust for x tile, TileData -> fp
	MOV	ip, #0x20*SONGDISPLAY_HEIGHT_TILES
	MLA	fp, ip, fp, r0
	LDRB	ip, [r2, r3, lsr #0x01] @ Width -> ip
	TST	r3, #0x01
	MOVNE	ip, ip, lsr #0x04
	ANDEQ	ip, ip, #0x0F
	AND	r8, r1, #0x07           @ sL -> r8
	MOV	r8, r8, lsl #0x02
	RSB	r9, r8, #0x20           @ sR -> r9
	CMP	r1, #SONGDISPLAY_WIDTH_TILES*8
	ADD	r1, r1, ip              @ x += Width
	BXGE	lr                      @ Exit on x0 >= DisplayWidth
	CMP	r1, #0x00               @ Exit on x1 <= 0
	BXLE	lr
	CMP	r1, ip
	MOVLT	r8, #0x20               @ Disable LHS on x0 < 0
	CMP	r1, #SONGDISPLAY_WIDTH_TILES*8
	MOVGT	r9, #0x20               @ Disable RHS on x1 > DisplayWidth
	ADD	r3, r3, r3, lsl #0x03   @ Seek PxData -> r3 (assumes cell height of 9px)
	ADD	r3, r2, r3, lsl #0x02
	ADD	r3, r3, #0x34           @ 104 glyphs in the font, 1 nybble per glyph, padded to words
	SUB	r8, r8, #0x09<<16       @ 9px height
1:	LDR	r7, [r3], #0x04
	TST	r9, #0x20
	LDREQ	ip, [fp, #0x20*SONGDISPLAY_HEIGHT_TILES]
	ORREQ	ip, ip, r7, lsr r9
	STREQ	ip, [fp, #0x20*SONGDISPLAY_HEIGHT_TILES]
	TST	r8, #0x20
	LDREQ	ip, [fp]
	ORREQ	ip, ip, r7, lsl r8
	STREQ	ip, [fp]
	ADD	fp, fp, #0x04
	ADDS	r8, r8, #0x01<<16
	BCC	1b
2:	BX	lr

/**************************************/

.LVBlankIRQ_MinsSecs:                 .word  TIMEDISPLAY_NULL @ SecLo | SecHi<<4 | MinLo<<8 | MinHi<<12
.LVBlankIRQ_MinsSecs_End:             .word  TIMEDISPLAY_NULL
.LVBlankIRQ_MinsSecsLastUpdateSample: .word  0
.LVBlankIRQ_MinsSecsLastUpdate:       .word  0xFFFFFFFF @ Invalid, force redraw on start

.LVBlankIRQ_TrackScroll:         .word 0 @ ScrollOffs (>= 0: Delay, < 0: Scroll)
.LVBlankIRQ_TrackName:           .word .LSoundFiles_OriginSongName
.LVBlankIRQ_TrackNameLastUpdate: .word 0

.LVBlankIRQ_GraphDataL: .space 0x01*GRAPH_W
.LVBlankIRQ_GraphDataR: .space 0x01*GRAPH_W

.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph_1bppUnpackLUT:
	.word 0x00000000,0x00000001,0x00000010,0x00000011,0x00000100,0x00000101,0x00000110,0x00000111
	.word 0x00001000,0x00001001,0x00001010,0x00001011,0x00001100,0x00001101,0x00001110,0x00001111

.LVBlankIRQ_DrawGraphsLUT_L:
	.word 0x00000000,0x00000001,0x00000102,0x00010203,0x01020304,0x02030405,0x03040506,0x04050607
	.word 0x05060708,0x06070809,0x0708090A,0x08090A0B,0x090A0B0C,0x0A0B0C0D,0x0B0C0D0E,0x0C0D0E0F
	.word 0x0D0E0F0F,0x0E0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F
	.word 0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F
	.word 0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F
	.word 0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F,0x0F0F0F0F

.LVBlankIRQ_DrawGraphsLUT_R:
	.word 0x00000000,0x00000001,0x00000102,0x00010203,0x01020303,0x02030304,0x03030405,0x03040506 @ Floor[x * 13/15 + 0.5]
	.word 0x04050607,0x05060708,0x06070809,0x0708090A,0x08090A0A,0x090A0A0B,0x0A0A0B0C,0x0A0B0C0D
	.word 0x0B0C0D0D,0x0C0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D
	.word 0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D
	.word 0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D
	.word 0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D,0x0D0D0D0D

/**************************************/
.size VBlankIRQ, .-VBlankIRQ
/**************************************/

@ Music is split into volumes and bitrates
@ This hacky macro sequence is used to avoid having to rename everything for rebuilding
.equ BUILDVOLUME, 2
.macro INCLUDE_FILE x
	.incbin "source/music/128k/\x"
.endm

.section .rodata
.balign 4

SoundFiles:
.if BUILDVOLUME == 1
	.word 8 @ Number of tracks
	.word 10f, 11f
	.word 20f, 21f
	.word 30f, 31f
	.word 40f, 41f
	.word 50f, 51f
	.word 60f, 61f
	.word 70f, 71f
	.word 80f, 81f

	.LSoundFiles_OriginSongName:
	11: .asciz "B-Front & Adrenalize - Above Heaven"
	21: .asciz "Da Tweekaz - Jagermeister"
	31: .asciz "Da Tweekaz - People Against Porn (10 Years Mix)"
	41: .asciz "Da Tweekaz - Wodka"
	51: .asciz "Da Tweekaz & Code Black - Shake Ya Shimmy"
	61: .asciz "D-Block & S-te-Fan - Feel Inside"
	71: .asciz "D-Block & S-te-Fan - Primal Energy (Defqon.1 2020 Anthem)"
	81: .asciz "Eiffel 65 - Blue (Team Blue Radio Mix)"

	.balign 4; 10: INCLUDE_FILE "B-Front & Adrenalize - Above Heaven.ulc"
	.balign 4; 20: INCLUDE_FILE "Da Tweekaz - Jagermeister.ulc"
	.balign 4; 30: INCLUDE_FILE "Da Tweekaz - People Against Porn (10 Years Mix).ulc"
	.balign 4; 40: INCLUDE_FILE "Da Tweekaz - Wodka.ulc"
	.balign 4; 50: INCLUDE_FILE "Da Tweekaz & Code Black - Shake Ya Shimmy.ulc"
	.balign 4; 60: INCLUDE_FILE "D-Block & S-te-Fan - Feel Inside.ulc"
	.balign 4; 70: INCLUDE_FILE "D-Block & S-te-Fan - Primal Energy (Defqon.1 2020 Anthem).ulc"
	.balign 4; 80: INCLUDE_FILE "Eiffel 65 - Blue (Team Blue Radio Mix).ulc"
.endif
.if BUILDVOLUME == 2
	.word 7
	.word 10f, 11f
	.word 20f, 21f
	.word 30f, 31f
	.word 40f, 41f
	.word 50f, 51f
	.word 60f, 61f
	.word 70f, 71f

	.LSoundFiles_OriginSongName:
	11: .asciz "Mark With a K - See Me Now (Da Tweekaz Extended Remix)"
	21: .asciz "No!ze Freakz - Freedom"
	31: .asciz "Noisecontrollers - Crump (Ran-D Remix)"
	41: .asciz "Noisecontrollers - Revolution Is Here (Original Mix)"
	51: .asciz "Ran-D - Zombie"
	61: .asciz "Ran-D & ANDY SVGE - Armageddon"
	71: .asciz "Ran-D & Psyko Punkz Ft. K's Choice - Not An Addict"

	.balign 4; 10: INCLUDE_FILE "Mark With a K - See Me Now (Da Tweekaz Extended Remix).ulc"
	.balign 4; 20: INCLUDE_FILE "No!ze Freakz - Freedom.ulc"
	.balign 4; 30: INCLUDE_FILE "Noisecontrollers - Crump (Ran-D Remix).ulc"
	.balign 4; 40: INCLUDE_FILE "Noisecontrollers - Revolution Is Here (Original Mix).ulc"
	.balign 4; 50: INCLUDE_FILE "Ran-D - Zombie.ulc"
	.balign 4; 60: INCLUDE_FILE "Ran-D & ANDY SVGE - Armageddon.ulc"
	.balign 4; 70: INCLUDE_FILE "Ran-D & Psyko Punkz Ft. K's Choice - Not An Addict.ulc"
.endif
.if BUILDVOLUME == 3
	.word 9
	.word 10f, 11f
	.word 20f, 21f
	.word 30f, 31f
	.word 40f, 41f
	.word 50f, 51f
	.word 60f, 61f
	.word 70f, 71f
	.word 80f, 81f
	.word 90f, 91f

	.LSoundFiles_OriginSongName:
	11: .asciz "S3RL - Fan Service"
	21: .asciz "S3RL - Hentai"
	31: .asciz "S3RL - MTC"
	41: .asciz "S3RL - MTC2"
	51: .asciz "S3RL - Ravers MashUp"
	61: .asciz "S3RL feat Kayliana & MC Riddle - All That I Need"
	71: .asciz "S3RL ft. Gl!tch - Cherry Pop"
	81: .asciz "S3RL vs Auscore - Green Hills 2017"
	91: .asciz "The Script - Hall Of Fame (Dark Rehab Hardstyle Bootleg)"

	.balign 4; 10: INCLUDE_FILE "S3RL - Fan Service.ulc"
	.balign 4; 20: INCLUDE_FILE "S3RL - Hentai.ulc"
	.balign 4; 30: INCLUDE_FILE "S3RL - MTC.ulc"
	.balign 4; 40: INCLUDE_FILE "S3RL - MTC2.ulc"
	.balign 4; 50: INCLUDE_FILE "S3RL - Ravers MashUp.ulc"
	.balign 4; 60: INCLUDE_FILE "S3RL feat Kayliana & MC Riddle - All That I Need.ulc"
	.balign 4; 70: INCLUDE_FILE "S3RL ft. Gl!tch - Cherry Pop.ulc"
	.balign 4; 80: INCLUDE_FILE "S3RL vs Auscore - Green Hills 2017.ulc"
	.balign 4; 90: INCLUDE_FILE "The Script - Hall Of Fame (Dark Rehab Hardstyle Bootleg).ulc"
.endif
.if BUILDVOLUME == 4
	.word 1
	.word 10f, 11f

	.LSoundFiles_OriginSongName:
	11: .asciz "Q-Dance: Defqon.1 Weekend Festival 2019 - Sefa"

	.balign 4; 10: .incbin "source/music/Defqon.1 Weekend Festival 2019 - Sefa (105kbps).ulc"
.endif
.if BUILDVOLUME == 5
	.word 1
	.word 10f, 11f

	.LSoundFiles_OriginSongName:
	11: .asciz "Q-Dance: Reverze 2018 - Da Tweekaz"

	.balign 4; 10: .incbin "source/music/Reverze 2018 - Da Tweekaz (96kbps).ulc"
.endif
.if BUILDVOLUME == 6
	.word 1
	.word 10f, 11f

	.LSoundFiles_OriginSongName:
	11: .asciz "Q-Dance: Reverze 2018 - Ran-D"

	.balign 4; 10: .incbin "source/music/Reverze 2018 - Ran-D (105kbps).ulc"
.endif
.if BUILDVOLUME == 7
	.word 1
	.word 10f, 11f

	.LSoundFiles_OriginSongName:
	11: .asciz "Q-Dance: Reverze 2020 - D-Block & S-te-Fan"

	.balign 4; 10: .incbin "source/music/Reverze 2020 - D-Block & S-te-Fan (75kbps).ulc"
.endif
.if BUILDVOLUME == 8
	.word 1
	.word 10f, 11f

	.LSoundFiles_OriginSongName:
	11: .asciz "Q-Dance: X-Qlusive 2019 - Da Tweekaz, D-Block & S-te-Fan"

	.balign 4; 10: .incbin "source/music/X-Qlusive 2019 - Da Tweekaz, D-Block & S-te-Fan (79kbps).ulc"
.endif
.if BUILDVOLUME == 9
	.word 1
	.word 10f, 11f

	.LSoundFiles_OriginSongName:
	11: .asciz "S3RL - S3RL Always Presents\x7F"

	.balign 4; 10: .incbin "source/music/S3RL Always Presents (100kbps).ulc"
.endif

.size SoundFiles, .-SoundFiles

/**************************************/
/* EOF                                */
/**************************************/
