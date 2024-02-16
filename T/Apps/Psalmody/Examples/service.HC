//5 has words
U0 Song()
{
  CTask *task;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    task=PopUpViewPrint(
	  "$LK,"Matthew,20:28",A="BF:Matthew,20:28"$\n"
	  "$LK,"Mark,10:45",A="BF:Mark,10:45"$\n"
	  "$LK,"John,13:14",A="BF:John,13:14"$\n");
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    while (!ScanKey) {
      "$$GREEN$$Jesus talking...\n$$FG$$";
      Play("M6/8");
      Play("4eAA5C4A5D4AA5D4A5C4AR",
	    "\0\0I\0\0came\0\0\0to\0\0serve.\n\0\0\0");
      Play("4AA5C4A5D4AA5D4A5C4AR",
	    "\0\0I\0\0give\0\0\0my\0\0word.\n\0\0\0");
      Play("5FGetFEG4AB5CD4A5C4qG5sECEC");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
