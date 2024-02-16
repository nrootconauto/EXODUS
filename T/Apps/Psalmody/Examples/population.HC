//5 has words

$TR,"Reward1"$
$ID,2$CallExtStr("JukeReward",""
$TR,"Reward2"$
$ID,2$
"applicant's briquettes raft Alexandra "
"edification grumbler immensities Casandra's "
"hosted Northwest impediments egoists "
"stolider quiche Aussie's Albanian "
"godparents Xmas Mycenae haze "
$ID,-2$
);
$ID,-2$
U0 Song()
{
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.780;
  try {
    while (!ScanKey) {
      Play("5eCD4B5C4AFFF5C4F5E4FAF5sEEeD",
	    "C.\0I.\0A.\0in\0charge.\n\0"
	    "\0\0\0Got\0\0locked\0\0down.\n\0\0No\0\0more\0");
      Play("F4FFF5qCeF4F5F4FFF5qCeF4F",
	    "birth.\n\0\0\0\0\0Derp\0y\0dearth.\n\0"
	    "\0\0\0\0\0\0");
      Play("5qGsE4A5E4AqB5etDCF4qG5DsGDGDetCRC",
	    "Whiten\0the\0\0heat\n\0\0\0\0"
	    "\0\0\0\0in\0\0the\0\0jun\0\0gle.\n\0");
      Play("qGsE4A5E4AqB5etDCF4qG5DsGDGDetCRC",
	    "Brain\0starts\0to\0beat\n\0\0\0"
	    "\0\0\0\0\0in\0\0the\0\0rum\0\0ble.\n\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
