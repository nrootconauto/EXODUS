#exe {Cd(__DIR__);;};;
#define FPTRS 1
#include "KERNELA.HH"
asm {
  ALIGN 16,0; //MUST ALIGN SYS_FIXED_AREA TO 16 TO AVOID SEGUALTS WITH FXSAVE
};
CSysFixedArea sys_fixed_area,*SYS_FIXED_AREA;
SYS_FIXED_AREA=&sys_fixed_area;
U0 InitFX() {
  I64 noreg ptr;
  ptr=SYS_FIXED_AREA;
  MOV RAX,U64 &ptr[RBP];
  FXSAVE U64[RAX]
}
InitFX;
CHeapCtrl ahc,ahd;
CTask _boot_task;
SetFs(&_boot_task);
HeapCtrlInit(&ahc,Fs,0);
HeapCtrlInit(&ahd,Fs,1);
Fs->data_heap=&ahd;
Fs->code_heap=&ahc;
CCPU cpu_structs[MP_PROCESSORS_NUM],
    *mp_cores[MP_PROCESSORS_NUM];
U32 SYS_CTRL_ALT_FLAGS=0;
U0 _InitCpus() {
  I64 i;
  for (i=0;i<mp_cnt;++i)
    mp_cores[i]=cpu_structs+i;
}
_InitCpus;
SetGs(mp_cores[0]);
CCPU *Gs2() {
  return GetGs;
}
QueInit(&Gs->next_dying);
TaskInit(Fs,0);
CTask *Fs2() {
  return Fs;
}
Bool IsRaw() {
  return __IsCmdLine;
}
Bool dol_doc_inited=FALSE;
#include "Kernel/KGLBLS.HC"
#include "DOLDOC/DocExt.HC"
#include "Kernel/KUTILS.HC"
#include "Kernel/KMATH.HC"
#include "Kernel/HASH.HC"
#include "Kernel/STR.HC"
#include "KERNELB.HH"
#include "GR/Gr.HH"
public extern I64 ExeCmdLine(CCmpCtrl *cc);
CTask *adam_task=Fs;
#include "Kernel/KDate.HC"
#include "Compiler/CHASH.HC"
#include "Kernel/STRB.HC"
#include "Kernel/FUNSEG.HC"
#include "Kernel/STRPRINT.HC"
#include "Kernel/KDATATYPES.HC"
#include "Kernel/COMPRESS.HC"
#include "Kernel/QSORT.HC"
#include "Kernel/KEXCEPT.HC"
#include "Kernel/DISPLAY.HC"
#include "Mem/MakeMem.HC"
#include "BlkDev2/MakeBlkDev.HC"
#include "Kernel/Sched.HC"
#include "Kernel/KDBG.HC"
#ifdef COMPONENT_COMPILER
#include "Compiler/CMP_PRJ.HC"
CInit;
#endif
#include "Adam/AMATH.HC"
#include "Kernel/FONT.HC"
#include "Kernel/FONT2.HC"
#include "Kernel/KMISC.HC"
#include "Kernel/KBMESSAGE.HC"
#include "Kernel/MOUSE.HC"
#include "Kernel/JOB.HC"
#include "Kernel/KTASK.HC"
#include "Kernel/KDefine.HC"
#include "Kernel/KLOAD.HC"
#include "Kernel/KEND.HC"
#include "Kernel/EDLITE.HC"
#ifdef COMPONENT_GRAPHICS
#include "Adam/TASK_SETTINGS.HC"
#include "Adam/ASND.HC"
#include "Adam/AMathODE.HC.Z";
#include "GR/MakeGr.HC"
#include "Adam/MENU.HC"
#include "Adam/WIN.HC"
#include "DOLDOC/MakeDoc.HC"

#help_index "Ctrls"
#include "Ctrls/CTRLSA.HC"
#include "Ctrls/CTRLSBTTN.HC"
#include "Ctrls/CTRLSSLIDER.HC"
#include "Adam/WINMGR.HC"
#include "AutoComplete/MakeAC.HC"
#include "God/MakeGod.HC"
#include "Adam/Opt/Find.HC"
#include "Adam/ARegistry.HC"
#include "Adam/AHash.HC"
#include "Adam/ADskA.HC"
#include "Adam/ADskB.HC"
#include "Adam/ADBG.HC"
#include "Diff.HC"
#include "Adam/Opt/CPURep.HC"
#include "Kernel/KeyDev.HC"
#include "Adam/FILEMGR.HC"
#include "Adam/Training.HC"
#include "Adam/InFile.HC"
#include "Adam/Opt/Mount.HC"
#include "Adam/TaskRep.HC"
#include "Adam/Opt/DocUtils.HC"
#include "Adam/Opt/StrUtils.HC"
#include "Adam/Opt/Merge.HC"
#include "Adam/Opt/Profiler.HC"
#include "HomeKeyPlugIns.HC"
#include "Adam/MakeISOFile.HC"
#endif
