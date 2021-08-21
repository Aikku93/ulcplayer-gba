/**************************************/
.include "source/ulc/ulc_Specs.inc"
/**************************************/
@ Graphs to OBJ
@ Glyphs to BG0
@ Design to BG1
@ Backdrop to BG2 (if any)
/**************************************/
.equ GRAPH_X,   0 @ Pixels
.equ GRAPH_Y,  40 @ Pixels
.equ GRAPH_W, 240 @ Pixels
.equ GRAPH_H,  64 @ Pixels
.equ GRAPH_H_LOG2, 6
.equ GRAPH_TILEOFS, 42
.equ GRAPH_SMPSTRIDE_RCP, 9363 @ Floor[2^27 / (VBlankRate * GRAPH_W)]
/**************************************/
.equ BACKDROP_ENABLE,  1
.equ BACKDROP_PALOFS, 96
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
.equ TIMEDISPLAY_CUR_Y,  125 @ Pixels
.equ TIMEDISPLAY_END_X,  208 @ Pixels
.equ TIMEDISPLAY_END_Y,  125 @ Pixels
.equ TIMEDISPLAY_NULL,   0xBDEF7 @ "--:--" (1|Bh<<1) for MM:SS
/**************************************/
.equ BUTTON_PREVSONG_X,     10 @ Sprite offset (Pixels)
.equ BUTTON_PREVSONG_Y,    121
.equ BUTTON_PREVSONG_TILE,   0
.equ BUTTON_PREVSONG_PAL,   15
.equ BUTTON_PREVSONG_OBJ,    8 @ <- Hardcoded, do not change
.equ BUTTON_PLAY_X,         30 @ Sprite offset (Pixels)
.equ BUTTON_PLAY_Y,        114
.equ BUTTON_PLAY_TILE,       8
.equ BUTTON_PLAY_PAL,       14
.equ BUTTON_PLAY_OBJ,        9 @ <- Hardcoded, do not change
.equ BUTTON_PAUSE_X,        52 @ Sprite offset (Pixels)
.equ BUTTON_PAUSE_Y,       121
.equ BUTTON_PAUSE_TILE,     24
.equ BUTTON_PAUSE_PAL,      15
.equ BUTTON_PAUSE_OBJ,      10 @ <- Hardcoded, do not change
.equ BUTTON_NEXTSONG_X,     78 @ Sprite offset (Pixels)
.equ BUTTON_NEXTSONG_Y,    122
.equ BUTTON_NEXTSONG_TILE,  32
.equ BUTTON_NEXTSONG_PAL,   15
.equ BUTTON_NEXTSONG_OBJ,   11 @ <- Hardcoded, do not change
.equ BUTTON_SLIDER_X0,     130 @ Sprite offset (Pixels, min)
.equ BUTTON_SLIDER_X1,     203 @ Sprite offset (Pixels, max)
.equ BUTTON_SLIDER_Y,      125
.equ BUTTON_SLIDER_TILE,    40
.equ BUTTON_SLIDER_PAL,     15
.equ BUTTON_SLIDER_OBJ,     12 @ <- Hardcoded, do not change
/**************************************/
.equ DESIGN_CHARMAP,   0
.equ DESIGN_TILEMAP,  31
.equ DESIGN_TILEOFS,   0
.equ GLYPHS_CHARMAP,   0
.equ GLYPHS_TILEMAP,  30
.equ GLYPHS_TILEOFS, (98 + 0x0000) @ Set palette here (design uses 98 tiles)
.equ BACKDROP_CHARMAP, 1
.equ BACKDROP_TILEMAP, 29
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
.Lmain_LoadDesign:
0:	LDR	r0, =0x06000000 + DESIGN_TILEOFS*0x20
	LDR	r1, =BgDesign_Gfx
	BL	UnLZSS
0:	LDR	r0, =0x06000000 + DESIGN_TILEMAP*0x0800
	LDR	r1, =BgDesign_Map
	BL	UnLZSS
0:	LDR	r0, =BgDesign_Pal
	LDR	r1, =0x05000000
	LDR	r2, =(0x02 * 6*16 / 0x04)
	SWI	0x0C
0:	LDR	r0, =0x06010000
	LDR	r1, =BgDesignSprites_Gfx
	BL	UnLZSS
.if BACKDROP_ENABLE
	LDR	r0, =0x06000000 + BACKDROP_CHARMAP*0x4000
	LDR	r1,=Backdrop_Gfx
	BL	UnLZSS
	LDR	r0, =.Lmain_ZeroWord
	LDR	r1, =0x06000000 + BACKDROP_TILEMAP*0x0800
	LDR	r2, =(0x0800 / 0x04) | 1<<24
	SWI	0x0C
	LDR	r0, =0x06000000 + BACKDROP_TILEMAP*0x0800
	MOV	r1, #(64/8)
	LDR	r2, =0x0100
	LDR	r3, =0x0202
1:	SUB	r1, #((240/8)/2) << 4
10:	STRH	r2, [r0]
	ADD	r0, #0x02
	ADD	r2, r3
	ADD	r1, #0x01 << 4
	BCC	10b
	ADD	r0, #0x02 @ Skip edge past screen border
	SUB	r1, #0x01
	BNE	1b
.endif
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
	LDR	r1, =SONGDISPLAY_TILEOFS + 0x5000
	LDR	r2, =SONGDISPLAY_WIDTH_TILES
	LDR	r3, =SONGDISPLAY_HEIGHT_TILES
	BL	.Lmain_SetupRawTilemap
	LDR	r0, =0x06000000 + 0x0800*GLYPHS_TILEMAP + 0x02*(TIMEDISPLAY_CUR_X/8 + 32*(TIMEDISPLAY_CUR_Y/8))
	LDR	r1, =TIMEDISPLAY_CUR_TILEOFS + 0x5000
	LDR	r2, =TIMEDISPLAY_CUR_WIDTH_TILES
	LDR	r3, =TIMEDISPLAY_CUR_HEIGHT_TILES
	BL	.Lmain_SetupRawTilemap
	LDR	r0, =0x06000000 + 0x0800*GLYPHS_TILEMAP + 0x02*(TIMEDISPLAY_END_X/8 + 32*(TIMEDISPLAY_END_Y/8))
	LDR	r1, =TIMEDISPLAY_END_TILEOFS + 0x5000
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
.if BACKDROP_ENABLE
	LDR	r2, =(BACKDROP_CHARMAP<<2) | (1<<7) | (BACKDROP_TILEMAP<<8) | (1<<14) @ 8bpp, 256x256
	STRH	r2, [r0, #0x0C] @ BG2CNT
.endif
	LDR	r1, =(GRAPH_X+GRAPH_W) | GRAPH_X<<8
	LDR	r2, =(GRAPH_Y+GRAPH_H) | GRAPH_Y<<8
	LDR	r3, =0x003B003F
	STR	r1, [r0, #0x40]   @ Set a window to block backdrop from zooming outside of the frame
	STR	r2, [r0, #0x44]
	STR	r3, [r0, #0x48]
	LDR	r1, =0x10102741
	STR	r1, [r0, #0x50]   @ BG0 over BG0,BG1,BG2,BD (additive blend, OBJ is added via AlphaBlend flag)
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
	LDR	r3, .Lmain_SpriteDisableWord
	BCC	0f
	LDR	r3, .Lmain_Button_PrevSong_Attr0
0:	STR	r3, [r2, #0x08*BUTTON_PREVSONG_OBJ]
1:	LSR	r3, r1, #0x08+1 @ Next song? (SR)
	LDR	r3, .Lmain_SpriteDisableWord
	BCC	0f
	LDR	r3, .Lmain_Button_NextSong_Attr0
0:	STR	r3, [r2, #0x08*BUTTON_NEXTSONG_OBJ]
1:	LSR	r3, r1, #0x01+1 @ Pause? (B)
	LDR	r3, .Lmain_SpriteDisableWord
	BCC	0f
	LDR	r3, .Lmain_Button_PauseSong_Attr0
0:	STR	r3, [r2, #0x08*BUTTON_PAUSE_OBJ]
1:	LSR	r3, r1, #0x00+1 @ Play? (A)
	LDR	r3, .Lmain_SpriteDisableWord
	BCC	0f
	LDR	r3, .Lmain_Button_PlaySong_Attr0
0:	STR	r3, [r2, #0x08*BUTTON_PLAY_OBJ]

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
11:	LDRH	r2, [r5, #0x04] @ File.BlockSize -> r2
	LDR	r0, [r5, #0x08] @ File.nBlocks -> r0
	LDR	r1, [r5, #0x0C] @ File.RateHz -> r1
	MUL	r0, r2          @ nSamples = nBlocks*BlockSize -> r0
	BL	__aeabi_uidiv   @ nSeconds -> r0
	LDR	r2, =0x88888889 @ 1/60 [.37fxp] -> r2
	BL	.Lmain_GetMinsSecsTHUMB
	LDR	r2, =-SONGDISPLAY_SCROLLRATE
	STR	r1, [r6, #0x00] @  Reset 'elapsed' time = 0
	STR	r0, [r6, #0x04] @  Set 'end' time
	MOV	r1, #0x00
	STR	r1, [r6, #0x08] @  Reset MinsSecsLastUpdateSample = 0
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
@ r2: 1/60 [.37fxp]
@ Returns r0 = SecsLo|SecsHi<<5|MinsLo<<10|MinsHi<<15|HourLo<<20 (plus DRAW bits)
@         r1 = DRAW bits (ie. everything at 0:00:00)
.thumb
.Lmain_GetMinsSecsTHUMB:
	BX	pc
	NOP
.arm
.Lmain_GetMinsSecs:
	UMULL	r1, ip, r2, r0        @ nMins = nSecs/60 -> ip (this must be exact, hence 64bit multiply)
	MOV	ip, ip, lsr #0x05
	SUB	r0, r0, ip, lsl #0x06 @ nSecs -= nMins*60 -> r0
	ADD	r0, r0, ip, lsl #0x02
	ADD	r1, r0, r0, lsr #0x04 @ SecsHi = nSecs/10 (this is exact for nSecs <= 60)
	SUB	r1, r1, r1, lsr #0x02 @   nSecs * (1+2^-4)(1-2^-2)*2^-3
	MOV	r1, r1, lsr #0x03
	SUB	r0, r0, r1, lsl #0x03 @ SecsLo = nSecs - SecsHi*10
	SUB	r0, r0, r1, lsl #0x01
	ORR	r0, r0, r1, lsl #0x05 @ SecsLo | SecsHi<<5 -> r0
	ADD	r1, ip, #0x01         @ Hours = nMins/60 -> r1 (this is exact for nMins <= 600)
	ADD	r1, r1, r1, lsr #0x04 @   (nMins+1) * (1+2^-4)(1+2^-8)*2^-6
	ADD	r1, r1, r1, lsr #0x08
	MOV	r1, r1, lsr #0x06
	ORR	r0, r0, r1, lsl #0x14 @ SecsLo | SecsHi<<5 | HourLo<<20
	SUB	ip, ip, r1, lsl #0x06 @ nMins -= Hours*60
	ADD	ip, ip, r1, lsl #0x02
	ADD	r1, ip, ip, lsr #0x04 @ MinsHi = nMins/10 (this is exact for nMins <= 60)
	SUB	r1, r1, r1, lsr #0x02 @   nMins * (1+2^-4)(1-2^-2)*2^-3
	MOV	r1, r1, lsr #0x03
	SUB	ip, ip, r1, lsl #0x03 @ MinsLo = nMins - MinsHi*10
	SUB	ip, ip, r1, lsl #0x01
	ORR	r0, r0, ip, lsl #0x0A @ SecsLo|SecsHi<<5|MinsLo<<10|MinsHi<<15|HourLo<<20
	ORR	r0, r0, r1, lsl #0x0F
0:	MOV	r1, #0x01<<0 | 0x01<<5 @ Always enable SecsLo|SecsHi|MinsLo
	ORR	r1, r1, #0x01<<10
	TST	r0, #0x0F<<20          @ Enable HourLo (and passthrough MinsHi)
	ORRNE	r1, r1, #0x01<<20
	TSTEQ	r0, #0x0F<<15          @ Enable MinsHi
	ORRNE	r1, r1, #0x01<<15
	ORR	r0, r1, r0, lsl #0x01  @ Mix DRAW bits with TotalTime
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

.Lmain_Button_PrevSong_Attr0:
	.hword BUTTON_PREVSONG_Y    | 1<<14
	.hword BUTTON_PREVSONG_X    | 2<<14                   @ 32x16
	.hword BUTTON_PREVSONG_TILE | BUTTON_PREVSONG_PAL<<12
	.hword 0

.Lmain_Button_PlaySong_Attr0:
	.hword BUTTON_PLAY_Y
	.hword BUTTON_PLAY_X        | 2<<14                   @ 32x32
	.hword BUTTON_PLAY_TILE     | BUTTON_PLAY_PAL<<12
	.hword 0

.Lmain_Button_PauseSong_Attr0:
	.hword BUTTON_PAUSE_Y       | 1<<14
	.hword BUTTON_PAUSE_X       | 2<<14                   @ 32x16
	.hword BUTTON_PAUSE_TILE    | BUTTON_PAUSE_PAL<<12
	.hword 0

.Lmain_Button_NextSong_Attr0:
	.hword BUTTON_NEXTSONG_Y    | 1<<14
	.hword BUTTON_NEXTSONG_X    | 2<<14                   @ 32x16
	.hword BUTTON_NEXTSONG_TILE | BUTTON_NEXTSONG_PAL<<12
	.hword 0

.Lmain_Button_Slider_Attr0:
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
	MOV	r1, #0x3300 + BACKDROP_ENABLE*0x400
	ORR	r1, r1, #0x41          @ MODE1 | OBJ1D | BG0 | BG1 | BG2*BACKDROP_ENABLE | OBJ | WIN0
	STRH	r1, [r0], #0xF0
0:	LDR	fp, [r4, #0x08]        @ SoundFile -> r5+fp?
	LDRB	ip, [r4, #0x00]        @ RdBufIdx -> ip
	MOVS	r5, fp                 @  N: SrcOffs = 0 -> r5, SliderOffset = 0 -> fp
	MOVEQ	sl, #0x00
	BEQ	2f
1:	LDRH	r5, [r0, #0x0104-0xF0] @ Get SmpPos from timer -> r5
	LDMIB	fp, {r0,r1,r8}         @ File.BlockSize | x<<16 -> r0, File.nBlocks -> r1, File.RateHz -> r8
	MOV	sl, r0, lsl #0x10      @ BlockSize -> sl
	MOV	sl, sl, lsr #0x10
	MUL	r1, r1, sl             @ nSmp = nBlocks*BlockSize -> r1
	LDR	r2, [r4, #0x04]        @ WrBufIdx | Pause<<1 | (nBlkRem-1)<<2 -> r2
	RSB	r5, r5, #0x010000      @ SmpPos = BlockSize - ((1<<16)-TimerVal)
	RSB	r5, r5, sl
	MLA	r5, sl, ip, r5         @ SmpPos += RdBufIdx*BlockSize (adjust for double buffer)
	MVN	r2, r2, lsr #0x02      @ -SmpRem = -nBlkRem*BlockSize + SmpPos -> r3 (nBlkRem is pre-decremented, so add 1)
	MLA	r3, r2, sl, r5         @ NOTE: nBlkRem is not particularly reliable, but should be fine for display purposes
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
	ADD	r7, r7, #0x01<<1            @ Tick seconds (lo digit)
	AND	ip, r7, #0x0F<<1
	CMP	ip, #0x09<<1
	BLS	12f                         @ <- Happens 9/10 times, so take the branch when we can
11:	ADD	r7, r7, #(1<<6) - (10<<1)   @ Tick seconds (hi digit)
	AND	ip, r7, #0x0F<<6
	CMP	ip, #0x05<<6
	ADDHI	r7, r7, #(1<<11) - (6<<6)   @ Tick minutes (lo digit)
	AND	ip, r7, #0x0F<<11
	CMP	ip, #0x09<<11
	ADDHI	r7, r7, #(1<<16) - (10<<11) @ Tick minutes (hi digit)
	AND	ip, r7, #0x0F<<16
	CMP	ip, #0x05<<16
	ADDHI	r7, r7, #(1<<21) - (6<<16)  @ Tick hours
12:	SUBS	r3, r3, r8                  @ Update again? (should rarely - if ever - happen, but just in case)
	BCS	1b
2:	STR	r1, .LVBlankIRQ_MinsSecsLastUpdateSample
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
	MOVEQ	sl, #ULC_MAX_BLOCK_SIZE
	STR	sl, [sp, #-0x04]! @ BlockSize needs to be saved to wrap the buffer around
0:	ADR	r0, .LVBlankIRQ_GraphDataCur
	LDR	r3, =ulc_OutputBuffer
	LDR	ip, =GRAPH_SMPSTRIDE_RCP
	MOV	r1, #(-GRAPH_W)<<24
	ADD	r2, r3, r5              @ Src -> r2
	ADD	r3, r3, sl, lsl #0x01   @ End -> r3
	LDR	r4, [r4, #0x08]
	MOVS	r5, r4
.if ULC_STEREO_SUPPORT
	LDRNEH	r5, [r4, #0x10]         @ nChan -> r5
.endif
	LDRNE	r4, [r4, #0x0C]         @ RateHz -> r4
.if ULC_STEREO_SUPPORT
	CMP	r5, #0x02
	ADDEQ	r1, r1, #0x01*ULC_MAX_BLOCK_SIZE*2 >> 8 @ Distance to right channel
.endif
	MUL	r4, ip, r4              @ Step = RateHz * SmpStrideReciprocal [.27fxp]
	LDR	r6, =BGDesign_GraphLUT
	LDR	r8, =0x06010000 + 0x20*GRAPH_TILEOFS
	MOV	r4, r4, lsr #(27-12)    @ Step -> .12fxp, PosMu=0 to HI
.if BACKDROP_ENABLE
	MOV	r7, #0x00               @ LPEnergy -> r7
.endif
1:	ADD	r4, r4, r4, lsl #0x10   @ [PosMu += Step]
10:	LDRB	sl, [r2, r1, lsl #0x08] @ Abs[xR] -> sl
	LDRB	fp, [r2], r4, lsr #0x1C @ Abs[xL] -> fp, update position
	BIC	r4, r4, #0x0F<<28       @ Clear integer part of Pos
	CMP	r2, r3                  @ Wrap (happens rarely, so use a BL instead of inlining conditionals)
	BLCS	.LVBlankIRQ_DrawGraph_WrapBuffer
	TST	sl, #0x80               @ [Signed -> Unsigned]
	EORNE	sl, sl, #0xFF
	TST	fp, #0x80
	EORNE	fp, fp, #0xFF
	ADD	sl, sl, fp              @ [xR+xL -> .9fxp]
	LDRB	ip, [r0]
	LDRB	fp, [r0, #GRAPH_W]
	RSB	sl, ip, sl, lsr #0x01   @ Combine with old (nicer effect) -> sl (Red)
	ADD	sl, ip, sl, asr #0x02
	STRB	sl, [r0], #0x01
	RSB	ip, fp, sl              @ Add to integrated energy -> fp (Blue)
	ADD	fp, fp, ip, asr #0x03
	STRB	fp, [r0, #GRAPH_W-1]
.if BACKDROP_ENABLE
	MLA	r7, fp, fp, r7          @ Accumulate to "LP" energy
.endif
20:	RSB	sl, sl, sl, lsl #0x02   @ Normalization rescaling (Red = 3/8, Blue=3/4)
	RSB	fp, fp, fp, lsl #0x02
	MOV	sl, sl, lsr #0x03
	MOV	fp, fp, lsr #0x02
	CMP	sl, #GRAPH_H/2-1 + 16   @ The LUT includes 16 'extra' levels to clip without fading
	MOVHI	sl, #GRAPH_H/2-1 + 16
	CMP	fp, #GRAPH_H/2-1 + 16
	MOVHI	fp, #GRAPH_H/2-1 + 16
	ADD	fp, r6, fp, lsl #0x05
	ADD	sl, r6, sl, lsl #0x05
	ADD	sl, sl, #0x0600
21:	LDMIA	sl!, {r5,r9}          @ Get 8 pixels (red)
	LDMIA	fp!, {ip,lr}          @ Get 8 pixels (blue)
	ADD	r5, ip, r5, lsl #0x04 @ Combine Blue + Red*16
	ADD	r9, lr, r9, lsl #0x04
	STMIA	r8, {r5,r9}             @ Store tile row
	ADD	r8, r8, #0x40           @ Next tile across
	ADDS	r4, r4, #0x01<<(32-(GRAPH_H_LOG2-1 - 3)) @ Half the graph is reflected, and we just did 8 pixels
	BCC	21b
3:	ADD	r8, r8, #0x08-0x40*(GRAPH_H/2/8) @ Rewind and move to next row
	TST	r8, #0x3F                        @ Wrap to next tile when crossing the boundary
	ADDEQ	r8, r8, #(GRAPH_H/2)*8-8*8
	ADDS	r1, r1, #0x01<<24                @ Next sample?
	BCC	1b

.if BACKDROP_ENABLE

@ r7: LPEnergy
.LVBlankIRQ_RescaleBackdrop:
	LDR	r0, .LVBlankIRQ_BackdropEnergy @ Smooth out LPEnergy before doing anything
	SUBS	r7, r7, r0
	ADDHI	r7, r0, r7, asr #0x01          @ Attack is faster than decay
	ADDCC	r7, r0, r7, asr #0x03
	STRNE	r7, .LVBlankIRQ_BackdropEnergy
0:	MOV	r0, #0x0100
	SUBS	r1, r7, #0x010000
	SUBCS	r0, r0, r1, lsr #0x0E  @ Scale = 1 - Max[0,LPEnergy-ARBITRARY_OFFSET]/ARBITRAY_SCALE_FACTOR -> r0
	MOV	r1, #GRAPH_W/2+GRAPH_X @ Adjust XOFS/YOFS based on scaling (TONC bg_rotscale_ex() formula)
	MUL	r2, r0, r1
	MOV	r1, #GRAPH_H/2+GRAPH_Y
	MUL	r3, r0, r1
	RSB	r2, r2, #(GRAPH_W/2)<<8
	RSB	r3, r3, #(GRAPH_H/2)<<8
	MOV	r4, #0x04000000
	STRH	r0, [r4, #0x20]        @ Store PA = PD = Scale
	STRH	r0, [r4, #0x26]
	ADD	r4, r4, #0x28          @ Store XOFS,YOFS
	STMIA	r4, {r2-r3}

@ r7: LPEnergy
.LVBlankIRQ_BrightenBackdrop:
	MOV	r0, #0x14 @ Brightness = 20/32 + Energy/ARBITRAY_SCALE_FACTOR -> r0 [.5fxp]
	ADD	r0, r0, r7, lsr #0x0D
	CMP	r0, #0x20
	MOVHI	r0, #0x20
	LDR	r1, =0x03E07C1F
	MOV	r2, #0x05000000
	ADD	r2, r2, #0x02*BACKDROP_PALOFS
	LDR	r3, =BgDesign_Pal + 0x02*BACKDROP_PALOFS
	MOV	lr, #(256-BACKDROP_PALOFS) @ Assume palette runs until the end
1:	LDMIA	r3!, {r4,r6}
	AND	r5, r1, r4, ror #0x10 @ --g0--b1--r1
	AND	r4, r1, r4            @ --g1--b0--r0
	AND	r7, r1, r6, ror #0x10 @ --g2--b3--r3
	AND	r6, r1, r6            @ --g3--b2--r2
	MUL	r8, r4, r0
	MUL	r9, r5, r0
	MUL	sl, r6, r0
	MUL	fp, r7, r0
	AND	r4, r1, r8, lsr #0x05
	AND	r5, r1, r9, lsr #0x05
	AND	r6, r1, sl, lsr #0x05
	AND	r7, r1, fp, lsr #0x05
	ORR	r4, r4, r5, ror #0x10 @ b1g1r1b0g0r0
	ORR	r6, r6, r7, ror #0x10 @ b3g3r3b2g2r2
	STMIA	r2!, {r4,r6}
	SUBS	lr, lr, #0x04
	BNE	1b
.endif

.LVBlankIRQ_Exit:
	LDMFD	sp!, {r3-fp,ip,lr} @ Pop BlockSize (into r3) from .LVBlankIRQ_DrawGraph. Saves having to "ADD sp, sp, #4"
	MSR	cpsr, #0x92     @ IRQ mode, IRQ-block (this is how we started this routine, saves having to push/pop cpsr)
	MSR	spsr, ip        @ Restore spsr
	LDR	pc, [sp], #0x04 @ Return to BIOS

.LVBlankIRQ_DrawGraph_WrapBuffer:
	LDR	ip, [sp, #0x00]
	SUB	r2, r2, ip, lsl #0x01 @ Rewind to start of buffer
	BX	lr

.LVBlankIRQ_GraphDataCur: .space 0x01*GRAPH_W
.LVBlankIRQ_GraphDataAvg: .space 0x01*GRAPH_W

@ r0:  Data (SecLo | SecHi<<5 | MinLo<<10 | MinHi<<15 | Hour<<20) (DRAW bit in bit0 of each part, data in bit1..4)
@ r1: &TileData
@ r2:  x

.LVBlankIRQ_DrawTimeDisplayData:
	STMFD	sp!, {r4-sl,lr}
	LDR	r4, =TimeDisplayFont
	ADR	r7, .LVBlankIRQ_DrawTimeDisplayData_DrawGlyph_1bppUnpackLUT
	MOV	sl, #0x0F
1:	ANDS	r3, sl, r0, lsr #0x14+1 @ Hour?
	ADDCC	r2, r2, #(4+2)/2        @  N: Center-align (x += w/2)
	BCC	1f
10:	LDR	r3, [r4, r3, lsl #0x02] @ Draw hour
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x04
	LDR	r3, [r4, #0x04*10]      @ Draw colon
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x02
1:	ANDS	r3, sl, r0, lsr #0x0F+1 @ MinHi?
	SUBCC	r2, r2, #0x04/2         @  Center-align when not drawn
	LDRCS	r3, [r4, r3, lsl #0x02]
	BLCS	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x04
1:	AND	r3, sl, r0, lsr #0x0A+1 @ MinLo (assumed to always be drawn)
	LDR	r3, [r4, r3, lsl #0x02]
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x04
1:	LDR	r3, [r4, #0x04*10]      @ Colon (assumes minutes are always drawn)
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x02
1:	AND	r3, sl, r0, lsr #0x05+1 @ SecHi
	LDR	r3, [r4, r3, lsl #0x02]
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
	ADD	r2, r2, #0x04
1:	AND	r3, sl, r0, lsr #0x00+1 @ SecLo
	LDR	r3, [r4, r3, lsl #0x02]
	BL	.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph
2:	LDMFD	sp!, {r4-sl,pc}

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
	MOV	r8, r2, lsr #0x03
	SUB	r2, r2, #0x05<<24
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
	ADDS	r2, r2, #0x01<<24
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

.LVBlankIRQ_DrawTimeDisplayData_DrawGlyph_1bppUnpackLUT:
	.word 0x00000000,0x0000000F,0x000000F0,0x000000FF,0x00000F00,0x00000F0F,0x00000FF0,0x00000FFF
	.word 0x0000F000,0x0000F00F,0x0000F0F0,0x0000F0FF,0x0000FF00,0x0000FF0F,0x0000FFF0,0x0000FFFF

.if BACKDROP_ENABLE

.LVBlankIRQ_BackdropEnergy: .word 0

.endif

/**************************************/
.size VBlankIRQ, .-VBlankIRQ
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
.if BACKDROP_ENABLE
	.incbin "source/music/FrenchcoreMix/Backdrop.pal"
.endif
.size   BgDesign_Pal, .-BgDesign_Pal
.global BgDesign_Pal

/**************************************/

BgDesignSprites_Gfx:
	.incbin "source/res/BgDesignSprites.gfx.lz"
.size   BgDesignSprites_Gfx, .-BgDesignSprites_Gfx
.global BgDesignSprites_Gfx

.if BACKDROP_ENABLE

Backdrop_Gfx: .incbin "source/music/FrenchcoreMix/Backdrop.img.lz"
.size Backdrop_Gfx, .-Backdrop_Gfx

.endif

/**************************************/

BgDesignSprites_Pal:
	.incbin "source/res/BgDesignWaveform.pal"
	.incbin "source/res/BgDesignSprites.pal"
.size   BgDesignSprites_Pal, .-BgDesignSprites_Pal
.global BgDesignSprites_Pal

/**************************************/

BGDesign_GraphLUT:
	.incbin "source/res/BgDesignWaveformLUT.bin"
.size   BGDesign_GraphLUT, .-BGDesign_GraphLUT
.global BGDesign_GraphLUT

/**************************************/

.balign 4
.equ TIMEDISPLAYFONT_CELLH, 5
TimeDisplayFont:
	.word 0x00075557 @ 0
	.word 0x00072232 @ 1
	.word 0x00071747 @ 2
	.word 0x00074747 @ 3
	.word 0x00044755 @ 4
	.word 0x00074717 @ 5
	.word 0x00075717 @ 6
	.word 0x00044447 @ 7
	.word 0x00075757 @ 8
	.word 0x00074757 @ 9
	.word 0x00001010 @ :
	.word 0x00000700 @ -
.size   TimeDisplayFont, .-TimeDisplayFont
.global TimeDisplayFont

/**************************************/

.balign 4
.equ MAINFONT_CELLH, 9
MainFont:
1:	.word 0x26866433,0x43536633,0x66666666,0x63433366 @ Glyph widths (1 nybble per glyph)
	.word 0x55555558,0x56655525,0x65565555,0x54343566
	.word 0x55555553,0x55625325,0x65555455,0x66424555
	.word 0x99998888
2:	.incbin "source/res/MainFont.gfx"
.size   MainFont, .-MainFont
.global MainFont

/**************************************/

SoundFiles:
	.word 19 @ Number of tracks
	.word  10f,  11f
	.word  20f,  21f
	.word  30f,  31f
	.word  40f,  41f
	.word  50f,  51f
	.word  60f,  61f
	.word  70f,  71f
	.word  80f,  81f
	.word  90f,  91f
	.word 100f, 101f
	.word 110f, 111f
	.word 120f, 121f
	.word 130f, 131f
	.word 140f, 141f
	.word 150f, 151f
	.word 160f, 161f
	.word 170f, 171f
	.word 180f, 181f
	.word 190f, 191f

	.LSoundFiles_OriginSongName:
	 11: .asciz "Rayvolt - And We Run"
	 21: .asciz "Vertex - Run It Up"
	 31: .asciz "Vertex - Get Down"
	 41: .asciz "Damian Ray - In My Brain (Rayvolt Remix)"
	 51: .asciz "Vertex - Collective Paranoia"
	 61: .asciz "Sefa & Mr. Ivex - LSD Problem"
	 71: .asciz "Re-Style & Vertex - Shadow World"
	 81: .asciz "Sefa - Schopenhauer"
	 91: .asciz "Dr. Peacock - Vive La Volta (Sefa Remix)"
	101: .asciz "Juju Rush - Catching Fire"
	111: .asciz "Vertex - Let It Roll"
	121: .asciz "Re-Style - Towards the Sun (Vertex & Rayvolt Remix)"
	131: .asciz "Toto - Africa (Rayvolt Remix)"
	141: .asciz "Rayvolt - Wellerman"
	151: .asciz "Vicetone & Tony Igy - Astronomia (Rayvolt Remix)"
	161: .asciz "Re-Style & Korsakoff - Leap of Faith"
	171: .asciz "Death Punch - Nowhere Warm"
	181: .asciz "Dr. Peacock & Sefa - Incoming"
	191: .asciz "Re-Style & Runeforce - A New Dawn"

	.balign 4;  10: .incbin "source/music/FrenchcoreMix/Rayvolt - And We Run.ulc"
	.balign 4;  20: .incbin "source/music/FrenchcoreMix/Vertex - Run It Up.ulc"
	.balign 4;  30: .incbin "source/music/FrenchcoreMix/Vertex - Get Down.ulc"
	.balign 4;  40: .incbin "source/music/FrenchcoreMix/Damian Ray - In My Brain (Rayvolt Remix).ulc"
	.balign 4;  50: .incbin "source/music/FrenchcoreMix/Vertex - Collective Paranoia.ulc"
	.balign 4;  60: .incbin "source/music/FrenchcoreMix/Sefa & Mr. Ivex - LSD Problem.ulc"
	.balign 4;  70: .incbin "source/music/FrenchcoreMix/Re-Style & Vertex - Shadow World.ulc"
	.balign 4;  80: .incbin "source/music/FrenchcoreMix/Sefa - Schopenhauer.ulc"
	.balign 4;  90: .incbin "source/music/FrenchcoreMix/Dr. Peacock - Vive La Volta (Sefa Remix).ulc"
	.balign 4; 100: .incbin "source/music/FrenchcoreMix/Juju Rush - Catching Fire.ulc"
	.balign 4; 110: .incbin "source/music/FrenchcoreMix/Vertex - Let It Roll.ulc"
	.balign 4; 120: .incbin "source/music/FrenchcoreMix/Re-Style - Towards the Sun (Vertex & Rayvolt Remix).ulc"
	.balign 4; 130: .incbin "source/music/FrenchcoreMix/Toto - Africa (Rayvolt Remix).ulc"
	.balign 4; 140: .incbin "source/music/FrenchcoreMix/Rayvolt - Wellerman.ulc"
	.balign 4; 150: .incbin "source/music/FrenchcoreMix/Vicetone & Tony Igy - Astronomia (Rayvolt Remix).ulc"
	.balign 4; 160: .incbin "source/music/FrenchcoreMix/Re-Style & Korsakoff - Leap of Faith.ulc"
	.balign 4; 170: .incbin "source/music/FrenchcoreMix/Death Punch - Nowhere Warm.ulc"
	.balign 4; 180: .incbin "source/music/FrenchcoreMix/Dr. Peacock & Sefa - Incoming.ulc"
	.balign 4; 190: .incbin "source/music/FrenchcoreMix/Re-Style & Runeforce - A New Dawn.ulc"

.size SoundFiles, .-SoundFiles

/**************************************/
/* EOF                                */
/**************************************/
