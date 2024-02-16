#ifndef TITLEINPUT_HC
#define TITLEINPUT_HC

#include "TitleGlobals"
#include "Sound"
#include "Globals"

U0 TitleInitEnd() {
  if (!titleData.transition && titleData.time > 0.1) {
    SetSnd(SND_TITLE_END);
    titleData.transition = TRUE;
  }
}

U0 TitleInput() {
  I64 msg, ch, sc;
  while (TRUE) {
    msg = ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN|1<<MSG_MS_L_DOWN, Fs);
    switch (msg) {
      case MSG_KEY_DOWN:
        if (ch) {
          switch (ch) {
            case '\n':
            case CH_SPACE:
              TitleInitEnd();
              break;
//            case CH_ESC:
            case CH_SHIFT_ESC:
              QuitGame;

              return;
            default:
              break;
          }
        }
        break;
      case MSG_MS_L_DOWN:
        TitleInitEnd();
        break;
      default:
        return;
    }
  }

}

#endif
