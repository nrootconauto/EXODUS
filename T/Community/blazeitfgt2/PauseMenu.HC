#ifndef PAUSEMENU_HC
#define PAUSEMENU_HC

#include "Globals"
//#include "Title"

#define PAUSESCR_X 192
#define PAUSESCR_Y 8
#define PAUSESCR_STR_X PAUSESCR_X+20
#define PAUSESCR_STR_Y PAUSESCR_Y+24

I32 menuSelection;
I32 menuConfirmation;

U0 InitPauseMenu() {
  if (!gW.pauseMenu) {
    gW.pauseMenu = TRUE;
    menuSelection = 0;
    menuConfirmation = -1;
  }
}

U0 DrawPauseMenu(CDC *dc) {
  CColorROPU32 mask;
  mask.c0.rop = 15;
  mask.c0.color = 14;
  if (gCtrl.downPressed) {
    if (menuConfirmation >= 0) {
      menuConfirmation++;
      menuConfirmation %= 2;
    } else {
      menuSelection++;
      menuSelection %= 3;
    }
  } else if (gCtrl.upPressed) {
    if (menuConfirmation >= 0) {
      menuConfirmation--;
      if (menuConfirmation < 0)
        menuConfirmation = 1;
    } else {
      menuSelection--;
      if (menuSelection < 0)
        menuSelection = 2;
    }
  }
  if (gCtrl.acceptPressed) {
    if (menuConfirmation >= 0) {
      switch (menuConfirmation) {
        case 0:
          menuConfirmation = -1;
          break;
        case 1:
          switch (menuSelection) {
            case 1:
              switchScene = SCENE_TITLE;
              break;
            case 2:
              QuitGame();
              break;
          }
          break;
      }
    } else {
      switch (menuSelection) {
        case 0:
          gW.pauseMenu = FALSE;
          break;
        case 1:
        case 2:
          menuConfirmation = 0;
          break;
      }
    }
  }

  PxBlot(dc->body,gAssets.PauseScreen, PAUSESCR_X, PAUSESCR_Y);
  if (menuConfirmation >= 0) {
    U8 *confirmStr;
    if (menuSelection == 1)
      confirmStr = "Confirm Main Menu";
    else
      confirmStr = "Confirm Quit";
    switch (menuConfirmation) {
      case 0:
        DrawText(dc->body,&gAssets.fontKapel2x,confirmStr,PAUSESCR_STR_X,PAUSESCR_STR_Y);
        DrawTextMask(dc->body,&gAssets.fontKapel2x,"NO",PAUSESCR_STR_X,PAUSESCR_STR_Y+32,mask);
        DrawText(dc->body,&gAssets.fontKapel2x,"YES",PAUSESCR_STR_X,PAUSESCR_STR_Y+32+32);
        break;
      case 1:
        DrawText(dc->body,&gAssets.fontKapel2x,confirmStr,PAUSESCR_STR_X,PAUSESCR_STR_Y);
        DrawText(dc->body,&gAssets.fontKapel2x,"NO",PAUSESCR_STR_X,PAUSESCR_STR_Y+32);
        DrawTextMask(dc->body,&gAssets.fontKapel2x,"YES",PAUSESCR_STR_X,PAUSESCR_STR_Y+32+32,mask);
        break;
    }
  } else {
    switch (menuSelection) {
      case 0:
        DrawTextMask(dc->body,&gAssets.fontKapel2x,"RESUME",PAUSESCR_STR_X,PAUSESCR_STR_Y,mask);
        DrawText(dc->body,&gAssets.fontKapel2x,"MAIN MENU",PAUSESCR_STR_X,PAUSESCR_STR_Y+32);
        DrawText(dc->body,&gAssets.fontKapel2x,"QUIT",PAUSESCR_STR_X,PAUSESCR_STR_Y+32+32);
        break;
      case 1:
        DrawText(dc->body,&gAssets.fontKapel2x,"RESUME",PAUSESCR_STR_X,PAUSESCR_STR_Y);
        DrawTextMask(dc->body,&gAssets.fontKapel2x,"MAIN MENU",PAUSESCR_STR_X,PAUSESCR_STR_Y+32,mask);
        DrawText(dc->body,&gAssets.fontKapel2x,"QUIT",PAUSESCR_STR_X,PAUSESCR_STR_Y+32+32);
        break;
      case 2:
        DrawText(dc->body,&gAssets.fontKapel2x,"RESUME",PAUSESCR_STR_X,PAUSESCR_STR_Y);
        DrawText(dc->body,&gAssets.fontKapel2x,"MAIN MENU",PAUSESCR_STR_X,PAUSESCR_STR_Y+32);
        DrawTextMask(dc->body,&gAssets.fontKapel2x,"QUIT",PAUSESCR_STR_X,PAUSESCR_STR_Y+32+32,mask);
        break;
    }
  }
}

#endif