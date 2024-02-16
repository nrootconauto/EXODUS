//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  try {
    while (!ScanKey) {
      Play("5sE4A5E4A5eFF4sAGAG5FGFGqCC4BA",
	    "All \0\0\0\0hell \0\0breaks \0\0\0\0"
	    "loose.\n\0\0\0\0I \0will \0get \0through.\n\0");
      Play("5sE4A5E4A5eFF4sAGAG5FGFGqCC4BA",
	    "All \0\0\0\0hell \0\0breaks \0\0\0\0"
	    "loose.\n\0\0\0\0I \0will \0get \0through.\n\0");
      Play("4A5CeCC4sBBBB5qEsCCCC4qA5E");
      Play("4A5CeCC4sBBBB5qEsCCCC4qA5E");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
