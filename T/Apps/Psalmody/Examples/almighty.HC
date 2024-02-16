//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  try {
    while (!ScanKey) {
      Play("4qG5etC4GGqARRetG5F4B5qEeFE",
	    "All\0righ\0\0\0ty.\n\0\0\0\0\0\0\0\0\0");
      Play("4qG5etC4GGqARRetG5F4B5qEeFE",
	    "All\0migh\0\0\0ty.\n\0\0\0\0\0\0\0\0\0");
      Play("5qFFEEeE4B5qFC4B",
	    "Al\0read\0y,\0\0I've\0\0seen\0en\0ough.\n\0");
      Play("5FFEEeE4B5qFC4B",
	    "Oh\0bo\0y,\0\0was\0\0that\0rough.\n\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
