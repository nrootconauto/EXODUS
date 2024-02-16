//5 has words
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo=2.5;
  try {
    while (!ScanKey) {
      Play("5sF4G5F4G5eGD4AGqG5eED4sAAAAeG5FsFGFG",
	    "In\0\0the\0\0twi\0light\0zone,\n\0"
	    "\0\0\0\0\0\0\0\0\0\0\0\0\0\0");
      Play("5F4G5F4G5eGD4AGqG5eED4sAAAAeG5FsFGFG",
	    "keep\0\0a\0\0friend\0ly\0tone.\n\0\0"
	    "\0\0\0\0\0\0\0\0\0\0\0\0\0");
      Play("5C4G5C4G5qFG4GG5sGDGDqGsDCDC",
	    "Mind\0\0in\0\0knots?\0\0\0\0Skip\0"
	    "\0de\0\0bait.\n\0\0\0\0\0");
      Play("5C4G5C4G5qFG4GG5sGDGDqGsDCDC",
	    "Watch\0\0those\0\0thoughts.\0\0\0\0"
	    "Head\0\0on\0\0straight.\n\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
