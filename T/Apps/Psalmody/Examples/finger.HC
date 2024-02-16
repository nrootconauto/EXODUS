//5 has words

U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      Play("5qEsC4B5C4BqA5RReG4RqAsG5G4G5G",
	    "Fin\0ger\0\0of\0\0God\n\0\0\0\0\0\0\0\0\0\0");
      Play("5qEsC4B5C4BqA5RReG4RqAsG5G4G5G",
	    "Light\0en\0\0the\0\0rod\n\0\0\0\0\0\0\0\0\0\0");
      Play("5qFetE4AGqGetGBG5sFDFD4qAeG5GqD",
	    "All\0of\0this\0strife\n\0\0"
	    "\0\0\0\0\0\0\0\0\0\0\0");
      Play("5FetE4AGqGetGBG5sFDFD4qAeG5GqD",
	    "Jump\0start\0my\0life\n\0\0\0"
	    "\0\0\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
