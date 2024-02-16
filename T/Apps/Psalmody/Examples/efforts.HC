//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  try {
    while (!ScanKey) {
      Play("4qG5sD4A5D4A5eF4G5etFDC4BAGqA5etGFC4eG5E",
	    "\0Let's\0\0try.\0\0\0\0O\0oh\0\0h.\0"
	    "\0\0\0Didn't\0\0\0work.\n\0\0");
      Play("4qG5sD4A5D4A5eF4G5etFDC4BAGqA5etGFC4eG5E",
	    "\0Let's\0\0try.\0\0\0\0O\0oh\0\0h.\0"
	    "\0\0\0Didn't\0\0\0work.\n\0\0");
      Play("4sAGAGeB5CsE4G5E4G5qGsFEFED4B5D4BeA5G4etGBG");
      Play("4sAGAGeB5CsE4G5E4G5qGsFEFED4B5D4BeA5G4etGBG");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
