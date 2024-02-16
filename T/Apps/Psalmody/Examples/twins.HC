//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.260;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      "$$GREEN$$As I look back on my sinful past...$$FG$$\n";
      Play("5qC4AABAeA5ECE4qB",
	    "Who\0was\0that\0per\0son?\0\0It\0wasn't\0\0me?\n\0");
      Play("5C4AABAeA5ECE4qB",
	    "Who\0was\0that\0per\0son?\0\0It\0wasn't\0\0me?\n\0");
      Play("5etDEDqF4etB5ED4eA5FGEqFDE",
	    "Sad\0to\0say,\0\0I\0guess\0\0"
	    "it\0\0was\0\0\0me.\n\0\0");
      Play("5etDEDqF4etB5ED4eA5FGEqFDE",
	    "Sad\0to\0say,\0\0I\0guess\0\0"
	    "it\0\0was\0\0\0me.\n\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
