#exe {Cd(__DIR__);;};;
#define FPTRS 1
#include "KernelA.HH"
asm {
  ALIGN 16,0; //MUST ALIGN SYS_FIXED_AREA TO 16 TO AVOID SEGUALTS WITH FXSAVE
};
CSysFixedArea sys_fixed_area,*SYS_FIXED_AREA;
SYS_FIXED_AREA=&sys_fixed_area;
U0 InitFX() {
  I64 noreg ptr;
  ptr=SYS_FIXED_AREA;
  MOV RAX,&ptr[RBP]
  FXSAVE U64[RAX]
}
InitFX;
CCPU cpu_structs[MP_PROCESSORS_NUM];
U32 SYS_CTRL_ALT_FLAGS=0;
//[0xE8,0x100) is a UserReserved block in TEB
//it's used by WinSrv/NTFS driver but not touched in usermode
//using C side thread-local storage with FFI reduces headache but also perf
asm {
_GET_FS::
	XOR	EAX,EAX
	MOV	RAX,GS:0xE8[RAX]
	RET
_SET_FS::
	PUSH	RBP
	MOV	RBP,RSP
	XOR	EAX,EAX
	PUSH	RSI
	MOV	RSI,SF_ARG1[RBP]
	MOV	GS:0xE8[RAX],RSI
	POP	RSI
	POP	RBP
	RET1	8
_GET_GS::
	XOR	EAX,EAX
	MOV	RAX,GS:0xF0[RAX]
	RET
_SET_GS::
	PUSH	RBP
	MOV	RBP,RSP
	XOR	EAX,EAX
	PUSH	RSI
	MOV	RSI,SF_ARG1[RBP]
	MOV	GS:0xF0[RAX],RSI
	POP	RSI
	POP	RBP
	RET1	8
}
_extern _GET_FS CTask* GetFs();
_extern _SET_FS U0 SetFs(CTask *);
_extern _GET_GS CCPU *GetGs();
_extern _SET_GS U0 SetGs(CCPU *);

Bool IsRaw() {
  return __IsCmdLine;
}
CHeapCtrl ahc,ahd;
CTask _boot_task;
SetFs(&_boot_task);
HeapCtrlInit(&ahc,Fs,0);
HeapCtrlInit(&ahd,Fs,1);
Fs->data_heap=&ahd;
Fs->code_heap=&ahc;
SetGs(&cpu_structs[0]);
QueInit(&Gs->next_dying);
TaskInit(Fs,0);
CTask *adam_task=Fs;
#include "Kernel/KGLBLS.HC"
#include "DOLDOC/DocExt.HC"
#include "Kernel/KUTILS.HC"
#include "Kernel/KMATH.HC"
#include "Kernel/HASH.HC"
#include "Kernel/STR.HC"
#include "KernelB.HH"
#include "GR/Gr.HH"
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
#include "Compiler/CMP_PRJ.HC"
CInit;
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
#help_index ""
#include "Adam/WINMGR.HC"
#include "Kernel/KDBG.HC"
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
