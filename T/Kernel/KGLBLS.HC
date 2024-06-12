extern U0 GrInit2();
F64	*pow10_I64,
	sys_os_version=5.030;
CTextGlbls	text;
CCntsGlbls	cnts={1,0,2676302000,2676302,2676302000,14e6,14e3,HPET,FALSE};
CDbgGlbls dbg;
CDoc *sys_clip_doc;
U8  *(*fp_getstr2)(I64 flags=0);
CDoc *(*fp_doc_put)(CTask *task=NULL);
U0 (*fp_update_ctrls)(CTask *task)=NULL;
I64 sys_num_spawned_tasks;
CTask *sys_focus_task=Fs;
CTask *sys_winmgr_task,*sys_task_being_scrn_updated;
#help_index "Bit"
U8 *rev_bits_table, //Table with U8 bits revd
   *set_bits_table; //Table with count of set bits in a U8
#help_index ""
CGridGlbls	ms_grid; //See $LK,"::/Demo/Graphics/Grid.HC"$.
CMsStateGlbls	ms,ms_last;
CMsHardStateGlbls ms_hard;
CMsHardStateGlbls ms_hard_last;
CAutoCompleteDictGlbls acd;
CAutoCompleteGlbls ac;
F64 target_fps=30.;
public CWinMgrGlbls winmgr={0,0,0,WINMGR_FPS,tS,tS,NULL,FALSE,FALSE,FALSE};
winmgr.t=CAlloc(sizeof(CWinMgrTimingGlbls));
winmgr.t->last_calc_idle_time=tS;
CTask *sys_macro_task;
CKbdStateGlbls	kbd;
I64 sys_msg_flags[1]={0};
U0 (*fp_set_std_palette)();
asm {
SYS_PROGRESSES::
SYS_PROGRESS1::		DU64	0;
SYS_PROGRESS1_MAX::	DU64	0;
SYS_PROGRESS1_T0::	DU64	0;
SYS_PROGRESS1_TF::	DU64	0;
SYS_PROGRESS1_DESC::	DU8	PROGRESS_DESC_LEN DUP(0);
SYS_PROGRESS2::		DU64	0;
SYS_PROGRESS2_MAX::	DU64	0;
SYS_PROGRESS2_T0::	DU64	0;
SYS_PROGRESS2_TF::	DU64	0;
SYS_PROGRESS2_DESC::	DU8	PROGRESS_DESC_LEN DUP(0);
SYS_PROGRESS3::		DU64	0;
SYS_PROGRESS3_MAX::	DU64	0;
SYS_PROGRESS3_T0::	DU64	0;
SYS_PROGRESS3_TF::	DU64	0;
SYS_PROGRESS3_DESC::	DU8	PROGRESS_DESC_LEN DUP(0);
SYS_PROGRESS4::		DU64	0;
SYS_PROGRESS4_MAX::	DU64	0;
SYS_PROGRESS4_T0::	DU64	0;
SYS_PROGRESS4_TF::	DU64	0;
SYS_PROGRESS4_DESC::	DU8	PROGRESS_DESC_LEN DUP(0);
SYS_MP_CNT_LOCK::	DU64	1;
SYS_SEMAS::		DU8	SEMA_SEMAS_NUM*DFT_CACHE_LINE_WIDTH DUP(0);
};

public _extern SYS_PROGRESS1 I64 progress1; //Current progress 1.
public _extern SYS_PROGRESS1_DESC
	U8 progress1_desc[PROGRESS_DESC_LEN]; //Progress 1 desc.
public _extern SYS_PROGRESS1_MAX I64 progress1_max; //Progress 1 max.
public _extern SYS_PROGRESS1_T0 F64 progress1_t0; //Progress 1 start time.
public _extern SYS_PROGRESS1_TF F64 progress1_tf; //Progress 1 end time.
public _extern SYS_PROGRESS2 I64 progress2; //Current progress 2.
public _extern SYS_PROGRESS2_DESC
	U8  progress2_desc[PROGRESS_DESC_LEN]; //Progress 2 desc.
public _extern SYS_PROGRESS2_MAX I64 progress2_max; //Progress 2 max.
public _extern SYS_PROGRESS2_T0 F64 progress2_t0; //Progress 2 start time.
public _extern SYS_PROGRESS2_TF F64 progress2_tf; //Progress 2 end time.
public _extern SYS_PROGRESS3 I64 progress3; //Current progress 3.
public _extern SYS_PROGRESS3_DESC
	U8  progress3_desc[PROGRESS_DESC_LEN]; //Progress 3 desc.
public _extern SYS_PROGRESS3_MAX I64 progress3_max; //Progress 3 max.
public _extern SYS_PROGRESS3_T0 F64 progress3_t0; //Progress 3 start time.
public _extern SYS_PROGRESS3_TF F64 progress3_tf; //Progress 3 end time.
public _extern SYS_PROGRESS4 I64 progress4; //Current progress 4.
public _extern SYS_PROGRESS4_DESC
	U8  progress4_desc[PROGRESS_DESC_LEN]; //Progress 4 desc.
public _extern SYS_PROGRESS4_MAX I64 progress4_max; //Progress 4 max.
public _extern SYS_PROGRESS4_T0 F64 progress4_t0; //Progress 4 start time.
public _extern SYS_PROGRESS4_TF F64 progress4_tf; //Progress 4 end time.
public _extern SYS_PROGRESSES
	CProgress sys_progresses[PROGRESS_BARS_NUM]; //All progress bars.
CBlkDevGlbls	blkdev;
CGodGlbls god;
CKeyDevGlbls keydev;
