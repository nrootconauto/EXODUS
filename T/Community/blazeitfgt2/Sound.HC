#ifndef SOUND_HC
#define SOUND_HC

#include "GrFast"

#define SND_NONE       0
#define SND_BULLET     1
#define SND_LASER      2
#define SND_BOMB       3
#define SND_CREDIT     4
#define SND_UPGRADE    5
#define SND_HIT        6
#define SND_PLAYER_DMG 7
#define SND_MOB_BULLET 8
#define SND_TITLE_END  9
#define SND_MUTE       10
#define SND_QUIT       11

U32 r = 32;
I64 playSnd;
I32 sndPri[SND_QUIT+1];

public U0 InitSnd() {
  playSnd = SND_NONE;
  sndPri[SND_NONE]       = 0;
  sndPri[SND_BULLET]     = 2;
  sndPri[SND_LASER]      = 4;
  sndPri[SND_BOMB]       = 9;
  sndPri[SND_CREDIT]     = 5;
  sndPri[SND_UPGRADE]    = 8;
  sndPri[SND_HIT]        = 3;
  sndPri[SND_PLAYER_DMG] = 7;
  sndPri[SND_MOB_BULLET] = 1;
  sndPri[SND_TITLE_END]  = 10;
  sndPri[SND_MUTE]       = 254;
  sndPri[SND_QUIT]       = 255;
}

public U0 SetSnd(I64 snd) {
  if (snd == SND_MUTE) {
    if (playSnd == SND_MUTE)
      playSnd = SND_NONE;
    else
      playSnd = SND_MUTE;
  } else if (sndPri[snd] > sndPri[playSnd]) {
    playSnd = snd;
  }
}

public U0 SndTask(I64) {
  while (TRUE) {
    while (playSnd == SND_NONE || playSnd == SND_MUTE) {
      Sleep(1);
    }
    I64 i, s=43, snd=playSnd;
    playSnd = SND_NONE;
    switch (snd) {
      case SND_BULLET:
        for (i=0; i<16; i++) {
          Snd(32-i);
          Sleep(2);
        }
        break;
      case SND_LASER:
        Snd(16);
        Sleep(4);
        Snd(20);
        Sleep(4);
        Snd(16);
        Sleep(4);
       break;
      case SND_BOMB:
       for (i=0; i<48; i++) {
         s = XorShift(s);
         Snd(30 + s%30 - i);
         Sleep(5);
       }
       break;
      case SND_HIT:
        Snd(40);
        Sleep(8);
        Snd(32);
        Sleep(16);
        break;
      case SND_PLAYER_DMG:
        Snd(40);
        Sleep(16);
        Snd(28);
        Sleep(44);
        Snd(36);
        Sleep(66);
        break;
      case SND_MOB_BULLET:
        for (i=0; i<8; i++) {
          Snd(24-i);
          Sleep(2);
        }
        break;
      case SND_CREDIT:
        Snd(36);
        Sleep(8);
        Snd(40);
        Sleep(8);
        Snd(44);
        Sleep(8);
        break;
      case SND_UPGRADE:
        Snd(40);
        Sleep(16);
        Snd(50);
        Sleep(8);
        Snd(60);
        Sleep(16);
        Snd(50);
        Sleep(8);
        Snd(60);
        Sleep(8);
        break;
      case SND_TITLE_END:
        Snd(24);
        Sleep(33);
        Snd(32);
        Sleep(16);
        Snd(24);
        Sleep(16);
        Snd(32);
        Sleep(16);
        Snd(24);
        Sleep(16);
        Snd(32);
        Sleep(16);
        Snd(24);
        Sleep(16);
        Snd(32);
        Sleep(16);
        Snd(40);
        Sleep(16);
        Snd(38);
        Sleep(16);
        Snd(48);
        Sleep(16);
        break;
      case SND_QUIT:
        goto snd_done;
      default:
        Beep;
    }
    Snd;
  }
snd_done:
  Snd;
}

#endif
