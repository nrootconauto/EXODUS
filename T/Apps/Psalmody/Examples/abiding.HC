//5 has graphics

#define X	330
#define Y	15

#define BEAMS_NUM	256

F64 beams_r[BEAMS_NUM],beams_é[BEAMS_NUM];

U0 DrawIt(CTask *,CDC *dc)
{
  I64 i;
  F64 r,x1,y1,x2,y2;
  dc->color=YELLOW;
  GrCircle(dc,X,Y,10);
  GrFloodFill(dc,X,Y,10);
  dc->color=BROWN;
  GrCircle(dc,X,Y,10);
  dc->color=YELLOW;
  for (i=0;i<BEAMS_NUM;i++) {
    r=125.0*((0.25*Beat+beams_r[i])%1.0);
    P2R(&x1,&y1,r     ,beams_é[i]);
    P2R(&x2,&y2,r+10.0,beams_é[i]);
    GrLine(dc,x1+X,y1+Y,x2+X,y2+Y);
  }
}

U0 Song()
{
  CTask *task;
  I64 i;
  SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
  Fs->text_attr=LTCYAN<<4+BLACK;
  Fs->draw_it=&DrawIt;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  for (i=0;i<BEAMS_NUM;i++) {
    beams_r[i]=Rand;
    beams_é[i]=2*ã*Rand;
  }
  try {
    task=PopUpViewPrint(
	  "$LK,"Numbers,6:25",A="BF:Numbers,6:25"$\n"
	  "$LK,"Psalms,31:16",A="BF:Psalms,31:16"$\n"
	  "$LK,"Psalms,67:1",A="BF:Psalms,67:1"$\n"
	  "$LK,"Psalms,80:3",A="BF:Psalms,80:3"$\n"
	  "$LK,"Psalms,80:19",A="BF:Psalms,80:19"$\n"
	  "$LK,"Psalms,119:135",A="BF:Psalms,119:135"$\n"
	  "$LK,"Daniel,9:17",A="BF:Daniel,9:17"$\n");
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    "$$BG+H,LTCYAN$$$$FD+H,BLACK$$";
    while (!ScanKey) {
      "$$WHITE$$To God...\n$$FG$$";
      Play("5etCFEsDDDDD4G5D4G5qC4eG5EqE4etAA5F4qG",
	    "I\0am\0a\0biding\0\0\0\0in\0\0Your\0\0"
	    "presence.\n\0\0\0\0\0\0\0\0");
      Play("5etCFEsDDDDD4G5D4G5qC4eG5EqE4etAA5F4qG",
	    "I\0am\0a\0biding\0\0\0\0in\0\0Your\0\0"
	    "presence.\n\0\0\0\0\0\0\0\0");
      Play("5D4B5sFGFG4eG5FRDqEG4eB5E",
	    "I'm\0so\0smug!\n\0\0\0\0\0\0\0\0\0\0\0\0");
      Play("5qD4B5sFGFG4eG5FRDqEG4eB5E",
	    "God\0gives\0hugs!\n\0\0\0\0\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  SettingsPop;
}

Song;
