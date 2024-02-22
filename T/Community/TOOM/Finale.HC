#define E1TEXT \
"Once you beat the big badasses and\n"\
"clean out the moon base you're supposed\n"\
"to win, aren't you? Aren't you? Where's\n"\
"your fat reward and ticket home? What\n"\
"the hell is this? It's not supposed to\n"\
"end this way!\n"\
"\n" \
"It stinks like rotten meat, but looks\n"\
"like the lost Deimos base.  Looks like\n"\
"you're stuck on The Shores of Hell.\n"\
"The only way out is through.\n"\
"\n"\
"To continue the DOOM experience, play\n"\
"The Shores of Hell and its amazing\n"\
"sequel, Inferno!\n"

#define E2TEXT \
"You've done it! The hideous cyber-\n"\
"demon lord that ruled the lost Deimos\n"\
"moon base has been slain and you\n"\
"are triumphant! But ... where are\n"\
"you? You clamber to the edge of the\n"\
"moon and look down to see the awful\n"\
"truth.\n" \
"\n"\
"Deimos floats above Hell itself!\n"\
"You've never heard of anyone escaping\n"\
"from Hell, but you'll make the bastards\n"\
"sorry they ever heard of you! Quickly,\n"\
"you rappel down to  the surface of\n"\
"Hell.\n"\
"\n" \
"Now, it's on to the final chapter of\n"\
"DOOM! -- Inferno."

#define E3TEXT \
"The loathsome spiderdemon that\n"\
"masterminded the invasion of the moon\n"\
"bases and caused so much death has had\n"\
"its ass kicked for all time.\n"\
"\n"\
"A hidden doorway opens and you enter.\n"\
"You've proven too tough for Hell to\n"\
"contain, and now Hell at last plays\n"\
"fair -- for you emerge from the door\n"\
"to see the green fields of Earth!\n"\
"Home at last.\n" \
"\n"\
"You wonder what's been happening on\n"\
"Earth while you were battling evil\n"\
"unleashed. It's good that no Hell-\n"\
"spawn could have come through that\n"\
"door with you ..."

#define E4TEXT \
"the spider mastermind must have sent forth\n"\
"its legions of hellspawn before your\n"\
"final confrontation with that terrible\n"\
"beast from hell.  but you stepped forward\n"\
"and brought forth eternal damnation and\n"\
"suffering upon the horde as a true hero\n"\
"would in the face of something so evil.\n"\
"\n"\
"besides, someone was gonna pay for what\n"\
"happened to daisy, your pet rabbit.\n"\
"\n"\
"but now, you see spread before you more\n"\
"potential pain and gibbitude as a nation\n"\
"of demons run amok among our cities.\n"\
"\n"\
"next stop, hell on earth!"

#define TEXT_SPEED 5
#define TEXT_WAIT 3
extern Bool BunnyScroll(CDC *dc);
U0 Finale(CDC *dc,I64 ep) {
  U8 *str,buf[TEXT_COLS*TEXT_ROWS+1];
  CDC *flat;
  I64 ch,cnt,coff,ascii;
  I64 i,i2;
  F64 start_tS;
  F64 wait_start_tS=0;
  switch(ep) {
    case 1:
      str=E1TEXT;
      flat=GetFlatDC("FLOOR4_8");
      break;
    case 2:
      str=E2TEXT;
      flat=GetFlatDC("SFLR6_1");
      break;
    case 3:
      BunnyScroll(dc);
      str=E3TEXT;
      flat=GetFlatDC("MFLR8_4");
      break;
    case 4:
      str=E4TEXT;
      flat=GetFlatDC("MFLR8_3");
      break;
  }
  start_tS=Server_tS;
  MemSet(buf,0,TEXT_COLS*TEXT_ROWS+1);
  cnt=StrLen(str);
  coff=0;
  while(TRUE) {
    ch=(Server_tS-start_tS)*TEXT_SPEED;
    if(ch+coff>cnt) {
      ch=cnt;
      if(!wait_start_tS)
	wait_start_tS=Server_tS;
      if(Server_tS-wait_start_tS>TEXT_WAIT)
	break;
    }
    if(!paused&&ScanKey(&ascii)) {
      if(ascii==CH_ESC)
	paused=TRUE;
      //Refresh to regen keys
      Refresh;
    }
    for(i=0;i<GR_WIDTH/2;i++) {
      for(i2=0;i2<GR_HEIGHT/2;i2++) {
        GrBlot(dc,
	      flat->width*i,
	      flat->height*i2,
	      flat
	      );
      }
    }
    while(Bt(char_bmp_white_space,str[ch+coff])) {
      buf[ch+coff]=str[ch+coff];
      coff++;
    }
    buf[ch+coff]=str[ch+coff];
    DoomPrint(dc,10,10,buf);
    if(paused)
      if(!MainMenu)
        Unpause;
    GrBlot(,0,0,doom_scrn);
    Refresh;
  }
  DCFill;
}
Bool BunnyScroll(CDC *dc) {
  F64 st=Server_tS;
  U8 buf[STR_LEN];
  CDC *p1=GetGrLump("PFUB2");
  CDC *p2=GetGrLump("PFUB1");
  CDC *lump; 
  I64 scrolled,finale_cnt,stage,ascii;
  while(TRUE) {
    finale_cnt=(Server_tS-st)*30.;
    scrolled=(finale_cnt-230)/2;
    if(scrolled>320)
      scrolled=320;
    if(scrolled<0)
      scrolled=0;
    GrBlot(dc,scrolled*2-p1->x*2-320*2,-p1->y*2,p1);
    GrBlot(dc,scrolled*2-p2->x*2,-p2->y*2,p2);
    if(!paused&&ScanKey(&ascii)) {
      if(ascii==CH_ESC)
	paused=TRUE;
      //Refresh to regen keys
      Refresh;
    }
    if(paused)
      if(!MainMenu)
        Unpause;
    if(finale_cnt<1130)
      goto skip;
    if(finale_cnt<1180) {
      lump=GetGrLump("END0");
      GrBlot(dc,(GR_WIDTH-13*8*2)/2-lump->x*2,(GR_HEIGHT-8*8*2)/2-lump->y*2,lump);
      goto skip;
    }
    stage=(finale_cnt-1180)/5;
    if(stage>9)
      break;
    if(stage>6)
      stage=6;
    StrPrint(buf,"END%d",stage);
    lump=GetGrLump(buf);
    GrBlot(dc,(GR_WIDTH-13*8*2)/2-lump->x*2,(GR_HEIGHT-8*8*2)/2-lump->y*2,lump);
skip:;
    GrBlot(,0,0,doom_scrn);
    Refresh;
  }
  DCFill;
  return FALSE;

}