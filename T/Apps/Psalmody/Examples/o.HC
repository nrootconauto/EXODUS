//5 no nothing
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      Play("5sCGCG4etA5DD4sG5G4G5GF4A5F4A5DDDDqG4sBGBG5qG");
      Play("5sCGCG4etA5DD4sG5G4G5GF4A5F4A5DDDDqG4sBGBG5qG");
      Play("5eG4G5qE4eAsAGqA5sE4A5E4A5DEDEqF4eAG");
      Play("5G4G5qE4eAsAGqA5sE4A5E4A5DEDEqF4eAG");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
