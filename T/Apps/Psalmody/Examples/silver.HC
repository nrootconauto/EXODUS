//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      Play("5qF4GsGGGG5GFGF4qA5eD4G5etD4B5EsFCFC",
	    "Love\0\0\0\0\0\0ev\0\0ery\0\0sec\0ond.\n\0"
	    "\0\0\0\0\0\0\0\0");
      Play("5qF4GsGGGG5GFGF4qA5eD4G5etD4B5EsFCFC",
	    "World--\0\0\0\0\0\0all\0\0that\0\0beck\0ons.\n\0"
	    "\0\0\0\0\0\0\0\0");
      Play("4qB5GFsE4A5E4A5qEFGeFC",
	    "\0Life\0is\0too\0\0\0\0prec\0i\0ous.\n\0\0\0");
      Play("4qB5GFsE4A5E4A5qEFGeFC",
	    "\0Can\0be\0\0\0\0\0worr\0i\0ous.\n\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
