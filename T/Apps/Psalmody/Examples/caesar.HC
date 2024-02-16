//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 1.765;
  music.stacatto_factor= 0.681;
  try {
    while (!ScanKey) {
      Play("5etC4B5CDDEqCDetEFGGGGEFAqE",
	    "Stab\0\0bed\0right\0in\0the\0back.\n\0"
	    "\0Right\0in\0the\0back\0\0\0by\0\0my\0friends.\n\0");
      Play("5etC4B5CDDEqCDetEFGGGGEFAqE",
	    "Stab\0\0bed\0right\0in\0the\0back.\n\0"
	    "\0Right\0in\0the\0back\0\0\0by\0\0my\0friends.\n\0");
      Play("5eEFetCGCeFCetG4B5GDEEeCEsGEGEeEG",
	    "\0How\0\0could\0\0you?\n\0"
	    "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0");
      Play("5EFetCGCeFCetG4B5GDEEeCEsGEGEeEG",
	    "\0How\0\0could\0\0you?\n\0"
	    "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
