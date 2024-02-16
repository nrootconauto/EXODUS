#ifndef PLAYFIELDINPUT_HC
#define PLAYFIELDINPUT_HC

#include "PlayfieldUpdate"

public U0 PlayfieldInput() {
  I64 msg, ch, sc;
  gCtrl.bombPressed = FALSE;
  gCtrl.upPressed = FALSE;
  gCtrl.downPressed = FALSE;
  gCtrl.acceptPressed = FALSE;
  while (TRUE) {
    msg = ScanMsg(&ch,&sc, 1<<MSG_KEY_DOWN|1<<MSG_KEY_UP, gW.task);
    switch (msg) {
      case MSG_KEY_DOWN:
        if (!ch) {
          switch (sc.u8[0]) {
            case SC_CURSOR_RIGHT:
              gCtrl.cVel.x = 1.0;
              break;
            case SC_CURSOR_LEFT:
              gCtrl.cVel.x = -1.0;
              break;
            case SC_CURSOR_UP:
              gCtrl.cVel.y = -1.0;
              gCtrl.upPressed = !gCtrl.upDown;
              gCtrl.upDown = TRUE;
              break;
            case SC_CURSOR_DOWN:
              gCtrl.cVel.y = 1.0;
              gCtrl.downPressed = !gCtrl.downDown;
              gCtrl.downDown = TRUE;
              break;
            case SC_CTRL:
              gCtrl.bombPressed = !gCtrl.bombDown;
              gCtrl.bombDown = TRUE;
              break;
            default:
              break;
          }
        } else {
          switch (ch) {
            case 'd':
              gCtrl.cVel.x = 1.0;
              break;
            case 'a':
              gCtrl.cVel.x = -1.0;
              break;
            case 'w':
              gCtrl.cVel.y = -1.0;
              gCtrl.upPressed = !gCtrl.upDown;
              gCtrl.upDown = TRUE;
              break;
            case 's':
              gCtrl.cVel.y = 1.0;
              gCtrl.downPressed = !gCtrl.downDown;
              gCtrl.downDown = TRUE;
              break;
            case 'z':
            case CH_SPACE:
              gCtrl.firing = TRUE;
              break;
            case 'x':
              gCtrl.bombPressed = !gCtrl.bombDown;
              gCtrl.bombDown = TRUE;
              break;
            case '\n':
              gCtrl.acceptPressed = !gCtrl.acceptDown;
              gCtrl.acceptDown = TRUE;
              if (gW.dead) {
                ResetGame();
              }
              break;
            case 'm':
              SetSnd(SND_MUTE);
              break;
#ifdef DEBUG
            case '1':
              gW.activeWeapon = WEAPON_SHOT0;
              break;
            case '2':
              gW.activeWeapon = WEAPON_SHOT1;
              break;
            case '3':
              gW.activeWeapon = WEAPON_SHOT2;
              break;
            case '4':
              gW.activeWeapon = WEAPON_SPREAD0;
              break;
            case '5':
              gW.activeWeapon = WEAPON_SPREAD1;
              break;
            case '6':
              gW.activeWeapon = WEAPON_SPREAD2;
              break;
            case '7':
              gW.activeWeapon = WEAPON_LASER0;
              break;
            case '8':
              gW.activeWeapon = WEAPON_LASER1;
              break;
            case '9':
              gW.activeWeapon = WEAPON_LASER2;
              break;
            case 'n':
              InitNextLevel;
              break;
            case 'u':
              gW.gtext.godWallet += 99;
              break;
#endif
            case CH_ESC:
              InitPauseMenu();
              break;
            case CH_SHIFT_ESC:
              gCtrl.quitGame = TRUE;
              return;
            default:
              break;
          }
        }
        break;
      case MSG_KEY_UP:
        if (!ch) {
          switch (sc.u8[0]) {
            case SC_CURSOR_RIGHT:
              if (gCtrl.cVel.x > 0.0)
                gCtrl.cVel.x = 0.0;
              break;
            case SC_CURSOR_LEFT:
              if (gCtrl.cVel.x < 0.0)
                gCtrl.cVel.x = 0.0;
              break;
            case SC_CURSOR_UP:
              if (gCtrl.cVel.y < 0.0)
                gCtrl.cVel.y = 0.0;
              //gCtrl.upReleased = gCtrl.upDown;
              gCtrl.upDown = FALSE;
              break;
            case SC_CURSOR_DOWN:
              if (gCtrl.cVel.y > 0.0)
                gCtrl.cVel.y = 0.0;
              //gCtrl.downReleased = gCtrl.downDown;
              gCtrl.downDown = FALSE;
            case SC_CTRL:
              gCtrl.bombDown = FALSE;
              break;
            default:
              break;
          }
        } else {
          switch (ch) {
            case 'd':
              if (gCtrl.cVel.x > 0.0)
                gCtrl.cVel.x = 0.0;
              break;
            case 'a':
              if (gCtrl.cVel.x < 0.0)
                gCtrl.cVel.x = 0.0;
              break;
            case 'w':
              if (gCtrl.cVel.y < 0.0)
                gCtrl.cVel.y = 0.0;
              //gCtrl.upReleased = gCtrl.upDown;
              gCtrl.upDown = FALSE;
              break;
            case 's':
              if (gCtrl.cVel.y > 0.0)
                gCtrl.cVel.y = 0.0;
              //gCtrl.downReleased = gCtrl.downDown;
              gCtrl.downDown = FALSE;
              break;
            case 'z':
            case CH_SPACE:
              gCtrl.firing = FALSE;
              break;
            case 'x':
              gCtrl.bombDown = FALSE;
              break;
            case '\n':
              gCtrl.acceptDown = FALSE;
              break;
            default:
              break;
          }
        }
        break;
      default:
        return;
    }
  }
}

#endif
