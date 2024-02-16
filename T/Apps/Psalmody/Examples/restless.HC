//5 has words
U0 Song()
{
  CTask *task;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 1.710;
  music.stacatto_factor= 0.736;
  try {
    task=PopUpViewPrint("$LK,"Ecclesiastes,5:12",A="BF:Ecclesiastes,5:12"$\n");
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    while (!ScanKey) {
      Play("5sDDD4A5CC4A5DD4A5CC4A5e.DsCCC4G5FD4G5FD4G5CC4A5e.D",
	    "I\0\0\0\0got\0\0\0paid,\0\0\0to\0\0\0"
	    "day.\n\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0");
      Play("5qD4sG5G4G5GetGD4A5eF4GqG5etF4BA5E4A5CECE",
	    "\0\0\0\0\0\0\0\0\0\0\0I\0\0\0"
	    "can't\0\0\0get\0\0to\0");
      Play("5qD4sG5G4G5GetGD4A5eF4GqG5etF4BA5E4A5CECE",
	    "sleep.\n\0\0\0\0\0\0\0\0\0\0\0\0"
	    "\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
