//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  try {
    "$$WW+H,1$$";
    while (!ScanKey) {
      Play("4qAA5sG4G5G4G5qGF4eG5FqEetC4BA",
	    "Let's\0ask\0Mike\0\0\0\0y;\0"
	    "Hates\0\0every\0thing.\n\0\0\0\0");
      Play("4qAA5sG4G5G4G5qGF4eG5FqEetC4BA",
	    "Let's\0ask\0Mike\0\0\0\0y;\0"
	    "Hates\0\0every\0thing.\n\0\0\0\0");
      Play("4eG5GqE4eG5FqF4sG5G4G5G4qA5etGE4B5qD",
	    "What\0do\0YOU\0\0\0know.\0"
	    "\0\0\0\0\0It's\0\0kosh\0er!\n\0");
      Play("4eG5GqE4eG5FqF4sG5G4G5G4qA5etGE4B5qD",
	    "What\0do\0YOU\0\0\0know.\0"
	    "\0\0\0\0\0It's\0\0kosh\0er!\n\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
