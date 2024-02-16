#ifndef TITLEINPUT_HC
#define TITLEINPUT_HC

#include "Draw";

extern U0 QuitGame();
extern U0 InitPlayfield();

public U0 TitleInput() {
  I64 msg, ch, sc;
  while (TRUE) {
    msg = ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN|1<<MSG_MS_L_DOWN, Fs);
    switch (msg) {
      case MSG_KEY_DOWN:
        if (ch) {
          switch (ch) {
            case CH_SPACE:
              InitPlayfield;
              break;
            case CH_ESC:
            case CH_SHIFT_ESC:
              QuitGame;
              return;
            default:
              break;
          }
        }
        break;
      case MSG_MS_L_DOWN:
        InitPlayfield;
        break;
      default:
        return;
    }
  }
}

#endif