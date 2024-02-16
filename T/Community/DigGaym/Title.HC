#ifndef TITLE_HC
#define TITLE_HC

#include "World"
#include "UI"
/*
#include "Px/CrunkLord"
#include "Px/NewScum"
#include "Px/TitleDigGaym1"
#include "Px/TitleDigGaym2"
#include "Px/TitleDigGaym3"
#include "Px/TitleDigGaym4"
#include "Px/TitleDigGaym5"
#include "Levels/LevelTitle"
*/

extern World gW;
extern UI gUI;
extern U0 QuitGame();
extern U0 InitGame();
extern U0 InitSandbox();
extern I8 noiseMap[640*640];
extern U8 tex1[640*480];

F64 title_t;
TextData txtPresents;
txtPresents.timer = 0;
txtPresents.speed = 8;
txtPresents.str = "PRESENTS";

TextData txtEnding0;
txtEnding0.speed = 32;
txtEnding0.str = "YOU COMPLETED ALL THE STAGES!";

TextData txtEnding1;
txtEnding1.speed = 32;
txtEnding1.str = "THANK YOU FOR PLAYING MY GAME.

FEW PEOPLE WILL EVER PLAY THIS GAME,
EVEN FEWER WILL COMPLETE ALL THE STAGES.
YOU HAVE EVERY RIGHT TO CALL YOURSELF AN
ELITE TEMPLEOS GAMER.

I SPENT HUNDREDS OF HOURS MAKING THIS GAME
KNOWING THE MOST I COULD EXPECT IS FOR
PEOPLE TO LOOK AT SCREENSHOTS AND SAY:

   \"HUH, NEAT\".

I CREATE GAMES FOR FUN, I CONSIDER IT AN
ARTISTIC EFFORT. AS TERRY SAID:

   \"MAKE GAMES, DONT PLAY THEM\".";

PxData *TitleDigGaymFrames[5] = {&TitleDigGaym1,&TitleDigGaym2,&TitleDigGaym3,&TitleDigGaym4,&TitleDigGaym5};
Anim animDigGaym = {0, 5, 0.33, 0.33, TitleDigGaymFrames, NULL};
CD2 digGaymPos;
Bool digDropped;
Bool clicked;
Button buttonGame;
Button buttonSandbox;
Button buttonEndMainMenu;

U0 DrawNoise(U8 *dst, U8 *src, I64 ts) {
  I64 y, x, tx, ty;
  for (y=0; y<480; y++) {
    for (x=0; x<640; x++) {
      I64 xx = x + ts;//%640;
      tx = (xx + gW.cam.x + 320)%640;
      ty = (y + gW.cam.y + 240)%640;
      xx = x + noiseMap[ty*640+tx];
      if (xx >= 640)
        xx = 640;
      else if (xx < 0)
        xx = 0;
      if (src[y*640+xx] != TRANSPARENT)
        dst[y*640+x] = tex1[y*640+xx];
    }
  }
}

public U0 UpdateTitle(F64 delta) {
  // Input
  if (clicked) {
    gUI.mouse.x = ms.pos.x;
    gUI.mouse.y = ms.pos.y - 8;
    if (HandleButton(&buttonGame, &gCtrl)) {
      InitGame();
      return;
    }
    if (HandleButton(&buttonSandbox, &gCtrl)) {
      InitSandbox();
      return;
    }
  } else if (gCtrl.mLDown) {
    clicked = TRUE;
  }

  // Update Timers
  title_t += delta;

  // Update Text
  txtPresents.timer += delta;

  UpdateAnim(&animDigGaym, delta);

  if (!digDropped) {
    digGaymPos.y += 800 * delta;
    if (digGaymPos.y > 300) {
      digGaymPos.y = 300;
      digDropped = TRUE;
      I64 i;
      for (i=0; i<28; i++) {
        DebrisAddRand(&gW.debrisEarth, digGaymPos.x+i*16, digGaymPos.y+58, 64, 8);
      }
    }
  }

  // Update Debris
  Debris *debris = gW.debrisEarth.d;
  for (i=0; i<gW.debrisEarth.len; i++) {
    debris[i].vel.y += 128.0 * delta;
    debris[i].pos.x += debris[i].vel.x * delta;
    debris[i].pos.y += debris[i].vel.y * delta;
/*
    if (debris[i].pos.x+320 <= gW.cam.x ||
        debris[i].pos.x-320 >= gW.cam.x ||
        debris[i].pos.y+240 <= gW.cam.y ||
        debris[i].pos.y-240 >= gW.cam.y ) {
      VectorDel(&gW.debrisEarth, i--);
    }
*/
  }
}

U0 DrawTitle(CTask*, CDC *dc) {
  CD2I32 cam;
  cam.x = ToI64(gW.cam.x);
  cam.y = ToI64(gW.cam.y);
  DrawBackground(dc->body, cam);
  DrawTiles(dc->body, &gW.cam, &gW.level);

  I64 scumY = 8;
  PxBlot(dc->body, &NewScum, 176, scumY);

  scumY += 150;
  MemSet(tex1, TRANSPARENT, 640*480);
  PxBlot(tex1, &CrunkLord, 101, scumY);
  I64 ts = tS*30;
  DrawNoise(dc->body, tex1, ts);

  DrawTextBounce(dc->body, &fontBig, &txtPresents, 256, scumY+68);
  DrawAnim(dc, &animDigGaym, ToI64(digGaymPos.x), ToI64(digGaymPos.y), FALSE);
  DrawText(dc->body, &fontBig, "LICENSE: MIT+NIGGER", 4, 452);
  DrawText(dc->body, &fontBig, "VER. 0.420", 504, 452);

  // Draw Debris
  I64 i;
  Debris *debris = gW.debrisEarth.d;
  for (i=0; i<gW.debrisEarth.len; i++) {
    PxBlot(dc->body, &tEarthDebris, debris[i].pos.x, debris[i].pos.y);
  }

  if (clicked) {
    DrawButton(dc->body, &buttonGame);
    DrawButton(dc->body, &buttonSandbox);
    PxBlot(dc->body, &CursorReg, gUI.mouse.x, gUI.mouse.y);
  }
}

public U0 TitleInput() {
  I64 msg, ch, sc;
  gCtrl.mLDown = FALSE;
  gCtrl.mLUp = FALSE;
  gCtrl.mRDown = FALSE;
  gCtrl.mRUp = FALSE;
  while (TRUE) {
    msg = ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN|1<<MSG_MS_L_DOWN, Fs);
    switch (msg) {
      case MSG_KEY_DOWN:
        if (ch) {
          switch (ch) {
            case CH_SPACE:
            case CH_ESC:
              clicked = TRUE;
              break;
            case CH_SHIFT_ESC:
              QuitGame;
              return;
            default:
              break;
          }
        }
        break;
      case MSG_MS_L_DOWN:
        gCtrl.mLDown = TRUE;
        break;
      case MSG_MS_L_UP:
        gCtrl.mLUp = TRUE;
        break;
      case MSG_MS_R_DOWN:
        gCtrl.mRDown = TRUE;
        break;
      case MSG_MS_R_UP:
        gCtrl.mRUp = TRUE;
        break;
      default:
        return;
    }
  }
}

public U0 InitTitle() {
  digDropped = FALSE;
  clicked = FALSE;

  // Setup Camera
  gW.cam.x = 320;
  gW.cam.y = 812;

  // Setup Level
  gW.activeLvl = &LevelTitle;
  LoadMap(&gW.level, gW.activeLvl, noiseMap);

  title_t = 0;
  digGaymPos.x = 100;
  digGaymPos.y = 0;

  // Reset Vectors
  gW.debrisEarth.len = 0;

  /* Init Function Pointers */
  gW.ActiveInput = &TitleInput;
  gW.ActiveUpdate = &UpdateTitle;
  Fs->draw_it = &DrawTitle;
}

U0 UpdateEndScreen(F64 delta) {
  // Input
  if (clicked) {
    gUI.mouse.x = ms.pos.x;
    gUI.mouse.y = ms.pos.y - 8;
    if (HandleButton(&buttonEndMainMenu, &gCtrl)) {
      InitTitle();
      return;
    }
  } else if (gCtrl.mLDown) {
    clicked = TRUE;
  }

  // Update Text
  txtEnding0.timer += delta;
  txtEnding1.timer += delta;
  gW.cam.x += delta*2;
}

U0 DrawEndScreen(CTask*, CDC *dc) {
  CD2I32 cam;
  cam.x = ToI64(gW.cam.x);
  cam.y = ToI64(gW.cam.y);
  DrawBackground(dc->body, cam);
//  DrawTiles(dc->body, &gW.cam, &gW.level);

  MemSet(tex1, TRANSPARENT, 640*480);
  PxBlot(tex1, &CrunkLord, 101, 406);
  I64 ts = tS*30;
  DrawNoise(dc->body, tex1, ts);

  DrawTextBounce(dc->body, &fontBig, &txtEnding0, 320-GetTextWidth(&fontBig, txtEnding0.str)>>1, 16);
  DrawTextBounce(dc->body, &fontBig, &txtEnding1, 8, 64);

  if (clicked) {
    PxBlot(dc->body, &CursorReg, gUI.mouse.x, gUI.mouse.y);
    DrawButton(dc->body, &buttonEndMainMenu);
/*
    DrawButton(dc->body, &buttonSandbox);
*/
  }
}

U0 InitTitleButtons() {
  I32 buttonPosX = 320 - 200>>1;
  ButtonNew(&buttonGame, buttonPosX, 364, 200, fontBig.y+8, "GAME",
            SWEET_GREEN, SWEET_GREEN_DK, SWEET_BLACK,
            SWEET_GREEN_DK, SWEET_GREEN_DK, SWEET_WHITE);
  ButtonNew(&buttonSandbox, buttonPosX, 364+fontBig.y+8+2, 200, fontBig.y+8, "SANDBOX",
            SWEET_GREEN, SWEET_GREEN_DK, SWEET_BLACK,
            SWEET_GREEN_DK, SWEET_GREEN_DK, SWEET_WHITE);
  ButtonNew(&buttonEndMainMenu, buttonPosX, 374, 200, fontBig.y+8, "MAIN MENU",
            SWEET_GREEN, SWEET_GREEN_DK, SWEET_BLACK,
            SWEET_GREEN_DK, SWEET_GREEN_DK, SWEET_WHITE);
}

U0 InitEndScreen() {
  clicked = FALSE;
  txtEnding0.timer = 0;
  txtEnding1.timer = 0;
  gW.cam.x = 320;
  gW.cam.y = 812;
  title_t = 0;

  /* Init Function Pointers */
  gW.ActiveInput = &TitleInput;
  gW.ActiveUpdate = &UpdateEndScreen;
  Fs->draw_it = &DrawEndScreen;
}

#endif
