//5 has words

$TR,"Reward1"$
$ID,2$CallExtStr("JukeReward",""
$TR,"Reward2"$
$ID,2$
"codas hulks Pugh surf "
"welt's boondoggled beacon Thurs "
"antipathy avoid Fulani's pollinated "
"debts Ronny encapsulated overcoat's "
"bikers Jenkins closes splice's "
$ID,-2$
);
$ID,-2$
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    while (!ScanKey) {
      Play("5qEeCDE4B5CD4qA5D4eBq.G",
	    "I'm\0in\0the\0shad\0ow\n\0"
	    "of\0the\0hand\0of\0God.\n\0\0");
      Play("5qEeCFqEeCD4qA5D4hB",
	    "I\0won't\0be\0left\n\0"
	    "in\0\0Hell\0for\0long.\n\0");
      Play("5qGEeFGqD4B5eDG4qA5eGF",
	    "\0\0\0\0\0\0Be\0\0"
	    "strong.\n\0\0\0");
      Play("qGEeFGqD4B5eDG4qA5eFG",
	    "\0\0\0\0\0\0Could\0"
	    "be\0wrong.\n\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
