//5 no nothing
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.976;
  music.stacatto_factor= 0.538;
  try {
    while (!ScanKey) {
      Play("5qEDCDeEEqEeDDqD");
      Play("5EDCDeEEqEeDDqD");
      Play("5eD4A5sFDFDqFsF4B5F4BqGetBBB5qFC");
      Play("5eD4A5sFDFDqFsF4B5F4BqGetBBB5qFC");
    }
  } catch
    PutExcept;
  Snd;
}
 
Song;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
