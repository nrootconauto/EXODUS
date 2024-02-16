//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  try {
    while (!ScanKey) {
      Play("5etDGDqGeCG4etA5E4G5eEFsG4B5G4B5qEG",
	    "Thanks,\0\0\0God!\0\0\0"
	    "You\0\0are\0might\0y\0\0good\0\0to\0me.\n\0\0");
      Play("5etDGDqGeCG4etA5E4G5eEFsG4B5G4B5qEG",
	    "Thanks,\0\0\0God!\0\0\0"
	    "You\0\0are\0might\0y\0\0good\0\0to\0me.\n\0\0");
      Play("5E4sB5G4B5GeEC4GA5qF4G5sC4G5C4GqG",
	    "\0\0\0\0\0\0\0"
	    "I\0won't\0tell.\n\0\0\0\0\0\0\0");
      Play("5E4sB5G4B5GeEC4GA5qF4G5sC4G5C4GqG",
	    "\0\0\0\0\0\0\0"
	    "I\0won't\0tell.\n\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
