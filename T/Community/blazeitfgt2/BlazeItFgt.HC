#ifndef BLAZEITFGT_HC
#define BLAZEITFGT_HC

#exe {
#ifdef DEBUG
  Option(OPTf_WARN_UNUSED_VAR, ON);
  Option(OPTf_WARN_PAREN, ON);
  Option(OPTf_WARN_HEADER_MISMATCH, ON);
#endif
}

#include "Assets"
#include "PlayfieldDraw"
#include "PlayfieldInput"
#include "SceneEnd"
#include "Text"
#include "Title"
U0 Init() {
  Seed;

  InitSnd;
  gCtrl.quitGame = FALSE;
  gr.fp_draw_ms = NULL; // disable TempleOS cursor
  VectorInit(&gW.bullets, sizeof(Bullet));
  VectorInit(&gW.bulletsM, sizeof(Bullet));
  VectorInit(&gW.mobs, sizeof(Mob));
  VectorInit(&gW.lasers, sizeof(Laser));
  VectorInit(&gW.pickups, sizeof(Pickup));
  VectorInit(&gW.godWords, sizeof(GWord));

  // Init Particle Buffers
  VectorInit(&gW.debris, sizeof(Debris));
  VectorInit(&gW.debrisMesh, sizeof(DebrisMesh));
  VectorInit(&gW.explosion, sizeof(Particle));
  VectorInit(&gW.spawnFX, sizeof(Particle));

  // Init Collision Buffers
  VectorInit(&gW.collide, sizeof(CD2));
  VectorInit(&gW.collideMeta, sizeof(I32));
  VectorInit(&gW.cPolys, sizeof(CD2I32));
  VectorInit(&gW.cPolyIdx, sizeof(cPolyMeta));

  // Init Draw Buffers
  VectorInit(&gW.grDebris, sizeof(GrDebris));
  VectorInit(&gW.grMobs, sizeof(GrBuff));
  VectorInit(&gW.grGuns, sizeof(GrBuff));

  gW.player.thruster = MAlloc(gAssets.shipThruster->cnt*sizeof(CD3I32)*3);

  gW.task = Fs;
}

U0 InitPlayfield() {
  ResetGame();

  gW.task->draw_it = &DrawPlayfield;
  ActiveInput = &PlayfieldInput;
  ActiveUpdate = &UpdateGame;
}

U0 BlazeItFgt() {
  SettingsPush;
  Fs->text_attr=BLACK<<4+WHITE;
  MenuPush(
        "File {"
        "  Abort(,CH_SHIFT_ESC);"
        "  Exit(,CH_ESC);"
        "}"
        "Play {"
        "  Up(,'w');"
        "  Down(,'s');"
        "  Left(,'a');"
        "  Right(,'d');"
        "  Weapon1(,'1');"
        "  Weapon2(,'2');"
        "  KillSnd(,'m');"
        "}"
        );
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;
  GrPaletteSet(gr_palette_std);

  Fs->win_inhibit=WIG_TASK_DFT-WIF_SELF_FOCUS-WIF_SELF_BORDER-WIF_FOCUS_TASK_MENU;

  Init;
  F64 t_last = tS;
  sndJob = *Spawn(&SndTask,NULL,"Sound",mp_cnt-1,Fs);
  InitTitle;
  while (!gCtrl.quitGame) {
    t_now = tS;
    t_delta = t_now - t_last;
    t_last = t_now;
    switch (switchScene) {
      case SCENE_TITLE:
        switchScene = SCENE_NONE;
        InitTitle();
        break;
      case SCENE_INTRO:
        switchScene = SCENE_NONE;
        InitIntro();
        break;
      case SCENE_GAME:
        switchScene = SCENE_NONE;
        InitPlayfield();
        break;
      case SCENE_END:
        switchScene = SCENE_NONE;
        InitEnd();
        break;
    }
    (ActiveInput)();
    (ActiveUpdate)(t_delta);
    Refresh;
  }
  SetSnd(SND_QUIT);
  gW.task->draw_it = NULL;
  Refresh;
  MenuPop;
  DocClear;
  SettingsPop;
  gr.fp_draw_ms=&DrawStdMs;
  SndRst;
  GrPaletteSet(gr_palette_std);
}

#endif
