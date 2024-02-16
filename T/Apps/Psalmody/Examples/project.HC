//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      Play("5qG4sARA5RC4B5C4BeA5C4A5CGCG4BA5sE4A",
	    "I'm\0mak\0\0ing\0\0some\0\0thing\0"
	    "\0\0\0\0\0for\0\0God.\n\0\0\0\0\0");
      Play("5qG4sARA5RC4B5C4BeA5C4A5CGCG4BA5sE4A",
	    "I'm\0mak\0\0ing\0\0some\0\0thing\0"
	    "\0\0\0\0\0for\0\0God.\n\0\0\0\0\0");
      Play("4eA5sCEqEsDECE4qA5sD4A5C4AeA5GF4sB5DeC4B",
	    "\0\0\0I\0hope\0\0He\0\0\0likes\0"
	    "\0it.\n\0\0\0\0\0\0\0\0\0");
      Play("4A5sCEqEsDECE4qA5sD4A5C4AeA5GF4sB5DeC4B",
	    "\0\0\0I\0hope\0\0He\0\0\0likes\0"
	    "\0it.\n\0\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
