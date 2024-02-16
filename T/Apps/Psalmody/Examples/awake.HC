//5 has graphics
#define R1	13
#define R2	21

U0 DrawIt(CTask *,CDC *dc)
{
  static F64 é=0;
  I64 x1=200,y1=20,x2=x1,y2=y1+R2;
  F64 tt=Beat%16.0,è;
  é+=1/(tt*tt+1);
  dc->color=BLACK;
  dc->thick=4;
  GrCircle3(dc,x2,y2,0,R2+10);
  for (è=é;è<é+2*ã;è+=ã/3) {
    dc->color=BLACK;
    dc->thick=2;
    GrCircle3(dc,x2+R2*Cos(è),y2-R2*Sin(è),0,8);
    dc->color=WHITE;
    dc->thick=2;
    GrCircle3(dc,x2+(R2+15)*Cos(è+ã/6),y2-(R2+15)*Sin(è+ã/6),0,3);
  }
  dc->color=BROWN;
  GrFloodFill(dc,x2+R2*Cos(è),y2-R2*Sin(è));
  dc->color=DKGRAY;
  GrFloodFill(dc,x2,y2);
  dc->thick=6;
  dc->color=RED;
  GrCircle3(dc,x1,y1,0,R1-6);
  dc->color=DKGRAY;
  GrCircle3(dc,x1,y1,0,R1-2);
  dc->color=LTGRAY;
  GrRect(dc,x1-2,y1-R2-1,4,10);
  GrCircle3(dc,x1,y1,0,R1);
  dc->color=RED;
  GrFloodFill(dc,x1,y1,TRUE);
  dc->color=BLACK;
  GrFloodFill(dc,x1,y1);
}

U0 Song()
{
  CTask *task;
  SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
  Fs->draw_it=&DrawIt;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    task=PopUpViewPrint("$LK,"Mark,14:37",A="BF:Mark,14:37"$\n");
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    while (!ScanKey) {
      "$$GREEN$$Jesus talking...$$FG$$\n";
      Play("4eB5C4qBsG5D4G5DetCGFsC4B5C4B5etCG4BeB5G4sB5C4B5C",
	    "Stay\0a\0wake.\n\0\0\0\0\0\0\0\0"
	    "\0\0\0\0\0\0\0\0\0\0\0\0\0");
      Play("4eB5C4qBsG5D4G5DetCGFsC4B5C4B5etCG4BeB5G4sB5C4B5C",
	    "Stay\0a\0wake.\n\0\0\0\0\0\0\0\0"
	    "\0\0\0\0\0\0\0\0\0\0\0\0\0");
      Play("5qDsD4B5D4BetAG5G4qBGsA5D4A5DqDetGFD",
	    "\0\0\0\0\0\0\0\0\0\0\0"
	    "I\0\0am\0a\0dead\0\0man.\n\0");
      Play("5qDsD4B5D4BetAG5G4qBGsA5D4A5DqDetGFD",
	    "\0\0\0\0\0\0\0\0\0\0\0"
	    "I\0\0am\0a\0dead\0\0man.\n\0");
    }
  } catch
    PutExcept;
  SettingsPop;
}

Song;
