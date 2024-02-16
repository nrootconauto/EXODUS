//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.758;
  try {
    while (!ScanKey) {
      Play("4qBeABqAGABhG",
	    "Earn\0est\0y?\0\0\0Not\0the\0best.\n\0");
      Play("5sCCCC4qBsAAAAqG5sCCCCqE4GR",
	    "Grov\0\0el\0\0ing?\0\0\0\0\0\0"
	    "What\0\0\0\0a\0mess.\n\0\0");
      Play("4sB5D4B5D4AGAGetAA5EsGCGCetFFEqDFeE4G",
	    "Cre\0\0a\0\0tion\0\0\0\0st\0or\0y\0\0\0\0\0"
	    "is\0\0\0\0quite\0hip\0stir!\n\0");
      Play("4sB5D4B5D4AGAGetAA5EsGCGCetFFEqDFeE4G",
	    "(Rec\0\0re\0\0a\0\0tion\0\0\0\0al\0\0\0\0\0"
	    "bad\0\0\0\0\0trip\0stir.)\n\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
