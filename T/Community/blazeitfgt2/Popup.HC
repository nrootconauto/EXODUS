#ifndef POPUP_HC
#define POPUP_HC

#define POPUP_TTL 4
#define POPUP_CNT 6

F64 popup_ttl;
U8 popupStr[POPUP_CNT][64];

public U0 InitPopup() {
  I64 i;
  for (i=0; i<POPUP_CNT; i++) {
    popupStr[i][0] = '\0';
  }
  popup_ttl = POPUP_TTL;
}

#endif
