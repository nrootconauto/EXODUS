F64 tS()
{//Time since boot in seconds as a float.
  return cnts.jiffies/ToF64(JIFFY_FREQ);
}
Bool Blink(F64 Hz=2.5)
{//Return TRUE, then FALSE, then TRUE at given frequency.
  if (!Hz) return 0;
  return ToI64(cnts.jiffies*2*Hz/JIFFY_FREQ)&1;
}

U16 EndianU16(U16)
{//Swap big<-->little endian.
  U16 reg RAX r;
  XOR  RAX,RAX
  MOV  AX,U16 SF_ARG1[RBP]
  XCHG AL,AH
  return r;
}

U32 EndianU32(U32)
{//Swap big<-->little endian.
  U32 reg RAX r;
  XOR   RAX,RAX
  MOV   EAX,U32 SF_ARG1[RBP]
  BSWAP EAX
  return r;
}

I64 EndianI64(I64)
{//Swap big<-->little endian.
  U64 reg RAX r;
  MOV   RAX,SF_ARG1[RBP]
  BSWAP RAX
  return r;
}
#help_index "Bit"


I64 BCnt(I64 i)
{//Count set bits in I64.
  MOV   RAX,SF_ARG1[RBP]
  MOV   RDX,RAX
  SHR1  RDX
  MOV   RCX,0x5555555555555555
  AND   RDX,RCX
  SUB   RAX,RDX
  MOV   RCX,0x3333333333333333
  MOV   RDX,RAX
  AND   RAX,RCX
  SHR   RDX,2
  AND   RDX,RCX
  ADD   RAX,RDX
  MOV   RDX,RAX
  SHR   RDX,4
  ADD   RAX,RDX
  MOV   RCX,0x0f0f0f0f0f0f0f0f
  AND   RAX,RCX
  MOV   RCX,0x0101010101010101
  IMUL2 RAX,RCX
  SHR   RAX,0x38
}

#help_index "Time"

U0 IntCore0TimerHndlr(I64 mS) {
  lock cnts.jiffies+=mS;
  cnts.timer+=mS*SYS_TIMER0_PERIOD+1;
}

public U0 SleepUntil(I64 wake_jiffy) {
  Bool old_idle=LBts(&Fs->task_flags,TASKf_IDLE);
  Fs->wake_jiffy=wake_jiffy;
  Yield;
  LBEqu(&Fs->task_flags,TASKf_IDLE,old_idle);
}

public U0 Sleep(I64 mS) {
  SleepUntil(cnts.jiffies+mS);
}

#help_index ""

F64 Ona2Freq(I8 ona)
{//Ona to freq. Ona=60 is 440.0Hz.
  if (!ona)
    return 0;
  else
    return 440.0/32*2.0`(ona/12.0);
}

I8 Freq2Ona(F64 freq)
{//Freq to Ona. 440.0Hz is Ona=60.
  if (freq>0)
    return ClampI64(12*Log2(32.0/440.0*freq),1,I8_MAX);
  else
    return 0;
}

U0 Snd(I8 ona=0) {
    SndFreq(ToI64(Ona2Freq(ona)));
}

Bool Silent(Bool val=ON)
{//Turn-off StdOut console text. (Not sound.)
  return LBEqu(&(Fs->display_flags),DISPLAYf_SILENT,val);
}

Bool IsSilent()
{//Return StdOut turned-off?
  return Bt(&(Fs->display_flags),DISPLAYf_SILENT);
}

U0 ProgressBarsRst(U8 *path=NULL)
{//Reset all progress bars to zero.
  CallExtStr("ProgressBarsRegTf",path);
  MemSet(sys_progresses,0,sizeof(sys_progresses));
}
