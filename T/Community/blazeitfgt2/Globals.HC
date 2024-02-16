#ifndef GLOBALS_HC
#define GLOBALS_HC

#include "World"
#include "Assets"
#include "GrFast"

World gW;
Assets gAssets;
MemSet(&gW, 0, sizeof(World));
MemSet(&gAssets, 0, sizeof(Assets));

// Init Assets
if (AssetsInit(&gAssets)) {
  Exit();
}

U0 (*ActiveInput)();
U0 (*ActiveUpdate)(F64 delta);

I32 gDepthBuf[SCR_W*SCR_H];
U8 *backbuffer = MAlloc(640*480);
F64 t_now, t_delta;
F64 death_ttl;
F64 blur_ttl;
F64 firing_ttl;
F64 bomb_ttl;
CD2I32 bombPos;

#define SCENE_NONE  0
#define SCENE_TITLE 1
#define SCENE_INTRO 2
#define SCENE_GAME  3
#define SCENE_END   4
I32 switchScene = SCENE_NONE;

CJob *sndJob;

class Controls {
  CD2 cVel;
  Bool firing;
  Bool bombPressed;
  Bool bombDown;
  Bool quitGame;
  Bool upDown;
  Bool upPressed;
  //Bool upReleased;
  Bool downDown;
  Bool downPressed;
  //Bool downReleased;
  Bool acceptDown;
  Bool acceptPressed;
} gCtrl;
MemSet(&gCtrl, 0, sizeof(Controls));

CBGR48 game_palette[COLORS_NUM]={
0x000000000000,0x03000000FFFF,0x30300303D9D9,0x00009898DCDC,
0x272727272727,0x5D5D5D5D5D5D,0xEAEA32323C3C,0x89891E1E2B2B,
0xD3D3FCFC7E7E,0x5A5AC5C54F4F,0x1E1E6F6F5050,0xF3F38989F5F5,
0x7A7A0909FAFA,0xFFFFC8C82525,0xFFFFC8002500,0xFFFFFFFFFFFF};

U0 QuitGame() {
  gCtrl.quitGame = TRUE;
}
#endif
