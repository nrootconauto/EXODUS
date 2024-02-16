#define COMPONENT_COMPILER 1
#define COMPONENT_GRAPHICS 1
#define IMPORT_BUILTINS 1
#define INIT_EVERYTHING 1
#define FPTRS 1
//#define GEN_HEADERS 1
#define USE_DOLDOC 1
#include "HCRT_TOS.HC"
#ifdef GEN_HEADERS
#include"GenHeaders.HC";
CDoc *unfound=DocNew("unfound.DD");
#endif
static U0 BootstrapImportSymbol(U8 *name,U8 *ptr,U64 type) {
  CHash *find=HashFind(name,Fs->hash_table,-1);
  if(find&&find->type&HTT_GLBL_VAR) {
    find(CHashGlblVar*)->data_addr=ptr;
  } else if(find&&find->type&HTT_FUN&&!(find(CHashFun*)->flags&1<<Ff_INTERNAL)) {
    find(CHashFun*)->exe_addr=ptr;
    Btr(&find(CHashFun*)->flags,Cf_EXTERN);
  } else if(name[0]=='_'||!StrNCmp(name,"SYS",3)||!find) {
    find=CAlloc(sizeof(CHashExport));
    find->str=StrNew(name);
    find->type=HTT_EXPORT_SYS_SYM;
    find(CHashExport*)->val=ptr;
    HashAdd(find,Fs->hash_table);
#ifdef GEN_HEADERS
    DocPrint(unfound,"%s\n",name);
#endif
  } else {
#ifdef GEN_HEADERS
    DocPrint(unfound,"%s\n",name);
#endif
  }
}

U0 LoadImps() {
  try {
    ExePutS("#define FPTRS;\n");
    ExeFile("KERNELA.HH");
    __BootstrapForeachSymbol(&BootstrapImportSymbol);
#ifdef GEN_HEADERS
    DocWrite(unfound);
    DocDel(unfound);
#endif
//Load asm externs second
    ExePrint("#define BOOT_TOS;\n");
    ExeFile("KERNELB.HH");
  } catch {
    TOSPrint("FDSF:%c\n",Fs->except_ch);
    Fs->catch_except=TRUE;
  }
}

U0 StartUpTasks()
{
  try {
    ExeFile("WallPaper.HC");
    ExePrint("WallPaperInit;;");
    ExePrint("#include \"AMOUSE.HC\";;");
  } catch PutExcept;
  User;
  WinTileVert;
  Silent;
  ACInit("PUBLIC.HC;KERNEL*.HH");
  Silent(OFF);
  AutoComplete(ON);
}

//cpu_structs[Gs->num=__CoreNum]=Gs;//It should be 0
SetFs(adam_task);
//DEBUGGING INFORMATION WILL BE APPENDED TO THESE SYMBOLS
LoadImps;
//Load symbols into adam_task
if (FileFind("HCRT.DBG.Z"))
  DbgInfoRead("HCRT.DBG.Z");
//Our entering thread doesnt have a cur_thrd,so spawn one
Gs->seth_task=Spawn(&CoreAPSethTask,NULL,"Seth");
U0 __InitCPUs() {
  I64 idx;
  for (idx=Gs->num+1;idx<mp_cnt;++idx)
    __SpawnCore(&CoreAPSethTask);
  for (idx=Gs->num+1;idx<mp_cnt;++idx)
    while (!Bt(&seth_tasks_ready,idx))
      Yield;
}
__InitCPUs;
try {
  if (__IsCmdLine)
    Drv('Z');
  ExePrint("%s;\n",__CmdLineBootText);
} catch PutExcept;
U0 _InitUI() {
  CTask *u;
  if (__IsCmdLine) {
    PCSpkInit;
    User;
    DeathWait(&u);
    Shutdown;
  } else {
    sys_winmgr_task=Spawn(&WinMgrTask);
    DrawWindowNew;
    PaletteSetStd;
    Refresh; // Wait for window manager
    PCSpkInit;
    StartUpTasks;
    SrvTaskCont;
  }
}
_InitUI;
#include "PUBLIC.HC";;
