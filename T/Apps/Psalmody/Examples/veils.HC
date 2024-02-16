//5 has words

$TR,"Reward1"$
$ID,2$CallExtStr("JukeReward",""
$TR,"Reward2"$
$ID,2$
"gels prominence Colombia Italy "
"bikini's Cheviot autograph's end "
"mailer psyche compliment's mukluk "
"fears animates unexplored esthetics "
"Cabernet catchphrase conglomerated almanac's "
$ID,-2$
);
$ID,-2$
U0 Song()
{
  CTask *task;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    task=PopUpViewPrint(
	  "$LK,"Exodus,34:29-36",A="BF:Exodus,34:29-36"$\n");
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    while (!ScanKey) {
	Play("5qCeEEqFDE4B5DC",
		"Shade\0my\0\0eyes\0the\0noon\0ap\0proach\0es.\n\0");
	Play("5eAAAGAGFGEFEDhC");
	Play("4qB5GF4BG5eGDqGeFG",
		"Look\0a\0way.\n\0\0\0Oy!\n\0\0\0\0\0");
	Play("4qB5GF4BG5eGDqGeFG",
		"Hot\0to\0day!\n\0\0\0Oy!\n\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
