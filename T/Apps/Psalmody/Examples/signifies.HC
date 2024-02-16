//5 has words
U0 Song()
{
  CTask *task;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    task=PopUpViewPrint("$LK,"Luke,12:12",A="BF:Luke,12:12"$\n");
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    while (!ScanKey) {
      Play("5hDeD4AqG5hDeD4GqF",
	    "It\0sig\0ni\0fies\n\0a\0big\0sur\0prise.\n\0");
      Play("5hDeD4sFGqA5hDeD4AqG",
	    "Why\0\0im\0pro\0vise?\n\0$$RED$$\"Be\0cause,\"$$FG$$\0"
	    "re\0plies.\n\0");
      Play("5eCE4sA5C4A5CeD4GqAA5FeE4G5etFCC",
	    "If\0\0you\0\0\0\0love\0your\0god,\n\0\0"
	    "don't\0bore\0\0Him!\n\0\0\0");
      Play("5eCE4sA5C4A5CeD4GqAA5FeE4G5etFCC",
	    "If\0\0you\0\0\0\0love\0your\0god,\n\0\0"
	    "sur\0prise\0\0Him!\n\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
