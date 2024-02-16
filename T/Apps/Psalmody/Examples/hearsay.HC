//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      Play("4qA5eCDqE4A5eCDECDECsCC",
	    "I\0don't\0\0know.\n\0\0\0\0\0\0\0\0\0\0\0");
      Play("4qA5eCDqE4A5eCDECDECsCC",
	    "Let's\0go\0\0slow.\n\0\0\0\0\0\0\0\0\0\0\0");
      Play("5eD4A5G4A5qDsECECC4B5C4BeA5FsDCeGDE",
	    "You\0\0say\0\0that,\0God?\n\0\0\0"
	    "\0\0\0\0\0\0\0\0\0\0\0\0");
      Play("5D4A5G4A5qDsECECC4B5C4BeA5FsDCeGDE",
	    "It\0\0sounds\0\0odd.\n\0\0\0\0\0"
	    "\0\0\0\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
