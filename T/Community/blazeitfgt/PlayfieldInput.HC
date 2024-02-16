#ifndef PLAYFIELDINPUT_HC
#define PLAYFIELDINPUT_HC

#include "World";
#include "Draw";

extern CD2 cVel;
extern Bool firing;
extern Bool quitGame;
extern I64 lastWheel;
extern I64 test_flag;
extern World gW;
extern U0 InitPlayfield();
extern CJob *sndJob;
extern U0 InitNextLevel();

public U0 PlayfieldInput() {
  I64 msg, ch, sc;
  while (TRUE) {
    msg = ScanMsg(&ch,&sc,
    1<<MSG_KEY_DOWN|1<<MSG_KEY_UP|
    1<<MSG_MS_L_DOWN|1<<MSG_MS_L_UP, gW.task);
    switch (msg) {
      case MSG_KEY_DOWN:
        if (!ch) {
          switch (sc.u8[0]) {
            case SC_CURSOR_RIGHT:
              cVel.x = 1.0;
              break;
            case SC_CURSOR_LEFT:
              cVel.x = -1.0;
              break;
            case SC_CURSOR_UP:
              cVel.y = -1.0;
              break;
            case SC_CURSOR_DOWN:
              cVel.y = 1.0;
            default:
              break;
          }
        } else {
          switch (ch) {
            case 'd':
              cVel.x = 1.0;
              break;
            case 'a':
              cVel.x = -1.0;
              break;
            case 'w':
              cVel.y = -1.0;
              break;
            case 's':
              cVel.y = 1.0;
              break;
            case CH_SPACE:
              firing = TRUE;
              break;
            case '1':
              gW.activeWeapon = WEAPON_SHOT;
              gW.activeWeaponTTL = gW.player.bulletCooldown;
              break;
            case '2':
              gW.activeWeapon = WEAPON_LASER;
              gW.activeWeaponTTL = WEAPON_LASER_TTL;
              break;
            case '\n':
              if (gW.dead) {
                InitPlayfield;
              }
              break;
            case 'm':
              Kill(sndJob);
              Snd;
              break;
#ifdef DEBUG
            case 'h': // TEST KEY
              test_flag = 1;
              break;
            case 'g': // Health Refill
              gW.player.health = 100000;
              break;
            case 'n':
              InitNextLevel;
              break;
            case 'u':
              gW.gtext.godWallet += 99;
              break;
#endif
            case CH_ESC:
            case CH_SHIFT_ESC:
              quitGame = TRUE;
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
              if (cVel.x > 0.0)
                cVel.x = 0.0;
              break;
            case SC_CURSOR_LEFT:
              if (cVel.x < 0.0)
                cVel.x = 0.0;
              break;
            case SC_CURSOR_UP:
              if (cVel.y < 0.0)
                cVel.y = 0.0;
              break;
            case SC_CURSOR_DOWN:
              if (cVel.y > 0.0)
                cVel.y = 0.0;
            default:
              break;
          }
        } else {
          switch (ch) {
            case 'd':
              if (cVel.x > 0.0)
                cVel.x = 0.0;
              break;
            case 'a':
              if (cVel.x < 0.0)
                cVel.x = 0.0;
              break;
            case 'w':
              if (cVel.y < 0.0)
                cVel.y = 0.0;
              break;
            case 's':
              if (cVel.y > 0.0)
                cVel.y = 0.0;
              break;
            case 'h': // TEST KEY
              test_flag = 0;
              break;
            case CH_SPACE:
              firing = FALSE;
            default:
              break;
          }
        }
        break;
      case MSG_MS_L_DOWN:
        firing = TRUE;
        break;
      case MSG_MS_L_UP:
        firing = FALSE;
        break;
      default:
      case NULL:
        if (ms.pos.z != lastWheel) {
          if (ms.pos.z > lastWheel) {
            gW.cam.zoom *= 0.9;
            gW.cam.zoom = Max(gW.cam.zoom, 0.1);
          } else {
            gW.cam.zoom *= 1.1;
            if (gW.cam.zoom > 1.0)
              gW.cam.zoom = 1.0;
          }
          lastWheel = ms.pos.z;
        }
        return;
      default:
        "UNHANDLED INPUT\n";
    }
  }
}

#endif