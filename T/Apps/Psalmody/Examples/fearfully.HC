//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 1.710;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      Play("5eDsEDeEsFEqGeFEqCD4hA",
	    "God\0\0\0puts\0His\0\0hand\0"
	    "\0u\0pon\0my\0soul.\n\0");
      Play("5eFsFEGFeAqGeEFhDD",
	    "Lord,\0\0\0res\0cue\0\0me\0from\0this\0Shoel.\n\0\0");
      Play("5eDsEDeEsFEqGeFEqCD4hA",
	    "God\0\0\0puts\0His\0\0hand\0"
	    "\0u\0pon\0my\0soul.\n\0");
      Play("5eFsFEGFeAqGeEFhDD",
	    "Does\0\0\0He\0\0\0know\0my\0\0woe?\n\0\0");
      Play("5qE4sB5C4eB5sG4A5G4A5DCDC4eGG5sGD4eG5F4sA5E4B5C4eB",
	    "God\0\0\0\0have\0\0You...\0"
	    "\0\0\0\0\0\0\0for\0\0\0got\0ten\0\0me?\n\0\0\0");
      Play("5qE4sB5C4eB5sG4A5G4A5DCDC4eGG5sGD4eG5F4sA5E4B5C4eB",
	    "Satan\0\0\0\0has\0\0come\0"
	    "\0\0\0\0\0\0\0and\0\0\0fought\0en\0\0me.\n\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
