//5 has words

$TR,"Reward1"$
$ID,2$CallExtStr("JukeReward",""
$TR,"Reward2"$
$ID,2$
"anyhow agility Spenser's Nannie's "
"lettering's educational Leticia's gobbler "
"impales Susana incubators Julliard's "
"Yahoo's Spirograph's joblessness fastenings "
"prosecutor's quells collage's bluefish "
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
      Play("5eEEE4B5DDD4A5CCCDEC4qA",
	    "Spring\0ing\0down\n\0the\0bun\0ny\0trail.\n\0"
	    "\0Hap\0py\0rush.\n\0There's\0hay\0to\0bail.\n\0");
      Play("5eCEE4A5FEDEEDCDECqE",
	    "Ada\0wise?\n\0\0\0Thun\0der\0sighs.\n\0"
	    "\0\0\0\0\0Great\0big\0fail.\n\0");
      Play("eG4AqA5Ge.CsCqF4eABAGB5sFG",
	    "Bob\0-n-\0\0weave?\n\0\0\0\0\0\0\0\0\0\0\0");
      Play("eG4AqA5Ge.CsCqF4eABA5C4B5sFG",
	    "Heft\0y\0\0heave.\n\0\0\0\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
