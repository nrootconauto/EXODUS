//5 has words

U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      DocClear;
      Play("4qBeBGqG5D4BeAGqR5etGED",
	    "Sees\0the\0\0end\0from\0the\0start.\n\0\0\0\0\0\0");
      Play("4qBeBGqG5D4BeAGqR5etGED",
	    "Got\0Heav\0\0en\0down\0to\0art.\n\0\0\0\0\0When\0");
      Play("4eBG5qGRsFEFEC4B5C4BqGG5etDRD",
	    "filled\0with\0doubt.\n\0\0\0\0\0\0"
	    "\0\0\0\0\0\0It'\0\0ll\0");
      Play("4eBG5qGRsFEFEC4B5C4BqGG5etDRD",
	    "all\0work\0out.\n\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
