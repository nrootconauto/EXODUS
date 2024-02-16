//5 has words
U0 Song()
{
  CTask *task;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.500;
  music.stacatto_factor= 0.900;
  try {
    task=PopUpViewPrint(
	  "$$WW+H,1$$You get what you pray for."
	  "Most people are fools like King Midas."
	  "People have laughable notions of Heaven."
	  "You'd be surprised -- I can't imagine things being "
	  "much better than Earth "
	  "because we need a sense of purpose."
	  "Don't ask for stuff, let God pick, but He might get "
	  "annoyed at that."
	  "God wants us to be happy.He tries hard.If you do get what "
	  "you pray for, you damn "
	  "well better be happy, you turkey!\n\n"
	  "$LK,"Ecclesiastes,3:13",A="BF:Ecclesiastes,3:13"$\n"
	  "$LK,"John,16:24",A="BF:John,16:24"$\n"
	  );
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    DocRecalc(DocPut(task)); //Reformat word-wrap with new window size.
    while (!ScanKey) {
      Play("4qB5eCDqC4AetAA5CeECsF4G5F4GqG",
	    "I'm\0on\0a\0mis\0sion\0from\0\0\0my\0\0"
	    "God.\n\0\0\0\0\0");
      Play("4B5eCDqC4AetAA5CeECsF4G5F4GqG",
	    "I'm\0on\0a\0mis\0sion\0from\0\0\0my\0\0"
	    "God.\n\0\0\0\0\0");
      Play("5etEDDDG4AB5G4GeG5E4G5GqF4G5etGCD",
	    "He\0\0\0told\0\0\0me\0\0\0\0to\0\0"
	    "be\0hap\0py.\n\0\0\0\0");
      Play("5EDDDG4AB5G4GeG5E4G5GqF4G5etGCD",
	    "He\0\0\0said\0\0\0to\0\0\0\0make\0\0"
	    "it\0snap\0py.\n\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
