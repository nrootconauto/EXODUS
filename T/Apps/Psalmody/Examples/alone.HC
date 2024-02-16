//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      Play("4q.GeGqGsBB5C4Bq.GeGqGsBB5C4B",
	    "I'm\0a\0lone.\n\0$$RED$$No,\0you're\0\0not.\n$$FG$$\0"
	    "I'm\0a\0lone.\n\0$$RED$$No,\0you're\0\0not.\n\0");
      Play("5q.C4eG5CsDC4eGG5qC4G5eCsDC4eGG",
	    "You\0are\0not\0a\0lone.\n\0\0\0Def\0inately,\0"
	    "not\0a\0lone.\n\0\0\0");
      Play("5sE4A5E4A5eCsCReRsD4A5e.G4sB5FFFFeE4sA5GeCsGDeDG",
	    "If\0\0you\0\0on\0ly\0\0\0\0\0knew.\n\0\0"
	    "His\0\0\0\0Spir\0it\0\0\0is\0\0with\0you.\n\0");
      Play("5sE4A5E4A5eCsCReRsD4A5e.G4sB5FFFFeE4sA5GeCsGDeDG",
	    "If\0\0you\0\0on\0ly\0\0\0\0\0knew.\n\0\0"
	    "His\0\0\0\0Spir\0it\0\0\0is\0\0with\0you.\n$$FG$$\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
