#help_index "Compiler/Directive"
public extern I8i Option(I64i num,I8i val);
public extern I64 PopUpTourPart();
#help_index ""
#help_index "AutoComplete"
#help_file "::/Doc/AutoComplete"
public extern CAutoCompleteGlbls ac;

#help_index "AutoComplete/Dictionary"
public extern CAutoCompleteDictGlbls acd;

#help_index "Bit"
#help_file "::/Doc/Bit"


#help_index "Boot"
#help_file "::/Doc/Boot"
public extern U0 Reboot();


#help_index "Char/BitMaps"
public extern U32 char_bmp_alpha[16],char_bmp_alpha_numeric[16],
char_bmp_alpha_numeric_no_at[16],	char_bmp_word[16],
char_bmp_dec_numeric[16],		char_bmp_hex_numeric[16],
char_bmp_white_space[16],		char_bmp_non_eol_white_space[16],
char_bmp_zero_cr_nl_cursor[16],	char_bmp_zero_tab_cr_nl_cursor[16],
char_bmp_zero_tab_cr_nl_cursor_dollar[16],
char_bmp_macro[16],			char_bmp_printable[16],
char_bmp_displayable[16],		char_bmp_safe_dollar[16],
char_bmp_filename[16],			char_bmp_non_eol[16];

#help_index "Char/Conversion"
public extern U8 *Char2KeyName(I64 ch,Bool include_ctrl=TRUE);
public extern I64 Char2ScanCode(I64 ch,I64 sc_flags=0);
public extern U8 ScanCode2Char(I64 sc);
public extern U8 *ScanCode2KeyName(I64 sc);
public extern F64 Str2F64(U8 *src,U8 **_end_ptr=NULL);
public extern I64 Str2I64(U8 *st,I64 radix=10,U8 **_end_ptr=NULL);
public extern U8 *StrScan(U8 *src,U8 *fmt,...);

#help_index "Char/Conversion;Time/Date/CDate;Date/CDate"
public extern CDate Str2Date(U8 *src);

#help_index "Char/Flags"
public extern U0 ScanFlags(U8 *_dst_flags,U8 *lst,U8 *src);
public extern U8 *StrPrintFlags(U8 *dst,U8 *lst,I64 flags);

#help_index "Char/Lists"
public extern I64 LstMatch(U8 *needle, U8 *haystack_lst,I64 flags=0);
public extern U8 *LstSub(I64 sub, U8 *lst);

#help_index "Char/Operations"
public extern U8 *MStrPrint(U8 *fmt,...);
public extern U8 *MStrUtil(U8 *src,I64 flags,F64 indent_scale_factor=0);
public extern U8 *ScaleIndent(U8 *src,F64 indent_scale_factor);
public extern I64 Spaces2Tabs(U8 *dst,U8 *src);
public _extern _STRCMP I64 StrCmp(U8 *st1,U8 *st2);
public _extern _STRCPY U0 StrCpy(U8 *dst,U8 *src);
public extern U8 *StrFind(U8 *needle,U8 *haystack_str,I64 flags=0);
public extern U8 *StrFirstOcc(U8 *src,U8 *marker);
public extern U8 *StrFirstRem(U8 *src,U8 *marker,U8 *dst=NULL);
public _extern _STRICMP I64 StrICmp(U8 *st1,U8 *st2);
public _extern _STRIMATCH U8 *StrIMatch(U8 *needle,U8 *haystack_str);
public extern U8 *StrLastOcc(U8 *src,U8 *marker);
public extern U8 *StrLastRem(U8 *src,U8 *marker,U8 *dst=NULL);
public _extern _STRMATCH U8 *StrMatch(U8 *needle,U8 *haystack_str);
public _extern _STRNCMP I64 StrNCmp(U8 *st1,U8 *st2,I64 n);
public _extern _STRNICMP I64 StrNICmp(U8 *st1,U8 *st2,I64 n);
public extern I64 StrOcc(U8 *src, U8 ch);
public extern U8 *StrPrint(U8 *dst,U8 *fmt,...);
public extern U8 *StrPrintJoin(U8 *dst,U8 *fmt,I64 argc,I64 *argv);
public extern U8 *StrUtil(U8 *_src,I64 flags);
public extern U8 *Tabs2Spaces(U8 *src);
public extern Bool WildMatch(U8 *test_str,U8 *wild_str);

#help_index "Char/Operations;Memory"
public extern U8 *CatPrint(U8 *dst,U8 *fmt,...);

#help_index "Char/Operations;Memory/Adam Heap"
public extern U8 *AStrNew(U8 *buf);

#help_index "Char/Operations;Memory/Heap"
public extern U8 *StrNew(U8 *buf,CTask *mem_task=NULL);

#help_index "Char/Output;StdOut"
public extern U0 GetOutOfDollar();
public extern Bool IsSilent();
public extern U0 Print(U8 *fmt,...);
public extern U0 PrintErr(U8 *fmt,...);
public extern U0 PrintWarn(U8 *fmt,...);
public extern U0 PutChars(U64 ch);
public extern U0 PutHex(I64 num,I64 width);
public extern U0 PutKey(I64 ch=0,I64 sc=0);
public extern U0 PutS(U8 *st); //Use $$LK,"Print",A="MN:Print"$$()
public extern Bool Silent(Bool val=ON);
public extern U8 *StrPrintHex(U8 *dst,I64 num;I64 width);

#help_index "Char;Debugging/Raw Output;TextBase Layer/Char"
public extern CTextGlbls text;

#help_index "Compiler/Lex"
public extern U0 HashSrcFileSet(CCmpCtrl *cc,
	CHashSrcSym *h,I64 line_num_offset=0);

#help_index "Compiler;Cmd Line (Typically)"
extern U8 *Load(U8 *filename,I64 ld_flags=0,
	CBinFile *bfh_addr=INVALID_PTR); //INVALID_PTR=don't care what load addr

#help_index "Compression"
public extern CArcCompress *CompressBuf(U8 *src,I64 size,CTask *mem_task=NULL);
public extern U8 *ExpandBuf(CArcCompress *arc,CTask *mem_task=NULL);

#help_index "Compression/Piece by Piece"
public extern U0 ArcCompressBuf(CArcCtrl *c);
public extern U0 ArcCtrlDel(CArcCtrl *c);
public extern CArcCtrl *ArcCtrlNew(Bool expand,I64 compression_type=CT_8_BIT);
public extern U0 ArcExpandBuf(CArcCtrl *c);
public extern Bool ArcFinishCompression(CArcCtrl *c);

#help_index "Data Types/Circular Queue"
public extern I64	QueCnt(CQue *head);
public extern CQue	*QueCopy(CQue *head,CTask *mem_task=NULL);
public extern U0	QueDel(CQue *head,Bool querem=FALSE);
public extern I64	QueSize(CQue *head);

#help_index "Data Types/Fifo"
public extern I64	FifoI64Cnt(CFifoI64 *f);
public extern U0	FifoI64Del(CFifoI64 *f);
public extern U0	FifoI64Flush(CFifoI64 *f);
public extern Bool	FifoI64Ins(CFifoI64 *f,I64 q);
public extern CFifoI64	*FifoI64New(I64 size,CTask *mem_task=NULL);
public extern Bool	FifoI64Peek(CFifoI64 *f,I64 *_q);
public extern Bool	FifoI64Rem(CFifoI64 *f,I64 *_q);
public extern I64	FifoU8Cnt(CFifoU8 *f);
public extern U0	FifoU8Del(CFifoU8 *f);
public extern U0	FifoU8Flush(CFifoU8 *f);
public extern Bool	FifoU8Ins(CFifoU8 *f,U8 b);
public extern CFifoU8	*FifoU8New(I64 size,CTask *mem_task=NULL);
public extern Bool	FifoU8Peek(CFifoU8 *f,U8 *_b);
public extern Bool	FifoU8Rem(CFifoU8 *f,U8 *_b);

#help_index "Data Types/Linked List"
public extern I64	LinkedLstCnt(U8 **_lst);
public extern U8	*LinkedLstCopy(U8 **_lst,CTask *mem_task=NULL);
public extern U0	LinkedLstDel(U8 **_lst);
public extern I64	LinkedLstSize(U8 **_lst);

#help_index "Data Types/Queue Vector"
public extern U0	QueVectU8Del(CQueVectU8 *v);
public extern I64	QueVectU8Get(CQueVectU8 *v,I64 idx);
public extern CQueVectU8 *QueVectU8New(I64 min_idx=0);
public extern U0	QueVectU8Put(CQueVectU8 *v,I64 idx,U8 ch);

#help_index "Debugging"
public extern U8 *Caller(I64 num=1);
public extern Bool ChkCodePtr(U8 *ptr);
public extern Bool ChkOnStk(U8 *ptr,CTask *task=NULL);
public extern Bool ChkPtr(U8 *ptr);
public extern Bool IsSingleUser();
public extern Bool IsSysDbg();
public extern Bool SingleUser(Bool val);
public extern Bool SysDbg(Bool val);
public extern U8 *TaskCaller(CTask *task=NULL,
	I64 num=0,Bool saved_context=FALSE);
public extern I64 UnusedStk(CTask *task=NULL);
public extern CDbgGlbls dbg;

#help_index "Debugging/Debugger"
public extern Bool B(U8 *addr,CTask *task=NULL,Bool live=TRUE); //Toggle bpt.
public extern I64 B2(CTask *task=NULL,Bool live=TRUE);
public extern CBpt *BptFind(U8 *needle_addr,CTask *haystack_task=NULL,Bool rem=FALSE);
public extern Bool BptR(U8 *addr,CTask *task=NULL,Bool live=TRUE,Bool rem=TRUE);
public extern Bool BptS(U8 *addr,CTask *task=NULL,Bool live=TRUE);
public extern Bool DbgMode(Bool val);
public extern Bool E(U8 *addr,I64 cnt=512,I64 edf_dof_flags=0);
public extern Bool EdLite(U8 *filename,I64 num=1,I64 edf_dof_flags=0);
extern Bool EdLiteFileLine(U8 *fl_file_line,I64 edf_dof_flags=0);
public extern Bool Fix(I64 edf_dof_flags=0);
public extern U0 FixSet(U8 *filename,I64 line);
public extern U0 G(U8 *ms=INVALID_PTR,CTask *task=NULL);
public extern U0 G2(U8 *ms=INVALID_PTR,CTask *task=NULL);
public extern Bool IsDbgMode();
public extern U0 S(U8 *ms=INVALID_PTR,CTask *task=NULL);

#help_index "Debugging/Debugger;DolDoc/Cmd Line (Typically);"\
	"Cmd Line (Typically);Help System"
public extern Bool Man(U8 *st,I64 edf_dof_flags=0);

#help_index "Debugging/Dump"
public extern U0 CallerRep(U8 **rbp=NULL,CTask *task=NULL);
public extern U0 D(U8 *addr,I64 cnt=0x80,Bool show_offset=TRUE);
public extern U0 Da(U8 **addr,I64 cnt=0x10);
public extern U0 Dm(U8 *addr,I64 cnt=0x80);
public extern U0 Dr(CTask *task=NULL);
public extern U0 StkRep(CTask *task=NULL);
extern I64 *TaskRegAddr(CTask *task,I64 reg_num);

#help_index "Debugging/FunSeg"
#help_file "::/Doc/DbgFunSeg"
public extern Bool PutSrcLink(U8 *addr,I64 cnt=1,U8 *buf=NULL);
public extern U8 *SrcEdLink(U8 *addr,I64 cnt=1,CTask *mem_task=NULL);
public extern U8 *SrcFileName(U8 *addr,I64 cnt=1,CTask *mem_task=NULL);
public extern I64 SrcLineNum(U8 *addr,I64 cnt=1);

#help_index "Debugging/FunSeg;Hash/System"
public extern CHash *FunSegFind(U8 *addr,I64 *_offset);

#help_index "Debugging/Raw Output"
public extern Bool IsRaw();
public extern Bool Raw(Bool val);
public extern U0 RawD(I64 mS=100,U8 *addr,I64 cnt=0x80);
public extern U0 RawDm(I64 mS=100,U8 *addr,I64 cnt=0x80);
public extern U0 RawDr(CTask *task=NULL);
public extern U0 RawPrint(I64 mS=100,U8 *fmt,...);
public extern U0 RawPutChar(I64 ch);
public extern U0 VGAFlush();

#help_index "Debugging;Debugging/Debugger"
public extern U0 Dbg(U8 *msg=NULL,I64 msg_num=0);
public extern U0 Panic(U8 *msg=NULL,I64 msg_num=0,Bool panic=TRUE);

#help_index "Define;Char/Define"
#help_file "::/Doc/Define"
public extern U8 *Define(U8 *dname);
public extern CHashDefineStr *DefineLoad(U8 *dname,U8 *st);
public extern U0 DefinePrint(U8 *dname,U8 *src,...);

#help_index "Define;Char/Define;Char/Lists"
public extern I64 DefineCnt(U8 *dname);
public extern CHashDefineStr *DefineLstLoad(U8 *dname,U8 *lst);
public extern I64 DefineMatch(U8 *needle,U8 *haystack_lst_dname,I64 flags=0);
public extern U8 *DefineSub(I64 sub,U8 *dname);

#help_index "DolDoc/Clip"
public extern CDoc *sys_clip_doc;

#help_index "DolDoc/Task;StdOut/Task"
#help_file "::/Doc/StdOutTask"
extern CDoc *(*fp_doc_put)(CTask *task=NULL);

#help_index "Exceptions"
public extern U0 Break();
public extern Bool BreakLock(CTask *task=NULL);
public extern Bool BreakUnlock(CTask *task=NULL);
public extern U0 PutExcept(Bool catch_it=TRUE);
extern U0 SysTry(U8 *start_label,U8 *skip_label);
extern U0 SysUntry();
public extern U0 throw(I64 ch=0,Bool no_log=FALSE);

#help_index "File/CD DVD"
public extern U0 DVDImageRead(U8 dvd_drv_let,U8 *out_name);
public extern U0 DVDImageWrite(U8 dvd_drv_let,
	U8 *in_name=NULL,I64 media_type=MT_DVD);

#help_index "File/CFile"
public extern Bool FBlkRead(CFile *f,U8 *buf,I64 blk=FFB_NEXT_BLK,I64 cnt=1);
public extern Bool FBlkWrite(CFile *f,U8 *buf,I64 blk=FFB_NEXT_BLK,I64 cnt=1);
public extern U0 FClose(CFile *f);
public extern CFile *FOpen(U8 *filename,U8 *flags,I64 cnt=0,CTask *mem_task=NULL);
public extern I64 FSize(CFile *f);

#help_index "File/Cmd Line (Typically);Cmd Line (Typically)"
public extern Bool Cd(U8 *dirname=NULL,Bool make_dirs=FALSE);
public extern I64 Del(U8 *files_find_mask,Bool make_mask=FALSE,
	Bool del_dir=FALSE,Bool print_msg=TRUE);
public extern I64 Dir(U8 *files_find_mask="*",Bool full=FALSE);
public extern Bool DirMk(U8 *filename,I64 entry_cnt=0);
public extern Bool Drv(U8 drv_let);
public extern U0 DskChg(U8 drv_let=0);
public extern U0 HomeSet(U8 *dirname);

#help_index "File/Cmd Line (Typically);Cmd Line (Typically);Install"
public extern Bool DrvMap(U8 drv_let,CDrv *dv);

#help_index "File/FileNames"
extern CDirEntry *Cd2DirEntry(CDirEntry *tmpde,U8 *abs_name);
public extern U8 *DirCur(CTask *task=NULL,CTask *mem_task=NULL);
public extern U8 *DirFile(U8 *dirname,U8 *name=NULL,U8 *_extension=NULL);
public extern U8 *DirNameAbs(U8 *dirname);
public extern CBlkDev *DrvIsWritable(U8 drv_let=0,Bool except=FALSE);
public extern U8 *ExtChg(U8 *filename,U8 *extension);
public extern U8 *ExtDft(U8 *filename,U8 *extension);
public extern U8 *FileExtDot(U8 *src);
public extern U8 *FileExtRem(U8 *src,U8 *dst=NULL);
public extern U8 *FileNameAbs(U8 *filename,I64 fuf_flags=0);
public extern Bool FileNameChk(U8 *filename);
public extern Bool FilesFindMatch(U8 *_test_name,
	U8 *files_find_mask,I64 fuf_flags=0);
public extern Bool IsDir(U8 *dir_name);
public extern Bool IsDotC(U8 *filename);
public extern Bool IsDotZ(U8 *filename);
public extern U0 PutDirLink(U8 *dirname,U8 *full_name=NULL);
public extern U0 PutFileLink(U8 *filename,U8 *full_name=NULL,
	I64 line=0,Bool plain_text=FALSE);
public extern U0 ToFileLine(U8 *_fl_file_line,U8 **_filename,I64 *_linenum);
public extern U8 *ToggleZorNotZ(U8 *name);

#help_index "File/FileNames;Misc"
public extern U8 *FileNameTmpTxt();

#help_index "File/Internal"
public extern U0 DirContextDel(CDirContext *dirc,Bool restore=TRUE);
public extern CDirContext *DirContextNew(U8 *mask,
	Bool make_mask=FALSE,Bool make_dirs=FALSE,Bool no_mask=FALSE);
public extern Bool DirNew(CDrv *dv,U8 *cur_dir,
	CDirEntry *tmpde,Bool free_old_chain=TRUE);
extern I64 FileAttr(U8 *name,I64 old_attr=0);

#help_index "File/Low Level"
#help_file "::/Doc/FileLowLevel"
public extern CBlkDev *BlkDevChk(CBlkDev *bd,Bool except=TRUE);
public extern U0 BlkDevDel(CBlkDev *bd);
public extern Bool BlkDevLock(CBlkDev *bd);
public extern CBlkDev *BlkDevNextFreeSlot(U8 first_drv_let,I64 type);
public extern Bool BlkDevUnlock(CBlkDev *bd,Bool rst=FALSE);
public extern U0 BlkDevsRelease();
public extern Bool BlkRead(CDrv *dv,U8 *buf, I64 blk, I64 cnt);
public extern Bool BlkWrite(CDrv *dv,U8 *buf, I64 blk, I64 cnt);
public extern U0 BlkWriteZero(CDrv *dv,I64 blk,I64 cnt);
public extern I64 Clus2Blk(CDrv *dv,I64 c);
public extern I64 ClusAlloc(CDrv *dv,I64 c=0,
	I64 cnt=1,Bool contiguous=FALSE);
public extern I64 ClusBlkRead(CDrv *dv,U8 *buf,I64 c,I64 blks);
public extern I64 ClusBlkWrite(CDrv *dv,U8 *buf,I64 c,I64 blks);
public extern I64 ClusNumNext(CDrv *dv,I64 c,I64 cnt=1);
public extern I64 ClusRead(CDrv *dv,U8 *buf,I64 c,I64 cnt);
public extern I64 ClusWrite(CDrv *dv,U8 *buf,I64 c,I64 cnt);
public extern Bool CopySingle(U8 *f1,U8 *f2); //Just one file
public extern U8 Drv2Let(CDrv *dv=NULL);
public extern CDrv *DrvChk(CDrv *dv,Bool except=TRUE);
public extern U0 DrvDel(CDrv *dv);
public extern Bool DrvLock(CDrv *dv);
public extern CDrv *DrvMakeFreeSlot(U8 drv_let);
public extern U8 *DrvModelNum(U8 drv_let=0);
public extern U8 DrvNextFreeLet(U8 first_drv_let='C');
public extern U8 *DrvSerialNum(U8 drv_let=0);
public extern U8 DrvTextAttrGet(U8 drv_let=0);
public extern Bool DrvUnlock(CDrv *dv,Bool rst=FALSE);
public extern U0 DrvsRelease();
extern U0 FAT32FreeClus(CDrv *dv,I64 c);
public extern CBlkDev *Let2BlkDev(U8 drv_let=0,Bool except=TRUE);
public extern I64 Let2BlkDevType(U8 drv_let);
public extern CDrv *Let2Drv(U8 drv_let=0,Bool except=TRUE);
public extern U8 Let2Let(U8 drv_let=0);
extern I64 Name2DirClus(CDrv *dv,U8 *dirname);
extern I64 Name2ParentDirClus(CDrv *dv,U8 *dirname);
extern U0 RedSeaFreeClus(CDrv *dv,I64 c,I64 cnt);

#help_index "File/Program Routines"
public extern U0 DirEntryDel(CDirEntry *tmpde);
public extern U0 DirEntryDel2(CDirEntry *tmpde);
public extern U0 DirTreeDel(CDirEntry *tmpde);
public extern U0 DirTreeDel2(CDirEntry *tmpde);
public extern Bool FileFind(U8 *filename,CDirEntry *_de=NULL,I64 fuf_flags=0);
public extern U8 *FileRead(U8 *filename,I64 *_size=NULL,I64 *_attr=NULL);
public extern I64 FileWrite(U8 *filename,
	U8 *fbuf,I64 size,CDate cdt=0,I64 attr=0);

#help_index "File/Program Routines;File/FileNames"
public extern CDirEntry *FilesFind(U8 *files_find_mask,I64 fuf_flags=0);

#help_index "File/System"
public extern U0 DskCacheInvalidate(CDrv *dv);

#help_index "Graphics/Color"
extern U0 (*fp_set_std_palette)();
public extern U8 *Color2Str(U8 *buf,CColorROPU32 c);
public extern CColorROPU16 Str2ColorU16(U8 *st);
public extern CColorROPU32 Str2ColorU32(U8 *st);

#help_index "Hash"
#help_file "::/Doc/Hash"
public _extern _HASH_ADD U0 HashAdd(CHash *tmph,CHashTable *table);
public _extern _HASH_ADD_AFTER U0 HashAddAfter(CHash *tmph,
	CHash *pred,CHashTable *table); //Add hash entry after entry.
public _extern _HASH_BUCKET_FIND CHash **HashBucketFind(
	U8 *needle_str,CHashTable *haystack_table);
public _extern _HASH_FIND CHash *HashFind(U8 *needle_str,
	CHashTable *haystack_table,I64 mask,I64 instance=1);
public _extern _HASH_SINGLE_TABLE_FIND CHash *HashSingleTableFind(
	U8 *needle_str,CHashTable *haystack_table,I64 mask,I64 instance=1);
public _extern _HASH_STR I64 HashStr(U8 *st);
public extern CHashTable *HashTableNew(I64 size,CTask *mem_task=NULL);

#help_index "Hash/Frame"
#help_file "::/Doc/Frame"
public extern I64 FramePtr(U8 *name,CTask *task=NULL);
public extern CHashGeneric *FramePtrAdd(U8 *name,I64 val=0,CTask *task=NULL);
public extern I64 FramePtrDel(U8 *name,CTask *task=NULL);
public extern I64 FramePtrSet(U8 *name,I64 val,CTask *task=NULL);

#help_index "Hash/System"
public extern U0 HashDel(CHashSrcSym *tmph);
public extern CHashGeneric *HashGenericAdd(U8 *name,
	I64 type,I64 val=0,I64 u8=0,I64 u16=0,CTask *task=NULL);
public extern CHashGeneric *HashPublic(U8 *st,I64 mask,Bool val=TRUE);
public _extern _HASH_REM_DEL Bool HashRemDel(CHash *tmph,CHashTable *table,
	I64 instance=1);//instance must match tmph's
public extern U0 HashTableDel(CHashTable *table);
public extern I64 HashTablePurge(CHashTable *table);
public extern I64 HashTypeNum(CHash *tmph);
public extern I64 HashVal(CHash *tmph);
extern U0 SysSymImportsResolve(U8 *sptr,I64 ld_flags=0);

#help_index "Hash/System;Char/Lists"
public extern I64 HashLstAdd(U8 *lst,I64 type,CHashTable *table);

#help_index "Hash/System;Define;Char/Define;Char/Lists"
public extern I64 HashDefineLstAdd(U8 *dname,I64 type,CHashTable *table);

#help_index "Help System;Debugging/Debugger"
public extern U0 Help();

#help_index "Info;File/Cmd Line (Typically);Cmd Line (Typically);Install"
public extern U0 DrvRep();

#help_index "Install"
#help_file "::/Doc/Install"
extern CATARep *ATARepFind(CATARep *haystack_head,I64 needle_num);
public extern Bool DrvEnable(U8 drv_let,Bool val);

#help_index "Install;File/Cmd Line (Typically);Cmd Line (Typically);"
public extern U0 Fmt(U8 drv_let,Bool quick=TRUE,
	Bool confirm=TRUE,I64 type=FSt_FAT32);

#help_index "Install;Memory/BlkPool"
public extern I64 Scale2Mem(I64 min,I64 max,I64 limit=2*1024*1024*1024);

#help_index "Job/Exe;Task/Job/Exe"
public extern U0 AdamErr(U8 *fmt,...);
public extern U0 AdamLog(U8 *fmt,...);
public extern I64 ExeCmdLine(CCmpCtrl *cc);
public extern U0 JobDel(CJob *tmpc);
public extern I64 JobsHndlr(I64 run_flags,CTask *task=NULL);
extern U0 SrvCmdLine(I64 dummy=0);
public extern U0 SrvTaskCont();
public extern CJob *TaskExe(CTask *srv,CTask *master,U8 *data,I64 flags);
public extern U0 TaskRstAwaitingMsg(CTask *task=NULL);
public extern U0 UserTaskCont();

#help_index "Job/Exe;Task/Job/Exe;Compiler"
public extern I64 Adam(U8 *fmt,...);
public extern I64 PopUp(U8 *buf,CTask *parent=NULL,CTask **_pu_task=NULL);
public extern I64 PopUpPrint(U8 *fmt,...);

#help_index "Job/Exe;Task/Job/Exe;MultiCore"
public extern I64 JobResGet(CJob *rqst=NULL);
public extern Bool JobResScan(CJob *rqst=NULL,I64 *_res=NULL);

#help_index "Job/Text & Msgs;Task/Job/Text & Msgs"
public extern CJob *TaskText(CTask *srv,CTask *master,U8 *data,I64 flags);

#help_index "Job/Text & Msgs;Task/Job/Text & Msgs;InFile;StdIn/InFile"
public extern U0 In(U8 *fmt,...);
public extern U0 InFile(U8 *filename);
public extern U0 InStr(U8 *fmt,...);
public extern U0 XTalk(CTask *task,U8 *fmt,...);
public extern U0 XTalkStr(CTask *task,U8 *fmt,...);
public extern U0 XTalkStrWait(CTask *task,U8 *fmt,...);
public extern U0 XTalkWait(CTask *task,U8 *fmt,...);

#help_index "Job/Text & Msgs;Task/Job/Text & Msgs;Messages"
public extern U0 Msg(I64 msg_code,I64 arg1,I64 arg2,I64 flags=0);
public extern U0 PostMsg(CTask *task,
	I64 msg_code,I64 arg1,I64 arg2,I64 flags=0);
public extern U0 PostMsgWait(CTask *task,I64 msg_code,
	I64 arg1,I64 arg2,I64 flags=0);
public extern CJob *TaskMsg(CTask *srv,CTask *master,
		     I64 msg_code,I64 arg1,I64 arg2,I64 flags);

#help_index "Job;Task/Job"
#help_file "::/Doc/Job"

#help_index "Keyboard Devices/System;Char/System"
#help_file "::/Doc/KeyDev"
public extern U0 CtrlAltCBSet(U8 ch,U0 (*fp_hndlr)(I64 sc),
	U8 *no_shift_desc=NULL,U8 *shift_desc=NULL,Bool in_irq=FALSE);
public extern U0 KeyDescSet(U8 *fmt,...);
public extern CKeyDevEntry *KeyDevAdd(Bool (*fp_put_key)(I64 ch,I64 sc),
	Bool (*fp_puts)(U8 *st),I64 priority,Bool key_descs=FALSE);
public extern U0 KeyDevRem(CKeyDevEntry *tmpk);
extern CKeyDevGlbls keydev;
extern CJob sys_macro_head;
extern CTask *sys_macro_task;

#help_index "Keyboard Devices;Char/Input;StdIn"
extern U8  *(*fp_getstr2)(I64 flags=0); //GetStr $$LK,"Flags",A="MN:GSF_SHIFT_ESC_EXIT"$$
public extern Bool AreYouSure();
public extern I64 GetChar(I64 *_scan_code=NULL,Bool echo=TRUE,
	Bool raw_cursor=FALSE);
public extern I64 GetKey(I64 *_scan_code=NULL,Bool echo=FALSE,
	Bool raw_cursor=FALSE);
public extern I64 GetS(U8 *buf,I64 size,Bool allow_ext=TRUE);
public extern U8 *GetStr(U8 *msg=NULL,U8 *dft=NULL,I64 flags=0);
extern U0	KbdInit();
public extern I64 KbdMsEvtTime();
extern U0	KbdMsHndlr(Bool poll_kbd,Bool poll_ms);
extern U0	KbdMsInit();
extern I64	KbdMsgsQue();
public extern U0 KbdTypeMatic(U8 delay);
extern Bool	MsHardDrvrInstall();
public extern I64 PressAKey();
public extern I64 ScanChar();
public extern Bool ScanKey(I64 *_ch=NULL,I64 *_scan_code=NULL,Bool echo=FALSE);
public extern Bool YorN();
public extern CKbdStateGlbls	kbd;

#help_index "Math"
public extern I64 CeilI64(I64 num,I64 to);
public extern U64 CeilU64(U64 num,U64 to);
public extern F64 Clamp(F64 d,F64 lo,F64 hi);
public extern I64 FloorI64(I64 num,I64 to);
public extern U64 FloorU64(U64 num,U64 to);
public extern F64 Max(F64 n1,F64 n2);
public extern F64 Min(F64 n1,F64 n2);
public extern F64 Pow10I64(I64 i);
public extern F64 Rand(); //With timestamp
public extern I16 RandI16();
public extern I32 RandI32();
public extern I64 RandI64();
public extern U16 RandU16();
public extern U32 RandU32();
public extern U64 RandU64();
public extern I64 RoundI64(I64 num,I64 to);
public extern I64 Seed(I64 seed=0,CTask *task=NULL);

#help_index "Memory/Adam Heap"
public extern U8 *ACAlloc(I64 size);
public extern U8 *AMAlloc(I64 size);
public extern U8 *AMAllocIdent(U8 *src);

#help_index "Memory/BlkPool"
public extern U0 BlkPoolAdd(CBlkPool *bp,CMemBlk *m,I64 pags);
public extern U0 BlkPoolInit(CBlkPool *bp,I64 pags);
public extern U8 *MemPagAlloc(I64 pags,CBlkPool *bp=NULL);
public extern U0 MemPagFree(CMemBlk *m,CBlkPool *bp=NULL);

#help_index "Memory/Heap"
public extern U8 *CAlloc(I64 size,CTask *mem_task=NULL);
public extern U8 *CAllocAligned(I64 size,I64 alignment,
	CTask *mem_task=NULL,I64 misalignment=0);
public _extern _FREE U0 Free(U8 *addr);
public _extern _MALLOC U8 *MAlloc(I64 size,CTask *mem_task=NULL);
public extern U8 *MAllocAligned(I64 size,I64 alignment,
	CTask *mem_task=NULL,I64 misalignment=0);
public extern U8 *MAllocIdent(U8 *src,CTask *mem_task=NULL);
public _extern _MHEAP_CTRL CHeapCtrl *MHeapCtrl(U8 *src);
public _extern _MSIZE I64 MSize(U8 *src);   //size of heap object
public _extern _MSIZE2 I64 MSize2(U8 *src); //Internal size

#help_index "Memory/HeapCtrl"
public extern U0 HeapCtrlDel(CHeapCtrl *hc);
public extern CHeapCtrl *HeapCtrlInit(CHeapCtrl *hc=NULL,
	CTask *task=NULL,CBlkPool *bp);

#help_index "Memory/Page Tables"
public extern I64 *MemPageTable(U8 *a);

#help_index "Messages"
#help_file "::/Doc/Msgs"
public extern I64 FlushMsgs(CTask *task=NULL);
public extern I64 GetMsg(I64 *_arg1=NULL,I64 *_arg2=NULL,
	I64 mask=~1,CTask *task=NULL);
extern U0 InputFilterTask();
public extern I64 ScanMsg(I64 *_arg1=NULL,I64 *_arg2=NULL,
	I64 mask=~1,CTask *task=NULL);

#help_index "Misc"
public extern I64 EndianI64(I64 d);
public extern U16 EndianU16(U16 d);
public extern U32 EndianU32(U32 d);
public extern U0 QSort(U8 *base,I64 num, I64 width,
	I64 (*fp_compare)(U8 *e1,U8 *e2));
public extern U0 QSortI64(I64 *base,I64 num,
	I64 (*fp_compare)(I64 e1,I64 e2));
public extern F64 sys_os_version;

#help_index "Misc/Progress Bars"
public extern U0 ProgressBarsRst(U8 *path=NULL);

#help_index "Mouse"
#help_file "::/Doc/Mouse"
public extern U0 GridInit();
public extern U0 MsSet(I64 x=I64_MAX,I64 y=I64_MAX,I64 z=I64_MAX,
	I64 l=I64_MAX,I64 r=I64_MAX);
public extern CMsStateGlbls ms;
public extern CGridGlbls ms_grid;
public extern CMsHardStateGlbls ms_hard;
extern CMsHardStateGlbls ms_hard_last;
extern CMsStateGlbls ms_last;

#help_index "Mouse/Ptr"
extern U0 MsInit();
extern U0 MsUpdate(I64 x,I64 y,I64 z,Bool l,Bool r);

#help_index "MultiCore"
#help_file "::/Doc/MultiCore"
public extern CTask *SpawnQue(U0 (*fp_addr)(U8 *data),U8 *data=NULL,
	U8 *task_name=NULL,I64 target_cpu,
	CTask *parent=NULL, //NULL means adam
	I64 stk_size=0,I64 flags=1<<JOBf_ADD_TO_QUE);

#help_index "MultiCore;Processor"
_extern SYS_MP_CNT_LOCK I64 mp_cnt_lock;
_extern SYS_SEMAS CSema sys_semas[SEMA_SEMAS_NUM];

#help_index "MultiCore;Job/Exe;Task/Job/Exe"
public extern CJob *JobQue(I64 (*fp_addr)(U8 *data),U8 *data=NULL,
	I64 target_cpu=1,I64 flags=1<<JOBf_FREE_ON_COMPLETE,
	I64 job_code=JOBT_CALL,U8 *aux_str=NULL,I64 aux1=0,I64 aux2=0);

#help_index "PCI;Info;File/System;Devices"
public extern I64 ATARep(Bool pmt=TRUE,
	Bool just_ide=FALSE,CATARep **_head=NULL);

#help_index "Processor"
public extern U8 *IntEntryGet(I64 irq);
public extern U8 *IntEntrySet(I64 irq,
	U0 (*fp_new_hndlr)(),I64 type=IDTET_IRQ,I64 dpl=0);

#help_index "Snd"
#help_file "::/Doc/Snd"
public extern U0 Beep(I8 ona=62,Bool busy=FALSE);
public extern I8 Freq2Ona(F64 freq);
public extern Bool IsMute();
public extern Bool Mute(Bool val);
public extern F64 Ona2Freq(I64 ona);
public extern U0 Snd(I8 ona=0);
public extern U0 SndRst();

#help_index "StdIn"
#help_file "::/Doc/Streams"

#help_index "StdOut"
#help_file "::/Doc/Streams"

#help_index "Task"
public extern I64 BirthWait(CTask **_task);
public extern U0 DeathWait(CTask **_task,Bool send_exit=FALSE);
public extern U0 Exit();
public extern Bool IsSuspended(CTask *task=NULL);
public extern Bool Kill(CTask *task,Bool wait=TRUE,Bool just_break=FALSE);
public extern Bool Suspend(CTask *task=NULL,Bool state=TRUE);
_extern _TASK_CONTEXT_RESTORE U0 TaskContextRestore();
_extern _TASK_END_NOW U0 TaskEndNow();
extern U0 TaskKillDying();
public extern U0 TaskQueIns(CTask *task,CTask *pred=NULL);
public extern U0 TaskQueRem(CTask *task);
public extern Bool TaskValidate(CTask *task);
public extern U0 TaskWait(CTask *task=NULL,Bool cmd_line_pmt=FALSE);
public extern CTask *User(U8 *fmt=NULL,...);
public extern U0 UserCmdLine(I64 dummy=0);
public extern CTask *adam_task;
public extern I64 sys_num_spawned_tasks;
extern CTask *sys_winmgr_task,*sys_task_being_scrn_updated;

#help_index "Task/Delay;Time/CPU Cycles"
public extern U0 Busy(I64 æS); //Loosely timed
public extern U0 PortNop(); //On the order of 1uS
extern I64 TimeCal();

#help_index "Task/Delay;Time/Jiffies"
public extern U0 Sleep(I64 mS);
public extern U0 SleepUntil(I64 wake_jiffy);

#help_index "Task/Misc"
extern U0 (*fp_update_ctrls)(CTask *task);
public extern U0 TSSBusy(I64 tr,Bool val=OFF);
public extern U0 TaskDerivedValsUpdate(CTask *task=NULL,Bool update_z_buf=TRUE);
public extern U0 WinDerivedValsUpdate(CTask *task);

#help_index "Task;Job/Exe;Task/Job/Exe;MultiCore"
public extern CTask *Spawn(U0 (*fp_addr)(U8 *data),U8 *data=NULL,
	U8 *task_name=NULL,I64 target_cpu=-1,	//-1 means current CPU
	CTask *parent=NULL, //NULL means adam
	I64 stk_size=0,I64 flags=1<<JOBf_ADD_TO_QUE);

#help_index "Time/CPU Cycles;Time/HPET;Time/Jiffies"
public extern CCntsGlbls cnts;

#help_index "Time/Date/CDate;Date/CDate"
#help_file "::/Doc/TimeDate"
public extern U0 Date2Struct(CDateStruct *_ds,CDate cdt);
extern U8 *MPrintDate(CDate cdt);
extern U8 *MPrintTime(CDate cdt);
public extern CDate Now();
public extern CDate Struct2Date(CDateStruct *_ds);
public extern CDate local_time_offset;

#help_index "Time/Date;Date"
#help_file "::/Doc/Date"
public extern I64 DayOfWeek(I64 i);
public extern I64 FirstDayOfMon(I64 i);
public extern I64 FirstDayOfYear(I64 i);
public extern I64 LastDayOfMon(I64 i);
public extern I64 LastDayOfYear(I64 i);
public extern I64 YearStartDate(I64 year);
public extern U16 mon_start_days1[12];
public extern U16 mon_start_days2[12];

#help_index "Time/HPET"
#help_file "::/Doc/TimeHPET"
public extern I64 HPET();

#help_index "Time/Jiffies"
#help_file "::/Doc/TimeJiffy"
public extern I64 SysTimerRead();//18.33333*65536Hz (SYS_TIMER_FREQ)

#help_index "Time/Seconds"
public extern Bool Blink(F64 Hz=2.5);
public extern F64 tS(); //From SysTimerFreq.

#help_index "Windows"
public extern Bool WinInside(I64 x,I64 y,CTask *task=NULL,I64 border=0);

#help_index ""

#help_index "File/Cmd Line (Typically);Cmd Line (Typically)"
public extern U8 *DBlk(I64 blk,Bool write=FALSE);
public extern U8 *DClus(I64 c,Bool write=FALSE,I64 num=0);
public extern U8 *Dump(U8 *filename,Bool write=FALSE);
public extern Bool Copy(U8 *src_files_find_mask,U8 *dst_files_find_mask=".");
public extern Bool Move(U8 *f1,U8 *f2);
public extern I64 CopyTree(U8 *src_files_find_mask,U8 *dst_files_find_mask,
	Bool no_mask=TRUE);
public extern I64 DelTree(U8 *files_find_mask,U8 *fu_flags=NULL);
public extern U0 Touch(U8 *files_find_mask="*",U8 *attr="+?",
	U8 *fu_flags=NULL,CDate cdt=I64_MIN);
#help_index "File/Internal"
public extern U8 *DirTreeSerialize(CDirEntry *tmpde,I64 *_size=NULL);
public extern CDirEntry *DirTreeUnserialize(U8 *src);
#help_index "File/Program Routines"
public extern I64 Size(U8 *files_find_mask="/*",U8 *fu_flags=NULL,I64 round_to=0);
public extern I64 FileCnt(CDirEntry *tmpde);
#help_index "File/Cmd Line (Typically);Cmd Line (Typically)"
public extern I64 FF(U8 *files_find_mask,U8 *fu_flags=NULL);
public extern I64 Zip(U8 *files_find_mask="*",U8 *fu_flags=NULL);
public extern I64 Unzip(U8 *files_find_mask="*.Z",U8 *fu_flags=NULL);
#help_index "Info;File/Cmd Line (Typically);Cmd Line (Typically)";
public extern I64 DskChk(U8 drv_let=0,Bool fix=FALSE,Bool confirm=TRUE);
public extern U0 DskView(U8 drv_let=0);
public extern I64 DrvUnused(U8 drv_let=0);
#help_index "DolDoc/Output;StdOut/DolDoc"
public extern U8 *FileMgr(I64 mode=FM_NORMAL,CTask *mem_task=NULL);
#help_index "Install;File/Cmd Line (Typically);Cmd Line (Typically);"
public extern U8 Mount(Bool caller_is_prtdsk=FALSE);
public extern U0 Unmount(U8 drv_let=0);
public extern U8 MountFile(U8 *filename,U8 drv_let='M');
#help_index "AutoComplete/Dictionary"
public extern U8 *ACDDefGet(U8 *st,I64 def_num=1)
public extern U8 *ACDDefsGet(U8 *st);
public extern U8 *ACDWordPtAt(U8 *st);
#help_index "AutoComplete"
#help_index "Install;File/Cmd Line (Typically);Cmd Line (Typically)"
public extern I64 DskPrt(U8 drv_let=0,...);
//TOOD CtrslA.HC
public extern Bool CtrlInside(CCtrl *c,I64 x,I64 y);
public extern CCtrl *CtrlFindUnique(CTask *haystack_task,I64 needle_type);
public extern U0 ViewAnglesDel(CTask *task=NULL);
public extern CCtrl *ViewAnglesNew(CTask *task=NULL);
public extern CCtrl *CtrlBttnNew(I64 x,I64 y,I64 width=-1,I64 height=-1,
	I64 num_states=1,U8 *state_texts,
	I32 *state_colors,CCtrlBttnState *_s=NULL);
public extern U0 CtrlBttnDel(CCtrl *c);
#help_index "DolDoc/Editor"
public extern I64 EdCurU8(CDoc *doc);
public extern U0 EdCursorLeft(CDoc *doc,I64 sc=I64_MIN);
public extern U0 EdCursorRight(CDoc *doc,I64 sc=I64_MIN);
public extern U0 EdLineUp(CDoc *doc,I64 sc=I64_MIN);
public extern U0 EdLineDown(CDoc *doc,I64 sc=I64_MIN);
#help_index "DolDoc/Clip"
public extern U0 ClipDel();
public extern U0 ClipCopy(CDoc *doc);
public extern U0 ClipCut(CDoc *doc);
public extern U0 ClipPaste(CDoc *doc);
public extern U0 DocCut(CDoc *doc,CDocEntry *start,CDocEntry *end);
public extern CDoc *DocCopy(CDoc *doc,CDocEntry *start,CDocEntry *end);
#help_index "DolDoc/Task;StdOut/Task"
public extern CDoc *DocPut(CTask *task=NULL);
public extern CDoc *DocDisplay(CTask *task=NULL);
public extern CDoc *DocBorder(CTask *task=NULL);
public extern CDoc *DocDblBufStart(CTask *task=NULL);
public extern Bool DocDblBufEnd(CTask *task=NULL);
public extern Bool DocDblBufSwap(CTask *task=NULL);
#help_index "DolDoc/Output;StdOut/DolDoc"
public extern Bool View()
#help_index "DolDoc"
public extern Bool DocEd(CDoc *doc,I64 dof_flags=0);
#help_index "DolDoc/Cmd Line (Typically);Cmd Line (Typically)"
public extern Bool Ed(U8 *link_st,I64 edf_dof_flags=0);
public extern Bool Plain(U8 *filename,I64 edf_dof_flags=0);
#help_index "DolDoc;Job/Exe;Task/Job/Exe"
public extern I64 PopUpEd(U8 *filename,CTask *parent=NULL,CTask **_pu_task=NULL);
#help_index "DolDoc/File";
public extern U0 DocLoad(CDoc *doc,U8 *src2,I64 size);
public extern CDoc *DocRead(U8 *name=NULL,I64 flags=0);
public extern U8 *DocSave(CDoc *doc,I64 *_size=NULL);
public extern Bool DocWrite(CDoc *doc,Bool prompt=FALSE);
#help_index "DolDoc"
public extern U0 DocInsDoc(CDoc *doc=NULL,CDoc *doc2);
#help_index "Graphics/GR Files;DolDoc/Output;StdOut/DolDoc"
public extern Bool DocType(CDoc *doc=NULL,U8 *filename,I64 trailing_new_lines=1);
#help_index "Graphics/GR Files;"\
	"File/Cmd Line (Typically);DolDoc/Cmd Line (Typically);"\
	"StdOut;Cmd Line (Typically)"
public extern Bool Type(U8 *filename,I64 trailing_new_lines=1);
#help_index "DolDoc/File"
public extern U8 *DocLineRead(U8 *filename,I64 line,CTask *mem_task=NULL);
public extern U8 *DocLineWrite(U8 *filename,I64 line,U8 *st);
#help_index "DolDoc/Editor"
public extern Bool DocGoToLine(CDoc *doc,I64 line_num);
public extern Bool DocFind(CDoc *haystack_doc,I64 start_line_num=I64_MIN,
	U8 *needle,I64 match=1);

public extern Bool DocAnchorFind(CDoc *haystack_doc,U8 *needle_str);
public extern U0 EdFindNext(CDoc *doc);
public extern U0 EdSelAll(CDoc *doc,Bool sel);
public extern Bool EdFindPaired(CDoc *doc,U8 plus,U8 minus,
	Bool fwd,Bool abort_on_dbl_colon=FALSE);
public extern Bool EdGoToFun(CDoc *doc,Bool fwd,Bool abort_on_dbl_colon);
public extern U0 EdSelFun(CDoc *doc,Bool abort_on_dbl_colon=FALSE);
public extern I64 EdReplace(CDoc *doc,U8 *find,U8 *replace,
Bool sel=TRUE,Bool match_case=TRUE,Bool whole_labels=FALSE);
#help_index "DolDoc/Input;StdIn/DolDoc"
public extern Bool DocForm(U8 *_d,U8 *class_name=lastclass,
    I64 dof_flags=0,U8 *header=NULL,U8 *footer=NULL);
public extern I64 DocMenu(CDoc *m,I64 dof_flags=0);
public extern I64 PopUpMenu(CDoc *doc,I64 dof_flags=0);
public extern Bool PopUpForm(U8 *_d,U8 *class_name=lastclass,
	I64 dof_flags=DOF_SIZE_MIN,U8 *header=NULL,U8 *footer=NULL);
#help_index "DolDoc"
public extern I64 DocGetKey(I64 *_sc=NULL);
#help_index "DolDoc/Input;StdIn/DolDoc"
public extern U8 *DocScanLine(CDoc *doc,CDocEntry *doc_e,
	I64 *cur_col=NULL,CDocEntry **_do_e_end=NULL);
#help_index "Keyboard Devices;Char/Input;StdIn"
public extern I64 GetI64(U8 *msg=NULL,I64 dft=0,I64 lo=I64_MIN,I64 hi=I64_MAX);
public extern F64 GetF64(U8 *msg=NULL,F64 dft=0,F64 lo=F64_MIN,F64 hi=F64_MAX);
public extern CDate GetDate(U8 *msg=NULL,CDate dft=I64_MIN,
	CDate lo=I64_MIN,CDate hi=I64_MAX);
#help_index "Graphics/Input"
public extern I64 PopUpColor(U8 *header=NULL,
	Bool allow_transparent=TRUE,Bool allow_dft=TRUE);
public extern I64 PopUpColorLighting(U8 *header=NULL);
#help_index "Graphics/Input;Graphics/Math/3D Transformation"
public extern Bool PopUpTransform(I64 *r);
#help_index "Graphics/Input"
public extern I64 PopUpColorDither(U8 *header=NULL);
#help_index "DolDoc/Link"
public extern U8 *DocEntryLink(CDoc *doc,CDocEntry *doc_e);
public extern I64 EdLinkCvt(U8 *link_st,U8 **_filename=NULL,U8 **_needle_str=NULL,
	I64 *_num=NULL,I64 edf_dof_flags=0);
public extern U8 *DocLinkFile(U8 *link_st,CTask *mem_task=NULL);
#help_index "DolDoc"
public extern Bool DocLock(CDoc *doc);
public extern Bool DocUnlock(CDoc *doc);
public extern U0 DocEntryDel(CDoc *doc,CDocEntry *doc_e);
public extern I64 DocEntrySize(CDoc *,CDocEntry *doc_e);
public extern CDocEntry *DocEntryCopy(CDoc *doc,CDocEntry *doc_e);
public extern U0 DocInsEntry(CDoc *doc,CDocEntry *doc_e);
public extern U0 DocRst(CDoc *doc,Bool is_old);
public extern U0 DocDel(CDoc *doc);
public extern I64 DocSize(CDoc *doc);
public extern CDoc *DocNew(U8 *filename=NULL,CTask *task=NULL);
//DocPopUp
#help_index "DolDoc/Output;StdOut/DolDoc"
public extern CTask *PopUpViewDoc(CDoc *doc,I64 dof_flags=0)
public extern CTask *PopUpViewPrint(U8 *fmt,...);
#help_index "DolDoc/Input;File/FileNames;StdIn/DolDoc"
public extern U8 *PopUpPickFile(U8 *dir=NULL);
public extern U8 *PopUpPickDir(U8 *dir=NULL);

public extern U8 *FileNameForm(U8 *dft=NULL,I64 dof_flags=0,CTask *mem_task=NULL);
public extern U8 *PopUpFileName(U8 *dft=NULL,I64 dof_flags=0);
#help_index "DolDoc"
public extern Bool PopUpCd();
#help_index "DolDoc/Input;Char/Lists;StdIn/DolDoc"
public extern I64 PopUpPickLst(U8 *lst);
#help_index "DolDoc/Input;Char/Lists;Char/Define;StdIn/DolDoc"
public extern U8 *PopUpPickDefineSub(U8 *dname);
#help_index "DolDoc/Input;StdIn/DolDoc"
public extern I64 PopUp1(U8 *b1,I64 n1,U8 *header=NULL,U8 *footer=NULL);
public extern I64 PopUp2(U8 *b1,I64 n1,U8 *b2,I64 n2,U8 *header=NULL,U8 *footer=NULL);
public extern Bool PopUpOk(U8 *header=NULL,U8 *footer=NULL);
public extern Bool PopUpNoYes(U8 *header=NULL,U8 *footer=NULL);
public extern Bool PopUpCancelOk(U8 *header=NULL,U8 *footer=NULL);
public extern U8 *PopUpGetStr(U8 *header=NULL);
public extern I64 PopUpGetI64(U8 *msg,I64 dft,I64 lo=I64_MIN,I64 hi=I64_MAX);
public extern F64 PopUpGetF64(U8 *msg,F64 dft,F64 lo=F64_MIN,F64 hi=F64_MAX);
public extern I64 PopUpRangeI64(I64 lo,I64 hi,I64 step=1,
	U8 *header=NULL,U8 *footer=NULL);
public extern F64 PopUpRangeF64(F64 lo,F64 hi,F64 step,
    U8 *fmt="%9.4f",U8 *header=NULL,U8 *footer=NULL);
public extern F64 PopUpRangeF64Exp(F64 lo,F64 hi,F64 factor,
    U8 *fmt="%9.4f",U8 *header=NULL,U8 *footer=NULL);
public extern F64 PopUpRangeF64Log(F64 lo,F64 hi,I64 steps,
    U8 *fmt="%9.4f",U8 *header=NULL,U8 *footer=NULL);
#help_index "Job/Exe;Task/Job/Exe;Compiler"
public extern I64 AdamFile(U8 *filename,Bool warn_ext=TRUE);
public extern I64 PopUpFile(U8 *filename,Bool warn_ext=TRUE,
	CTask *parent=NULL,CTask **_pu_task=NULL);
public extern I64 PopUpRunFile(U8 *filename,I64 ccf_flags=0,...);
#help_index "DolDoc/Output;StdOut/DolDoc"

public extern U0 DocPutKey(CDoc *doc,I64 ch=0,I64 sc=0);
#help_index "DolDoc/Output;StdOut/DolDoc"
public extern CDocEntry *DocPrint(CDoc *doc=NULL,U8 *fmt,...);
public extern U0 DocPrintPartial(CDoc *doc=NULL,U8 *fmt,...);
public extern U0 DocPrintAtomic(CDoc *doc=NULL,U8 *fmt,...);
public extern CDocEntry *DocPutLine(CDoc *doc=NULL,CDocEntry *doc_e);
#help_index "Debugging/Dump;DolDoc/Cmd Line (Typically);"\
	"Cmd Line (Typically);DolDoc/Output;StdOut/DolDoc"
public extern U0 DocDm(U8 *buf,I64 cnt=0x80);
#help_index "DolDoc"
public extern Bool DocRecalc(CDoc *doc,I64 recalc_flags=RECALCt_NORMAL);
#help_index "DolDoc"
public extern U0 DocTop(CDoc *doc=NULL);

public extern U0 DocCenter(CDoc *doc=NULL,I64 recalc_flags=RECALCt_NORMAL);
public extern U0 DocBottom(CDoc *doc=NULL);
public extern U0 DocClear(CDoc *doc=NULL,Bool clear_holds=FALSE)
public extern Bool DocCursor(Bool show=OFF,CDoc *doc=NULL);
public extern Bool DocHighlightCursor(Bool show=OFF,CDoc *doc=NULL);
public extern Bool DocScroll(Bool val=OFF,CDoc *doc=NULL);
public extern U0 DocCollapse(Bool collapse=TRUE,CDoc *doc=NULL);
#help_index "DolDoc/Cmd Line (Typically);Cmd Line (Typically)"
public extern I64 DocMax(I64 i=I64_MAX);
#help_index "DolDoc/Task;StdOut/Task"
public extern U0 DocUpdateTaskDocs(CTask *task);
#help_index "DolDoc"
public extern I64 DocEntryRun(CDoc *doc,CDocEntry *doc_e,
	Bool exited,I64 *_has_action=NULL);

#help_index "DolDoc/Task;StdOut/Task"
public extern CDoc *DocBorderNew(CDoc *pdoc);
public extern U0 DocTermNew();
#help_index "DolDoc"
#help_index "DolDoc/Tree"
public extern Bool DocTreeFind(CDoc *haystack_doc,U8 *needle_path,
  CDocEntry **_tree_entry=NULL,
  CDocEntry **_start_indent=NULL, CDocEntry **_end_indent=NULL);
public extern Bool DocTreeFFind(U8 *name,U8 *path);

public extern Bool DocTreeWrite(CDoc *doc,U8 *path,Bool write=TRUE,U8 *fmt,...);
public extern Bool DocTreeMake(CDoc *doc,U8 *path);
public extern Bool DocTreeWrite(CDoc *doc,U8 *path,Bool write=TRUE,U8 *fmt,...);
public extern Bool DocTreeAppend(CDoc *doc,U8 *path,Bool write=TRUE,U8 *fmt,...);
public extern Bool DocTreeFWrite(U8 *name,U8 *path,U8 *fmt,...);
public extern Bool DocTreeFAppend(U8 *name,U8 *path,U8 *fmt,...);
#help_index "DolDoc/Compiler;Compiler"
public extern I64 ExeDoc(CDoc *doc,I64 ccf_flags=0);
#help_index "DolDoc/Tree;DolDoc/Compiler;Compiler"
public extern I64 DocTreeExe(CDoc *doc,U8 *path);
public extern I64 DocTreeFExe(U8 *name,U8 *path);
#help_index "DolDoc"
#help_file "::/Doc/DolDoc"
public extern class CDolDocGlbls;
#help_index "God"
public extern U8 *BibleLine2Verse(I64 line,I64 separate_ch=CH_SPACE);
public extern U0 BookLines(CDoc *doc_out=NULL,I64 start,I64 lines,
	U8 *book_filename=BIBLE_FILENAME);
public extern U0 BibleVerse(CDoc *doc_out=NULL,U8 *verse,I64 lines);
public extern CDoc *BibleDoc();
public extern U0 BibleView();
#help_index "God;Graphics/Sprite;Sprites"
public extern U8 *GodDoodleSprite(U8 *hex=NULL);
#help_index "God"
public extern U0 GodDoodle(U8 *hex=NULL);
#help_index "God"
public extern class CGodGlbls;
public extern U8 *GodSongStr();
public extern U0 GodSong();
public extern U0 GodBitsIns(I64 num_bits,I64 n);
public extern U0 GodHexIns(U8 *st);
public extern I64 GodBits(I64 num_bits,U8 *msg=NULL);
public extern I64 GodInit(U8 *files_find_mask="/Adam/God/Vocab.DD*",U8 *fu_flags=NULL);
public extern U8 *GodWordStr(I64 bits=17);
public extern U0 GodWord(I64 bits=17);
public extern U0 GodBiblePassage(I64 num_lines=20);
#help_index "Graphics"
public extern Bool GrPlot0(CDC *dc=NULL,I64 x,I64 y);
public extern I64 GrPeek0(CDC *dc=NULL,I64 x,I64 y);
#help_index "Graphics;Graphics/Device Contexts"
public extern I64 GrBlot(CDC *dc=NULL,I64 x,I64 y,CDC *img);
#help_index "Graphics/Device Contexts"

public extern CDC *DCExt(CDC *dc=NULL,I64 x1,I64 y1,I64 x2,I64 y2,
	CTask *task=NULL);
public extern CDC *DCDiff(CDC *base,CDC *update);
#help_index "Graphics/Char;Char/Graphics"

public extern I64 GrPutChar(CDC *dc=NULL,I64 x,I64 y,U8 ch)
#help_index "Graphics"
public extern I64 GrRect(CDC *dc=NULL,I64 x,I64 y,I64 w,I64 h);
public extern I64 GrHLine(CDC *dc=NULL,I64 x1,I64 x2,I64 y,I64 z1=0,I64 z2=0);
#help_index "Graphics"
public extern I64 GrFillPoly3(CDC *dc=NULL,I64 n,CD3I32 *poly);
public extern I64 GrRectB(CDC *dc=NULL,I64 x1,I64 y1,I64 x2,I64 y2);

public extern I64 GrRect3(CDC *dc=NULL,I64 x,I64 y,I64 z,I64 w,I64 h);
public extern U0 GrBorder(CDC *dc=NULL,I64 x1,I64 y1,I64 x2,I64 y2,
	I64 step=1,I64 start=0);
public extern Bool GrArrow3(CDC *dc=NULL,I64 x1,I64 y1,I64 z1,
	I64 x2,I64 y2,I64 z2,F64 w=2.75,I64 step=1,I64 start=0);
#help_index "Graphics/Char;Char/Graphics"
public extern Bool GrTextBox3(CDC *dc=NULL,I64 x1,I64 y1,I64 z1,U8 *s,I64 border=2);
public extern Bool GrTextDiamond3(CDC *dc=NULL,
	I64 x1,I64 y1,I64 z1,U8 *_s,I64 border=2);
#help_index "Graphics/Mesh"
public extern I64 Gr3Mesh(CDC *dc=NULL,I64 vertex_cnt,CD3I32 *p,
	I64 tri_cnt,CMeshTri *tri);
#help_index "Graphics/Misc;Mouse/Ptr"
public extern U0 DrawStdMs(CDC *dc,I64 x,I64 y);
public extern U0 DrawWaitMs(CDC *dc,I64 x,I64 y);
#help_index "Graphics/GR Files;Graphics/Scrn"
public extern Bool GRScrnCaptureRead(U8 *filename,CDC *dc=NULL,I64 x=0,I64 y=0);
public extern I64 GRScrnCaptureWrite(U8 *filename,Bool include_zoom=TRUE);
#help_index "Graphics/Math/3D Transformation"
#help_file "::/Doc/Transform"
public extern U0 Mat4x4MulXYZ(I64 *r,I64 *_x,I64 *_y,I64 *_z);
public extern U0 DCTransform(CDC *dc,I64 *_x,I64 *_y,I64 *_z);
public extern I64 *Mat4x4IdentEqu(I64 *r);
public extern I64 *Mat4x4IdentNew(CTask *mem_task=NULL);
public extern I64 Mat4x4NormSqr65536(I64 *r);
public extern U0 DCMat4x4Set(CDC *dc=NULL,I64 *r);
#help_index "Graphics/Mesh"
public extern U0 DCLighting(CDC *dc,
	CD3I32 *p1,CD3I32 *p2,CD3I32 *p3,CColorROPU32 color);

#help_index "Graphics/Device Contexts"
public extern U0 DCFill(CDC *dc=NULL,CColorROPU32 val=TRANSPARENT);
public extern U0 DCClear(CDC *dc=NULL);
public extern U0 DCRst(CDC *dc);
public extern U0 DCExtentsInit(CDC *dc=NULL);
public extern CDC *DCAlias(CDC *dc=NULL,CTask *task=NULL);
public extern CDC *DCNew(I64 width,I64 height,CTask *task=NULL,Bool null_bitmap=FALSE);
public extern U0 DCDel(CDC *dc);
public extern I64 DCSize(CDC *dc);
public extern I32 *DCDepthBufRst(CDC *dc);
public extern I32 *DCDepthBufAlloc(CDC *dc);
public extern CDC *DCCopy(CDC *dc,CTask *task=NULL);
public extern U0 DCMono(CDC *dc,
  I64 quest=TRANSPARENT,I64 true_color=0,I64 false_color=COLOR_MONO);
public extern I64 DCColorChg(CDC *dc,I64 src_color,I64 dst_color=TRANSPARENT);
public extern U8 *DCSave(CDC *dc,I64 *_size=NULL,I64 dcsf_flags=DCSF_COMPRESSED);
#help_index "Graphics/GR Files"
#help_file "::/Doc/GRFiles"
#help_index "Graphics/Device Contexts;Graphics/GR Files"
public extern I64 GRWrite(U8 *filename,CDC *dc,I64 dcsf_flags=DCSF_COMPRESSED);
public extern CDC *GRRead(U8 *filename,CTask *task=NULL);
#help_index "Graphics/Sprite;Graphics/GR Files;DolDoc/Output;StdOut/DolDoc"
public extern U0 DocGR(CDoc *doc=NULL,U8 *filename);
#help_index "Graphics/Device Contexts;Graphics/Scrn"
public extern CDC *DCScrnCapture(Bool include_zoom=TRUE,CTask *task=NULL);
#help_index "Graphics"

public extern class CGrGlbls;
public extern U0 WinZBufUpdate();
#help_index "Graphics/Math"
public extern Bool Line(U8 *aux_data,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2,
	Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),I64 step=1,I64 start=0);
#help_index "Graphics/Math/3D Transformation"
public extern I64 *Mat4x4MulMat4x4Equ(I64 *dst,I64 *m1,I64 *m2);
public extern I64 *Mat4x4MulMat4x4New(I64 *m1,I64 *m2,CTask *mem_task=NULL);
public extern I64 *Mat4x4Equ(I64 *dst,I64 *src);
public extern I64 *Mat4x4New(I64 *src,CTask *mem_task=NULL);
public extern I64 *Mat4x4RotX(I64 *m,F64 è);
public extern I64 *Mat4x4RotY(I64 *m,F64 ê);
public extern I64 *Mat4x4RotZ(I64 *m,F64 é);
public extern I64 *Mat4x4Scale(I64 *m,F64 s);
public extern U0 DCThickScale(CDC *dc=NULL);
public extern I64 *Mat4x4TranslationEqu(I64 *r,I64 x,I64 y,I64 z);
public extern I64 *Mat4x4TranslationAdd(I64 *r,I64 x,I64 y,I64 z);
public extern Bool DCSymmetrySet(CDC *dc=NULL,I64 x1,I64 y1,I64 x2,I64 y2);
public extern Bool DCSymmetry3Set(CDC *dc=NULL,I64 x1,I64 y1,I64 z1,
	I64 x2,I64 y2,I64 z2,I64 x3,I64 y3,I64 z3);
public extern U0 DCReflect(CDC *dc,I64 *_x,I64 *_y,I64 *_z);
#help_index "Graphics/Math"
public extern Bool Circle(U8 *aux_data,I64 cx,I64 cy,I64 cz,I64 radius,
	Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),
	I64 step=1,F64 start_radians=0,F64 len_radians=2*ã);
public extern Bool Ellipse(U8 *aux_data,I64 cx,I64 cy,I64 cz,
	I64 x_radius,I64 y_radius,Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),
	F64 rot_angle=0,I64 step=1,F64 start_radians=0,F64 len_radians=2*ã);
public extern Bool RegPoly(U8 *aux_data,I64 cx,I64 cy,I64 cz,
	I64 x_radius,I64 y_radius,I64 sides,
	Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),
	F64 rot_angle=0,I64 step=1,F64 start_radians=0,F64 len_radians=2*ã);
#help_index "Graphics/Data Types/D3I32;Math/Data Types/D3I32;Data Types/D3I32"
public extern F64 D3I32Dist(CD3I32 *p1,CD3I32 *p2);
public extern I64 D3I32DistSqr(CD3I32 *p1,CD3I32 *p2);
public extern F64 D3I32Norm(CD3I32 *p);
public extern I64 D3I32NormSqr(CD3I32 *p);
#help_index "Graphics/Math"
public extern Bool Bezier2(U8 *aux_data,CD3I32 *ctrl,
	Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),Bool first=TRUE);
public extern Bool Bezier3(U8 *aux_data,CD3I32 *ctrl,
	Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),Bool first=TRUE);
public extern Bool BSpline2(U8 *aux_data,CD3I32 *ctrl,I64 cnt,
	Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),Bool closed=FALSE);
public extern Bool BSpline3(U8 *aux_data,CD3I32 *ctrl,I64 cnt,
	Bool (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z),Bool closed=FALSE);
public extern Bool ClipLine(I64 *_x1,I64 *_y1,I64 *_x2,I64 *_y2,
	I64 left,I64 top,I64 right,I64 bottom);
#help_index "Graphics/Color"
public extern U0 GrPaletteColorSet(I64 color_num,CBGR48 bgr48);
public extern CBGR48 GrPaletteColorGet(I64 color_num);
public extern U0 GrPaletteGet(CBGR48 *bgr48);
public extern U0 GrPaletteSet(CBGR48 *bgr48);
public extern U0 PaletteSetStd();
#help_index "Graphics"

public extern Bool GrClamp(CDC *dc=NULL,I64 *left,I64 *top,I64 *right,I64 *bottom,
	I64 width=0,I64 height=0);
public extern Bool GrPlot(CDC *dc=NULL,I64 x,I64 y);
public extern I64 GrPeek(CDC *dc=NULL,I64 x,I64 y);
public extern I64 GrFloodFill(CDC *dc=NULL,I64 x,I64 y,
	Bool not_color=FALSE,I64 z=0,I32 *db=NULL);
public extern I64 GrFillCircle(CDC *dc=NULL,I64 cx,I64 cy,I64 z=0,I64 diameter);
public extern Bool GrPlot3B(CDC *dc=NULL,I64 x,I64 y,I64 z);
public extern Bool GrPlot3(CDC *dc=NULL,I64 x,I64 y,I64 z);
public extern Bool GrLine(CDC *dc=NULL,I64 x1,I64 y1,I64 x2,I64 y2,
	I64 step=1,I64 start=0);
public extern Bool GrCircle(CDC *dc=NULL,I64 cx,I64 cy,I64 radius,
  I64 step=1,F64 start_radians=0,F64 len_radians=2*ã);
public extern Bool GrEllipse(CDC *dc=NULL,
		I64 cx,I64 cy,
		I64 x_radius,I64 y_radius,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã);
public extern Bool GrRegPoly(CDC *dc=NULL,
		I64 cx,I64 cy,
		I64 x_radius,I64 y_radius,I64 sides,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã);
public extern Bool Gr2Bezier(CDC *dc=NULL,CD3I32 *ctrl);
public extern Bool Gr3Bezier(CDC *dc=NULL,CD3I32 *ctrl);
public extern Bool Gr2BSpline(CDC *dc=NULL,CD3I32 *ctrl,I64 cnt,Bool closed=FALSE);
public extern I64 GrLineFat3(CDC *dc=NULL,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2,
	I64 width,I64 start=0);
public extern Bool GrLine3(CDC *dc=NULL,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2,
	I64 step=1,I64 start=0);
#help_index "Graphics/Char;Char/Graphics"

public extern Bool GrPutChar3(CDC *dc=NULL,I64 x,I64 y,I64 z,U8 ch);
public extern I64 GrPrint3(CDC *dc=NULL,I64 x,I64 y,I64 z,U8 *fmt,...);
public extern I64 GrVPrint3(CDC *dc=NULL,I64 x,I64 y,I64 z,U8 *fmt,...);
#help_index "Graphics"

public extern Bool GrEllipse3(CDC *dc=NULL,
		I64 cx,I64 cy,I64 cz,
		I64 x_radius,I64 y_radius,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã);
public extern Bool GrCircle3(CDC *dc=NULL,I64 cx,I64 cy,I64 cz,I64 radius,
  I64 step=1,F64 start_radians=0,F64 len_radians=2*ã);
public extern Bool GrRegPoly3(CDC *dc=NULL,
		I64 cx,I64 cy,I64 cz,
		I64 x_radius,I64 y_radius,I64 sides,
		F64 rot_angle=0,
		I64 step=1,
		F64 start_radians=0,
		F64 len_radians=2*ã);
public extern I64 GrFloodFill3(CDC *dc=NULL,I64 x1,I64 y1,I64 z1,Bool not_color=FALSE);
#help_index "Graphics;Graphics/Device Contexts"
public extern I64 GrBlot3(CDC *dc=NULL,I64 x1,I64 y1,I64 z1,CDC *img);
#help_index "Graphics"

public extern Bool Gr2Bezier3(CDC *dc=NULL,CD3I32 *ctrl);
public extern Bool Gr3Bezier3(CDC *dc=NULL,CD3I32 *ctrl);
public extern Bool Gr3BSpline3(CDC *dc=NULL,CD3I32 *ctrl,I64 cnt,Bool closed=FALSE);
#help_index "Graphics/Scrn"
public extern U0 GrScaleZoom(F64 scale);
#help_index "Graphics/Sprite;Sprites"
public extern U0 Sprite3(CDC *dc=NULL,I64 x,I64 y,I64 z,U8 *elems,
	Bool just_one_elem=FALSE);
public extern U0 Sprite3B(CDC *dc=NULL,I64 x,I64 y,I64 z,U8 *elems);
public extern U0 Sprite3Mat4x4B(CDC *dc=NULL,I64 x,I64 y,I64 z,U8 *elems,I64 *m);
public extern U0 Sprite3XB(CDC *dc=NULL,I64 x,I64 y,I64 z,U8 *elems,F64 è=0);
public extern U0 Sprite3YB(CDC *dc=NULL,I64 x,I64 y,I64 z,U8 *elems,F64 ê=0);
public extern U0 Sprite3ZB(CDC *dc=NULL,I64 x,I64 y,I64 z,U8 *elems,F64 é=0);
public extern U0 SpriteExtents(U8 *elems,I64 *min_x=NULL,I64 *max_x=NULL,
				   I64 *min_y=NULL,I64 *max_y=NULL);
public extern CDC *Sprite2DC(U8 *elems);
public extern U8 *SpriteInterpolate(F64 t,U8 *elems0,U8 *elems1);

#help_index "Graphics/Sprite;DolDoc/Output;StdOut/DolDoc"
public extern CDocEntry *DocSprite(CDoc *doc=NULL,U8 *elems,U8 *fmt=NULL);
public extern CDocEntry *Sprite(U8 *elems,U8 *fmt=NULL);
#help_index "TextBase Layer;Char/TextBase Layer"
#help_file "::/Doc/TextBase"
public _extern _TEXT_CHAR Bool TextChar(CTask *task,Bool allow_border=FALSE,
I64 x,I64 y,I64 d); //Plot char. 30fps in Fs->draw_it() callback.
public _extern _TEXT_LEN_STR Bool TextLenStr(CTask *task,I64 x,I64 y,I64 len,
I64 attr,U8 *s); //Plot str with len.  30fps in Fs->draw_it() callback.
public _extern _TEXT_LEN_ATTR_STR Bool TextLenAttrStr(CTask *task,I64 x,I64 y,
I64 len,U32 *_attr); //Plot attr str with len.	30fps in Fs->draw_it() callback.
public _extern _TEXT_LEN_ATTR Bool TextLenAttr(CTask *task,I64 x,I64 y,I64 len,
I64 attr); //Plot attrs with len.  30fps in Fs->draw_it() callback.
public extern U0 TextPrint(CTask *task,I64 x,I64 y,I64 attr,U8 *fmt,...);
public extern U0 TextBorder(CTask *task=NULL,I64 l,I64 r,I64 t,I64 b,I64 attr,Bool solid);
public extern U0 TextRect(I64 l,I64 r,I64 t,I64 b,I64 d);

#help_index "Graphics/Sprite;Sprites"
public extern U0 Sprite2Code(CDoc *doc=NULL,U8 *elems);
public extern U8 *Code2Sprite(CDoc *doc,I64 *_size=NULL);
#help_index "Graphics/Sprite;Sprites;Graphics/Math/3D Transformation"
public extern U8 *SpriteTransform(U8 *elems,I64 *r);
#help_index "Graphics/Sprite;Sprites"
#help_file "::/Doc/Sprite"
public extern I64 SpriteSize(U8 *elems);
public extern U8 *DC2Sprite(CDC *tmpb);
public extern U8 *SpriteElem2Summary(CSprite *tmpg);
#help_index "Cmd Line (Typically)"
public extern Bool Diff(U8 *dst_file,U8 *src_file,I64 *_df_flags=NULL);
#help_index "Cmd Line (Typically);Info"
public extern U0 ZipRep(U8 *files_find_mask="/*",U8 *fu_flags=NULL,
  Bool just_text_not_graphics=TRUE);
#help_index "DolDoc/Cmd Line (Typically)"
//Adam/Opt/Utils/DocUtils
public extern U0 Collapse(U8 *files_find_mask="*",
	Bool collapse=TRUE,U8 *fu_flags=NULL);
public extern I64 DocOpt(U8 *files_find_mask="*",U8 *fu_flags=NULL);
public extern U0 CursorRem(U8 *files_find_mask="*");
#help_index "Cmd Line (Typically)"
public extern U0 Merge(U8 *dst_files_find_mask="/*",U8 *src_files_find_mask="/*",
  U8 *fu_flags=NULL);
#help_index "Utils;Cmd Line (Typically)"
public extern U0 NewFiles(U8 *files_find_mask="/*",CDate cdt=0,U8 *fu_flags=NULL);
public extern I64 Sort(U8 *_in_name,U8 *_out_name=NULL,
	I64 entry_lines=1,Bool unique=FALSE);
public extern I64 Words(U8 *files_find_mask="*",U32 *,
	U8 *fu_flags=NULL);
public extern I64 LongLines(U8 *files_find_mask="*",I64 cols=80,U8 *fu_flags=NULL);

public extern U0 SU(U8 *files_find_mask,I64 suf_flags,U8 *fu_flags=NULL,
	F64 indent_scale_factor=0);
public extern U0 S2T(U8 *files_find_mask,U8 *fu_flags=NULL);

#help_index "Debugging/Dump"
public extern U0 ClassRep(U8 *_d,U8 *class_name=lastclass,
	I64 max_depth=2,Bool fun=FALSE,I64 offset=0,Bool include_regs=FALSE);
public extern U0 ClassRepD(U8 *_d,U8 *class_name=lastclass,
	I64 max_depth=2,Bool fun=FALSE,I64 offset=0);
public extern U0 FunRep(U8 *st,U8 *rbp=NULL,I64 max_depth=2,CTask *task=NULL,Bool include_regs=FALSE);
#help_index "Debugging/Unassemble"
public extern U0 Uf(U8 *st);
#help_index "Info;Hash;Cmd Line (Typically)"
public extern I64 HashDepthRep(CHashTable *table=NULL);
#help_index "Help System"
#help_file "::/Doc/HelpSystem"

public extern U0 DocHelpIdx(CDoc *doc,U8 *idx);
public extern U0 PopUpHelpIndex(U8 *idx,CTask *parent=NULL);
#help_index "Hash/System"
public extern U0 MapFileLoad(U8 *filename);
#help_index "Math"
public extern U0 R2P(F64 *_mag=NULL,F64 *_arg=NULL,F64 x,F64 y);
public extern U0 P2R(F64 *_x=NULL,F64 *_y=NULL,F64 mag,F64 arg);
public extern F64 Wrap(F64 é,F64 base=-ã);
public extern I64 DistSqrI64(I64 x1,I64 y1,I64 x2,I64 y2);
public extern F64 ASin(F64 s);
public extern F64 ACos(F64 c);
public extern F64 Sinh(F64 x);
public extern F64 Cosh(F64 x);

#help_index "Math/Complex;Data Types/Complex"
public extern Complex *CAdd(Complex *sum,Complex *n1,Complex *n2);
public extern Complex *CSub(Complex *diff,Complex *n1,Complex *n2);
public extern Complex *CMul(Complex *prod,Complex *n1,Complex *n2);
public extern Complex *CDiv(Complex *quot,Complex *n1,Complex *n2);
public extern Complex *CScale(Complex *dst,F64 s);
public extern Complex *CCopy(Complex *dst,Complex *src);
public extern Complex *CEqu(Complex *dst,F64 x,F64 y);
public extern Complex *CPoly(Complex *dst,I64 n,Complex *zeros,Complex *x);

#help_index "Math/ODE"
#help_file "::/Doc/ODE"
public extern CMathODE *ODENew(I64 n,F64 max_tolerance=1e-6,I64 flags=0);
public extern Bool ODEPause(CMathODE *ode,Bool val=ON);
public extern U0 ODEDel(CMathODE *ode);
public extern I64 ODESize(CMathODE *ode);
public extern U0 ODERenum(CMathODE *ode);
public extern CMass *MassFind(CMathODE *ode,F64 x,F64 y,F64 z=0);
public extern CSpring *SpringFind(CMathODE *ode,F64 x,F64 y,F64 z=0);
public extern U0 MassOrSpringFind(
	CMathODE *ode,CMass **res_mass,CSpring **res_spring,
	F64 x,F64 y,F64 z=0);
public extern CMass *MassFindNum(CMathODE *ode,I64 num);
public extern U0 ODERstInactive(CMathODE *ode);
#help_index "Memory/Task"
public extern I64 TaskMemAlloced(CTask *task=NULL,Bool override_validate=FALSE);
public extern I64 TaskMemUsed(CTask *task=NULL,Bool override_validate=FALSE);
#help_index "Memory/Task;Debugging/Heap;Memory/Debugging"
public extern Bool HeapRep(CTask *task);
#help_index "Memory/HeapCtrl;Debugging/Heap;Memory/Debugging"
public extern Bool IsInHeapCtrl(U8 *a,CHeapCtrl *hc,Bool lock=TRUE);
public extern Bool HeapCtrlWalk(CHeapCtrl *hc);
#help_index "Memory/Task;Debugging/Heap;Memory/Debugging"
public extern Bool IsInHeap(U8 *a,CTask *task=NULL,Bool lock=TRUE);
public extern Bool HeapWalk(CTask *task=NULL);
public extern U0 DrawGrabMs(CDC *dc,I64 x,I64 y,Bool closed);
#help_index "Registry"
public extern Bool RegDft(U8 *path,U8 *val,Bool is_adam_entry=FALSE);
public extern I64 RegExe(U8 *path);
public extern Bool RegWrite(U8 *path,U8 *fmt,...);
public extern I64 RegCnt(U8 *path);
public extern Bool RegAppend(U8 *path,U8 *fmt,...);
public extern Bool OneTimePopUp(U8 *_flags,I64 flag_num,U8 *msg);
#help_index "Boot/Once;Registry/Once"
#help_file "::/Doc/Once"

public extern U0 AOnceFlush();
public extern U0 OnceFlush();
public extern U0 AOnce(U8 *fmt,...);
public extern U0 Once(U8 *fmt,...);
public extern U0 AOnceDrv(U8 drv_let=0,U8 *fmt,...);
public extern U0 OnceDrv(U8 drv_let=0,U8 *fmt,...);
public extern U0 OnceExe();
#help_index "Snd"
public extern U0 SndTaskEndCB();
#help_index "Snd/Math;Math"
public extern F64 Saw(F64 t,F64 period);
public extern F64 FullSaw(F64 t,F64 period);
public extern F64 Caw(F64 t,F64 period);
public extern F64 FullCaw(F64 t,F64 period);
public extern F64 Tri(F64 t,F64 period);
public extern F64 FullTri(F64 t,F64 period);
#help_index "Snd/Music"
#help_index "Snd/Music;Time/Seconds"
public extern F64 tM();
public extern F64 Beat();
#help_index "Snd/Music"
public extern I8 Note2Ona(I64 note,I64 octave=4);
public extern I8 Ona2Note(I8 ona);
public extern I8 Ona2Octave(I8 ona);
public extern U0 Play(U8 *st,U8 *words=NULL);
#help_index "Snd"
public extern CTask *Noise(I64 mS,F64 min_ona,F64 max_ona);
public extern CTask *Sweep(I64 mS,F64 ona1,F64 ona2);
#help_index "InFile;Help System/Training"
#help_file "::/Doc/InFile"
//InFile
public extern U0 InGetStr(U8 *st);
public extern U0 InPrint(I64 mS=100,U8 *fmt,...);
public extern U0 InGetKey(I64 scan_code,I64 sc_mask=0xFF|SCF_SHIFT|SCF_CTRL|SCF_ALT);
public extern I64 InGetChar(...);
public extern U0 InUntilKey(I64 scan_code,I64 sc_mask=0xFF|SCF_SHIFT|SCF_CTRL|SCF_ALT);
public extern I64 InUntilChar(...);
public extern Bool InView();
#help_index "InFile;Help System/Training;Mouse"
public extern U0 InSetMs(I64 mS=7,I64 x=I64_MAX,I64 y=I64_MAX,I64 z=I64_MAX,
		I64 l=I64_MAX,I64 r=I64_MAX);
#help_index "Menus"
#help_file "::/Doc/Menus"
public extern CMenuEntry *MenuSubEntryFind(
	CMenuEntry *haystack_first,U8 *needle_entry_name);
public extern CMenuEntry *MenuEntryFind(CMenu *haystack_menu,U8 *needle_full_name);
public extern CMenu *MenuNew(U8 *st,I64 flags=0,CTask *task=NULL);
public extern CMenu *MenuFile(U8 *filename,I64 flags=0,CTask *task=NULL);
public extern U0 MenuDel(CMenu *m);
public extern CMenu *MenuPush(U8 *st);
public extern CMenu *MenuFilePush(U8 *filename);
public extern U0 MenuPop();
#help_index "Info;Task"
public extern U0 TaskRep();
#help_index "Task/Settings"
public extern CTaskSettings *SettingsPush(CTask *task=NULL,I64 flags=0);
public extern U0 SettingsPop(CTask *task=NULL,I64 flags=0);
#help_index "Help System"
public extern U0 KeyMap(CTask *task=NULL);
#help_index "Help System/Training"
public extern U0 TipOfDay(U8 *tip_file="::/Doc/Tips.DD");
#help_index "Windows"
#help_file "::/Doc/Windows"
public extern U0 WinScrollNull(CTask *task,CD3I64 *s);
public extern U0 WinScrollRestore(CTask *task,CD3I64 *s);
public extern CTask *WinRefocus(CTask *task=NULL);
public extern I64 WinToTop(CTask *task=NULL,Bool update_z_buf=TRUE);
public extern CTask *WinFocus(CTask *task=NULL);
public extern Bool WinHorz(I64 left,I64 right,CTask *task=NULL);
public extern Bool WinVert(I64 top,I64 bottom,CTask *task=NULL);
public extern U0 WinTileHorz();
public extern U0 WinTileVert();
public extern U0 WinMax(CTask *task=NULL);
public extern Bool WinBorder(Bool val=OFF,CTask *task=NULL);
#help_index "Windows;Task/Delay"

public extern U0 Refresh(I64 cnt=1,Bool force=FALSE);
#help_index "Compiler"
public extern U0 CInit();
public extern I64 ExeFile(U8 *name,I64 ccf_flags=0);
public extern I64 ExeFile2(U8 *name,I64 ccf_flags=0);
public extern I64 ExePrint(U8 *fmt,...);
public extern I64 ExePrint2(U8 *fmt,...);
public extern I64 ExePutS(U8 *buf,U8 *filename=NULL,I64 ccf_flags=0,
	CLexHashTableContext *htc=NULL);
public extern I64 ExePutS2(U8 *buf,U8 *filename=NULL,I64 ccf_flags=0);
public _extern _LAST_FUN I64 LastFun(I64 argc,I64 *argv);
public extern I64 RunFile(U8 *name,I64 ccf_flags=0,...);
public extern I64 RunFile2(U8 *name,I64 ccf_flags=0,...);
public extern CCmpGlbls cmp;

#help_index "Compiler/Directive"
#help_file "::/Doc/Directives"
public extern Bool Echo(Bool val);
public extern Bool GetOption(I64 num);
public extern I64 PassTrace(I64 i=0b1001111101);
extern U0 StreamDir();
public extern I64 StreamExePrint(U8 *fmt,...);
public extern U0 StreamPrint(U8 *fmt,...);
public extern Bool Trace(Bool val=ON);

#help_index "Compiler/Lex"
#help_file "::/Doc/Lex"
extern U0 ClassMemberLstDel(CHashClass *c);
public extern U0 CmpCtrlDel(CCmpCtrl *cc);
public extern CCmpCtrl *CmpCtrlNew(U8 *buf=NULL,I64 flags=0,U8 *filename=NULL);
public extern I64 CmpCtrlSize(CCmpCtrl *cc);
public extern I64 IsLexExpression2Bin(
	CCmpCtrl *cc,U8 **machine_code); //FALSE=no err
public extern I64 Lex(CCmpCtrl *cc);
public extern U0 LexAttachDoc(CCmpCtrl *cc,CLexFile *tmpf=NULL,
	CDoc *doc=NULL,U8 *abs_filename=NULL,CDocEntry *doc_e=NULL,I64 col=0);
public extern CD2I32 *LexD2I32(CCmpCtrl *cc,CD2I32 *p);
public extern CD3I32 *LexD3I32(CCmpCtrl *cc,CD3I32 *p);
public extern U0 LexExcept(CCmpCtrl *cc,U8 *str=NULL);
public extern I64 LexExpression(CCmpCtrl *cc);
public extern U8 *LexExpression2Bin(CCmpCtrl *cc,I64 *_type=NULL);
public extern F64 LexExpressionF64(CCmpCtrl *cc);
public extern I64 LexExpressionI64(CCmpCtrl *cc);
public extern U8 *LexExtStr(CCmpCtrl *cc,I64 *_size=NULL,Bool lex_next=TRUE);
public extern U8 *LexFirstRem(CCmpCtrl *cc,U8 *marker,I64 _len=NULL);
public extern I64 LexGetChar(CCmpCtrl *cc);
public extern U0 LexPopNoRestore(CCmpCtrl *cc);
public extern U0 LexPopRestore(CCmpCtrl *cc);
public extern U0 LexPush(CCmpCtrl *cc);
public extern U0 LexPutLine(CCmpCtrl *cc,U8 *start);
public extern U0 LexPutPos(CCmpCtrl *cc);
public extern U0 LexPutToken(CCmpCtrl *cc);
public extern U0 LexSkipEol(CCmpCtrl *cc);
public extern U8 *LexStmt2Bin(
	CCmpCtrl *cc,I64 *_type,I64 cmp_flags=CMPF_PRS_SEMICOLON);
public extern U0 LexWarn(CCmpCtrl *cc,U8 *str=NULL);
extern CMemberLst *MemberClassBaseFind(
	CHashClass *needle_class,CHashClass *haystack_class);
public extern CMemberLst *MemberFind(U8 *needle_str,CHashClass *haystack_class);
extern U0 MemberLstDel(CMemberLst *tmpm);
public extern I64 MemberMetaData(U8 *st,CMemberLst *ml);
public extern CMemberLstMeta *MemberMetaFind(U8 *st,CMemberLst *ml);
public extern CHashClass *OptClassFwd(CHashClass *tmpc);
public extern I64 PrsKeyWord(CCmpCtrl *cc);

#help_index "Compiler;Cmd Line (Typically)"
extern I64 Cmp(U8 *filename,
	U8 *map_name=NULL,U8 *out_name=NULL,U8 mapfile_drv_let=0);

#help_index "Debugging/Unassemble"
public extern U8 *U(U8 *rip,I64 cnt=20,I64 seg_size=64);
public extern U0 Ui(U8 *buf,U8 **_rip,I64 seg_size=64,
	I64 *_jmp_dst=NULL,Bool just_ins=FALSE);
public extern I64 Un(U8 *rip,I64 cnt=0x80,I64 seg_size=64);

#help_index "Hash/System"
public extern I64 HashEntrySize(CHashSrcSym *tmph);
public extern I64 HashEntrySize2(CHashSrcSym *tmph);
public extern I64 HashTableSize2(CHashTable *table);

#help_index "Profiler"

public extern U0 Prof(I64 depth=10,I64 cpu_num=0);
/*Start collecting profiler statistics.
Profilers report where time is spent
by sampling RIP during the $TX,"",D="DD_JIFFY_HZ"$
timer interrupt.

Do a $LK,"ProfRep",A="MN:ProfRep"$(), (profiler report)
after you have collected data.
*/
public extern U0 ProfRep(I64 filter_cnt=1,Bool leave_it=OFF); //Profiler report. Call $LK,"Prof",A="MN:Prof"$() first and collect data.

#help_index ""

