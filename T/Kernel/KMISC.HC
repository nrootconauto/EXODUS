F64 tS()
{//Time since boot in seconds as a float.
  return __GetTicks/1000.;
}
Bool Blink(F64 Hz=2.5)
{//Return TRUE, then FALSE, then TRUE at given frequency.
  if (!Hz) return 0;
  return ToI64(__GetTicks*2*Hz/1000.)&1;
}

U16 EndianU16(U16 d)
{//Swap big<-->little endian.
  I64 res=0;
  res.u8[1]=d.u8[0];
  res.u8[0]=d.u8[1];
  return res;
}

U32 EndianU32(U32 d)
{//Swap big<-->little endian.
  I64 res=0;
  res.u8[3]=d.u8[0];
  res.u8[2]=d.u8[1];
  res.u8[1]=d.u8[2];
  res.u8[0]=d.u8[3];
  return res;
}

I64 EndianI64(I64 d)
{//Swap big<-->little endian.
  U64 res;
  res.u8[7]=d.u8[0];
  res.u8[6]=d.u8[1];
  res.u8[5]=d.u8[2];
  res.u8[4]=d.u8[3];
  res.u8[3]=d.u8[4];
  res.u8[2]=d.u8[5];
  res.u8[1]=d.u8[6];
  res.u8[0]=d.u8[7];
  return res;
}
#help_index "Bit"
I64 BCnt(I64 d)
{//Count set bits in I64.
  I64 res=0,i;
  for (i=0;i<8;i++)
    res+=set_bits_table[d.u8[i]];
  return res;
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
