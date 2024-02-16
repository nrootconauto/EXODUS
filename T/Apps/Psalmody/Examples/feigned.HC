//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.857;
  try {
    while (!ScanKey) {
      Play("5eEDEFqDDeEDEDqCC",
	    "$$CL$$Sit\0ting\0in\0a\0church\n\0\0"
	    "wond\0ering\0to\0my\0self,\n\0\0");
      Play("5eD4GB5CqDsGGGGeD4GB5CqDsGGGG",
	    "\"Is\0\0God\0\0real?\"\n\0\0\0\0\0"
	    "\"At\0\0the\0\0wheel?\"\n\0\0\0\0\0");
      "$$GREEN$$God talking...\n$$FG$$";
      Play("5qFFFetRE4A5qGsGFGFGEGEqC",
	    "$$RED$$Oh,\0Hell\0yes!\n\0\0\0\0\0"
	    "\0\0\0\0\0\0\0\0\0");
      Play("5FFFetRE4A5qGsGFGFGEGEqC",
	    "Pass\0the\0test.$$FG$$\n\0\0\0\0\0"
	    "\0\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
