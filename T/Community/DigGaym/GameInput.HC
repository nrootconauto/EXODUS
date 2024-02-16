#ifndef GAMEINPUT_HC
#define GAMEINPUT_HC

#include "World"

extern U0 QuitGame();
extern CJob *sndJob;

public U0 GameInput() {
  I64 msg, ch, sc;
  gCtrl.mLDown = FALSE;
  gCtrl.mLUp = FALSE;
  gCtrl.mRDown = FALSE;
  gCtrl.mRUp = FALSE;
  while (TRUE) {
    msg = ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN|1<<MSG_KEY_UP|
                  1<<MSG_MS_L_DOWN|1<<MSG_MS_L_UP|
                  1<<MSG_MS_R_DOWN|1<<MSG_MS_R_UP, Fs);
    switch (msg) {
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
      case MSG_KEY_DOWN:
        if (ch) {
          switch (ch) {
            case 'd':
              gCtrl.cVel.x = 1.0;
              break;
            case 'a':
              gCtrl.cVel.x = -1.0;
              break;
            case 'w':
              gCtrl.cVel.y = -1.0;
              break;
            case 's':
              gCtrl.cVel.y = 1.0;
              break;
            case CH_SPACE:
              gCtrl.cJump = TRUE;
              break;
            case 'i':
              gCtrl.cInv = TRUE;
              break;
            case '1':
              gCtrl.cNum = 0;
              break;
            case '2':
              gCtrl.cNum = 1;
              break;
            case '3':
              gCtrl.cNum = 2;
              break;
            case '4':
              gCtrl.cNum = 3;
              break;
            case '5':
              gCtrl.cNum = 4;
              break;
            case '6':
              gCtrl.cNum = 5;
              break;
            case '7':
              gCtrl.cNum = 6;
              break;
            case '8':
              gCtrl.cNum = 7;
              break;
            case CH_ESC:
              gCtrl.cEsc = TRUE;
              break;
            case CH_SHIFT_ESC:
              QuitGame;
              return;
            case 'x':
              gCtrl.cTest0 = TRUE;
              break;
            case 'c':
              gCtrl.cTest1--;
              break;
            case 'v':
              gCtrl.cTest1++;
              break;
            case 'b':
              gCtrl.cTest2--;
              break;
            case 'n':
              gCtrl.cTest2++;
              break;
            case 'm':
              Kill(sndJob);
              Snd;
              break;
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
              break;
            case SC_CURSOR_DOWN:
              if (gCtrl.cVel.y > 0.0)
                gCtrl.cVel.y = 0.0;
            default:
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
              break;
            case 's':
              if (gCtrl.cVel.y > 0.0)
                gCtrl.cVel.y = 0.0;
              break;
            case CH_SPACE:
              gCtrl.cJump = FALSE;
              break;
            case 'm':
              gCtrl.cTest3 = 0;
              break;
            default:
          }
        }
        break;
      default:
        return;
    }
  }
}

#endif
