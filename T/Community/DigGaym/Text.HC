#ifndef TEXT_HC
#define TEXT_HC

#include "Font"

class TextData {
  U8 *str;
  F64 timer;
  F64 speed;
};

I64 GetTextWidth(Font* font, U8 *str) { // assumes single line
  I64 i, width=0;
  for (i=0; i<StrLen(str); i++) {
    switch (str[i]) {
      case 32:
        width += font->x;
        break;
      default:
        width += font->font[str[i]-33]->width + 1;
    }
  }
  return width-1;
}

U0 DrawText(U8 *fb, Font* font, U8 *str, I64 x, I64 y) {
  I64 i, cur=x;
  for (i=0; i<StrLen(str); i++) {
    switch (str[i]) {
      case 10:
        cur = x;
        y += font->y;
        break;
      case 32:
        cur += font->x;
        break;
      default:
        PxBlot(fb, font->font[str[i]-33], cur, y);
        cur += font->font[str[i]-33]->width + 1;
    }
  }
}

U0 DrawTextBounce(U8 *fb, Font* font, TextData *data, I64 x, I64 y) {
  I64 i, cur=x;
  F64 bounce = data->timer * data->speed;
  I64 max = Min(StrLen(data->str), ToI64(bounce)+1);
  for (i=0; i<max; i++) {
    switch (data->str[i]) {
      case 10:
        cur = x;
        y += font->y;
        break;
      case 32:
        cur += font->x;
        break;
      default:
        F64 by = 0;
        if (i == ToI64(bounce)) {
          by += bounce-i;
        }
        PxBlot(fb, font->font[data->str[i]-33], cur, y+6*by);
        cur += font->font[data->str[i]-33]->width + 1;
    }
  }
}

#endif