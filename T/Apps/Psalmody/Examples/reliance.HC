//5 has words
U0 Song()
{
  CTask *task;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  try {
    task=PopUpViewPrint(
	  "$$WW+H,1$$$LK,"BF:Matthew,6:11"$\n\n"
	  "I find two things interesting.Jesus asks for "
	  "the bare minimum... can't ask for less than daily bread."
	  "Also, He actually demands it.I find that funny.\n\n"
	  "$LK,"BF:Matthew,10:31"$\n\n"
	  "I have a funny story.I used to shoot birds with a BB-gun."
	  "That passage didn't snd so comforting!!How many sparrows "
	  "am I worth?\n"
	  );
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    DocRecalc(DocPut(task)); //Reformat word-wrap with new window size.
    while (!ScanKey) {
      Play("5qG4sBGBG5eF4G5sGGGGeRFC4G5qFC",
	    "Where's\0my\0\0\0next\0\0\0meal!!\n\0"
	    "\0\0\0\0\0\0\0\0\0");
      Play("5G4sBGBG5eF4G5sGGGGeRFC4G5qFC",
	    "God,\0we\0\0\0had\0\0a\0deal!!\n\0\0"
	    "\0\0\0\0\0\0\0\0");
      Play("4BGsGAGA5eCCsCECE4qA5CsGFGF",
	    "Day\0old\0bread?\n\0\0\0\0\0\0\0\0\0"
	    "\0\0\0\0\0\0\0");
      Play("4qBGsGAGA5eCCsCECE4qA5CsGFGF",
	    "'Dai\0ly'\0I\0\0\0\0said.\n\0\0\0\0\0"
	    "\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
