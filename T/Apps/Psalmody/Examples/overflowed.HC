//5 has words

$TR,"Reward1"$
$ID,2$CallExtStr("JukeReward",""
$TR,"Reward2"$
$ID,2$
"pocketing refocus Dana's chiaroscuro "
"Lela's bunt's Brahmans lacy "
"Limousin's spatters bedraggle trade's "
"briquets breeding's dethronement's avariciously "
"foodstuff dwarf's botany's tiff's "
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
	"$LK,"Matthew,25:11-12",A="BF:Matthew,25:11-13"$\n"
	"$LK,"Luke,13:25-28",A="BF:Luke,13:25-28"$\n");
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    while (!ScanKey) {
      Play("5eC4B5qC4eBB5qD4B5ED4B",
	    "\0\0\0I'm\0\0busy.\n\0\0\0\0\0");
      Play("5eCC4qBeBB5C4BM2/4",
	    "\0\0\0Who\0the\0hell\0are\0");
      Play("5hDM4/4",
	    "you?\n\0");
      Play("4eAB5qC4eBB5qD4B5ED4B",
	    "\0\0\0Gee\0\0wizzy.\n\0\0\0\0\0");
      Play("5eCC4qBeBB5C4BM2/4",
	    "\0\0\0Some\0one\0close\0the\0");
      Play("5q.DeCM4/4",
	    "flue.\n\0It's\0");
      Play("qE4AA5etG4A5CsD4A5D4A5etDDDGGCFFF",
	    "me?\n\0\0\0\0\0\0\0\0\0"
	    "\0\0\0\0\0\0\0Char\0\0it\0");
      Play("qE4AA5etG4A5CsD4A5D4A5etDDDsEDDE4B5D4B5C",
	    "y.\n\0\0\0\0\0\0\0\0\0"
	    "\0\0\0\0\0\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  Snd;
}

Song;
