//5 has graphics

#define		X	25
#define		H	5

F64 t0=Beat;
U0 DrawIt(CTask *,CDC *dc)
{
  I64 i;
  F64 dt=Beat-t0;
  dc->x=325;
  dc->y=40;
  dc->z=GR_Z_ALL;
  dc->flags|=DCF_TRANSFORMATION;
  Mat4x4RotZ(dc->r,ã*dt/8);
  Mat4x4RotX(dc->r,3*ã/8);

  for (i=0;i<=2*H;i+=H) {
    GrLine3(dc,-X,-X,i,X,-X,i);
    GrLine3(dc,X,-X,i,X,X,i);
    GrLine3(dc,X,X,i,-X,X,i);
    GrLine3(dc,-X,X,i,-X,-X,i);
  }

  GrLine3(dc,-X,-X,0,-X,-X,2*H);
  GrLine3(dc,X,-X,0,X,-X,2*H);
  GrLine3(dc,-X,X,0,-X,X,2*H);
  GrLine3(dc,X,X,0,X,X,2*H);
}

U0 Song()
{
  SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
  Fs->draw_it=&DrawIt;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  try {
    while (TRUE) {
      t0=Beat;
      Play("5qC4qAqA5sEDED4qBqB5etGGEs4G5C4G5C");
      Play("5qC4qAqA5sEDED4qBqB5etGGEs4G5C4G5C");
      Play("5etCD4G5etEE4G5qFqF4qAsA5C4A5C4sA5F4A5FetECC",
	    "In \0my \0\0corn\0\0\0er? \0\0\0\0\0\0\0"
	    "Hope \0we're \0right.\n\0");
      Play("5etCD4G5etEE4G5qFqF4qAsA5C4A5C4sA5F4A5FetECC",
	    "In \0my \0\0corn\0\0\0er? \0\0\0\0\0\0\0"
	    "Hope \0we're \0right.\n\0");
    }
  } catch
    PutExcept;
  SettingsPop;
}

Song;
