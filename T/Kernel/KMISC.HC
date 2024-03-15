F64 tS()
{//Time since boot in seconds as a float.
  return __GetTicksHP/JIFFY_FREQ;
}
Bool Blink(F64 Hz=2.5)
{//Return TRUE, then FALSE, then TRUE at given frequency.
  if (!Hz) return 0;
  return ToI64(__GetTicks*2*Hz/1000.)&1;
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

asm {
_BCNT::
//Count set bits in I64.
  MOV  R8,8[RSP]
  XOR  RAX,RAX
  XOR  RCX,RCX//data dep
@@0:
  TEST R8,R8
  JZ   @@1
  BSF  RCX,R8
  MOV  RDX,1
  SHL  RDX,CL
  NOT  RDX
  AND  R8,RDX
  INC  RAX
  JMP  @@0
@@1:
  RET1 8
}

_extern _BCNT I64 BCnt(I64);

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
