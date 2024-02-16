//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      "$$GREEN$$To God...$$FG$$\n";
      Play("M5/4");
      Play("5eEqCeEFEDC4qB5eEqCeEFEDC4qB",
	    "Fa\0ther,\0for\0give\0them\0if\0you\0must.\n\0"
	    "I'd\0like\0to\0see\0them\0turn\0to\0dust.\n\0");
      Play("M4/4");
      Play("5sG4B5G4BetA5F4G5eEFsEGEGqD4sB5D4B5DGFGF4etG5G4B");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
