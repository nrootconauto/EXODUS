#ifndef SOUND_HC
#define SOUND_HC

#define SND_NONE 0
#define SND_LASER 1
#define SND_UPGRADE 2
#define SND_MOB_HIT 3
#define SND_PLAYER_DMG 4
#define SND_BASE_DESTROYED 5
#define SND_GRAPPLE_FIRE 6
#define SND_GRAPPLE_HIT 7
#define SND_EXPLOSION 8
#define SND_MINE 9
#define SND_LVL_END 10
#define SND_QUIT 11

I64 playSnd;
I32 sndPri[SND_QUIT+1];

public U0 InitSnd() {
  playSnd = SND_NONE;
  sndPri[SND_NONE] = 0;
  sndPri[SND_LASER] = 1;
  sndPri[SND_UPGRADE] = 8;
  sndPri[SND_MOB_HIT] = 2;
  sndPri[SND_PLAYER_DMG] = 7;
  sndPri[SND_BASE_DESTROYED] = 9;
  sndPri[SND_GRAPPLE_FIRE] = 3;
  sndPri[SND_GRAPPLE_HIT] = 4;
  sndPri[SND_EXPLOSION] = 5;
  sndPri[SND_MINE] = 2;
  sndPri[SND_LVL_END] = 9;
  sndPri[SND_QUIT] = 10;
}

public U0 SetSnd(I64 snd) {
  if (sndPri[snd] > sndPri[playSnd])
    playSnd = snd;
}

public U0 SndTask(I64) {
  while (TRUE) {
    while (playSnd == SND_NONE) {
      Sleep(1);
    }
    I64 snd = playSnd;
    playSnd = SND_NONE;
    switch (snd) {
      case SND_LASER:
        Snd(32);
        Sleep(16);
        Snd(26);
        Sleep(33);
        Snd(32);
        Sleep(16);
       break;
      case SND_MOB_HIT:
        Snd(46);
        Sleep(8);
        Snd(32);
        Sleep(33);
        break;
      case SND_PLAYER_DMG:
        Snd(40);
        Sleep(16);
        Snd(28);
        Sleep(44);
        Snd(36);
        Sleep(66);
        break;
      case SND_GRAPPLE_FIRE:
        Snd(30);
        Sleep(16);
        Snd(40);
        Sleep(32);
        Snd(30);
        Sleep(16);
        Snd;
        break;
      case SND_GRAPPLE_HIT:
        Snd(60);
        Sleep(2);
        Snd(70);
        Sleep(2);
        Snd(60);
        Sleep(2);
        Snd(70);
        Sleep(2);
        Snd;
        break;
      case SND_EXPLOSION:
        I64 i;
        for (i=0; i<32; i++) {
          Snd(RandU16%37+10);
          Sleep(4);
        }
        Snd;
        break;
      case SND_UPGRADE:
        Snd(48);
        Sleep(44);
        Snd(68);
        Sleep(33);
        Snd(80);
        Sleep(44);
        Snd(54);
        Sleep(33);
        Snd(68);
        Sleep(33);
        Snd(80);
        Sleep(66);
        break;
      case SND_BASE_DESTROYED:
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
      case SND_MINE:
        Snd(22);
        Sleep(8);
        Snd(28);
        Sleep(8);
        Snd(22);
        Sleep(8);
        Snd(50);
        Sleep(8);
        break;
      case SND_LVL_END:
        Snd(64);
        Sleep(100);
        Snd(66);
        Sleep(100);
        Snd(68);
        Sleep(100);
        Snd(66);
        Sleep(100);
        Snd(74);
        Sleep(100);
        break;
      case SND_QUIT:
        goto snd_done;
      default:
        Beep;
    }
    Snd;
  }
snd_done:
}

#endif