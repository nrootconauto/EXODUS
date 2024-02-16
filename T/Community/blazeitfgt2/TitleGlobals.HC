#ifndef TITLEGLOBALS_HC
#define TITLEGLOBALS_HC

#define TITLE_END_T 1

class TitleData {
  F64 time;
  F64 end_t;
  U8 *srcText;
  CBGR48 palette[COLORS_NUM];
  Bool transition;
} titleData;

titleData.srcText = FileRead("TitleDraw.HC");

#endif
