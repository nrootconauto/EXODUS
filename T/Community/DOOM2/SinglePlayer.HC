#include "MainDrawer.HC";
U64 r;
CDC *title=GetGrLump( "TITLEPIC");
DocClear;
while(TRUE) {
  TallBlot(doom_scrn,0,0,GR_HEIGHT,title);
  r=MainMenu;
  GrBlot(,0,0,doom_scrn);
  Refresh; 
  if(!r) {
     DCFill;
     break;
  }
}


DCFill;
