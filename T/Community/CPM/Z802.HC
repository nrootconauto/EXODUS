#exe {Cd(__DIR__);;};;
#include "ANSI.HC";
//#define DBG 
#ifdef DBG
U0 DbgLog(U8 *fmt,...) {
        U8 *fmted=StrPrintJoin(NULL,fmt,argc,argv);
        Free(fmted);
}
#else
#define DbgLog 0&&
#endif
//https://github.com/redcode/Z80/blob/master/sources/Z80.c
#define Z80_DBG_NEXT 0
#define Z80_DBG_STEP 1
#define Z80_DBG_FIN 2
class CZ80 {
  I64 dbg_state;
  U16 _zPC;
  U16 _zSP;
  U16 _zIX;
  U16 _zIY;
  U16 _zAF;
  U16 _zBC;
  U16 _zDE;
  U16 _zHL;
  U16 _zAF_;
  U16 _zBC_;
  U16 _zDE_;
  U16 _zHL_;
  U16 _zXY;
  U8 RAM[U16_MAX+1];
} Z80,*z80=&Z80;
#define zPC z80->_zPC
#define zSP z80->_zSP
#define zIX z80->_zIX
#define zIY z80->_zIY
#define zAF z80->_zAF
#define zBC z80->_zBC
#define zDE z80->_zDE
#define zHL z80->_zHL
#define zXY z80->_zXY


#define zAF_ z80->_zAF_
#define zBC_ z80->_zBC_
#define zDE_ z80->_zDE_
#define zHL_ z80->_zHL_


#define DATA Z80._zDATA
#define MEMPTR Z80._zMEMPTR
#define zF z80->_zAF.u8[0]
#define zA z80->_zAF.u8[1]
#define zC z80->_zBC.u8[0]
#define zB z80->_zBC.u8[1]
#define zE z80->_zDE.u8[0]
#define zD z80->_zDE.u8[1]
#define zL z80->_zHL.u8[0]
#define zH z80->_zHL.u8[1]


#define zRAM z80->RAM

//#define DBG 1
U0 DumpRegs() {
#ifdef DBG
  TOSPrint("AF:%p,",zA);
  if(Bt(&zF,7)) TOSPrint("S,");
  if(Bt(&zF,6)) TOSPrint("Z,");
  if(Bt(&zF,4)) TOSPrint("H,");
  if(Bt(&zF,2)) TOSPrint("P,");
  if(Bt(&zF,1)) TOSPrint("N,");
  if(Bt(&zF,0)) TOSPrint("C,");
  TOSPrint("\n");
  return;
  TOSPrint("BC:%p,%p\n",zB,zC);
  TOSPrint("DE:%p,%p\n",zD,zE);
  TOSPrint("HL:%p,%p\n",zH,zL);
  TOSPrint("SP:%p\n",zSP);
#endif
}

I64 Fetch8(U16 ptr) {
  U8 *s=z80->RAM;
  return s[ptr&0xffFF];
}
U0 Write8(U16 ptr,U8 v) {
  z80->RAM[ptr&0xFFff]=v;
}
I64 Fetch16(U16 ptr) {
  U16 ret;
  ret.u8[0]=Fetch8(ptr);
  ret.u8[1]=Fetch8(ptr+1);
  return ret;
}
U0 Write16(U16 ptr,U16 v) {
  Write8(ptr,v.u8[0]);
  Write8(ptr+1,v.u8[1]);
}

#define SF (1<<7)
#define ZF (1<<6)
#define YF (1<<5)
#define HF (1<<4)
#define XF (1<<3)
#define PF (1<<2)
#define NF (1<<1)
#define CF (1)
U8 FlagTableAdd[0x10000];
U8 FlagTableSub[0x10000];
U8 FlagTableAdc[0x20000];
U8 FlagTableSbc[0x20000];
U8 FlagTableXor[0x100];
U8 FlagTableAnd[0x100];
U8 FlagTableInc[0x100];
U8 FlagTableDec[0x100];

I64 BCnt(U16 p) {
  I64 cnt=0;
  while(p) {
    p&=~(1<<Bsf(p));
    cnt++;
  }
  return cnt;
}
U0 PopulateTables() {
  I64 noreg a;
  I64 noreg b;
  I64 _b,res,c;
  for(a=0;a!=0x100;a++) {
    FlagTableInc[a]=0;
    FlagTableInc[a]|=ToBool(a&0x80)*SF;
    FlagTableInc[a]|=(BCnt(a)%2==0)*PF;
    FlagTableInc[a]|=(a&0xf==0)*HF;
    FlagTableInc[a]|=(a==0)*ZF;
    
    FlagTableDec[a]=0;
    FlagTableDec[a]|=ToBool(a&0x80)*SF;
    FlagTableDec[a]|=!(a&0xf==0xf)*HF;
    FlagTableDec[a]|=(a==0)*ZF;
    FlagTableDec[a]|=(BCnt(a)%2==0)*PF;
  }
  for(a=0;a!=0x100;a++)
    for(_b=0;_b!=0x100;_b++) {
//Add
      b=_b;
      FlagTableAdd[a<<8|b]=0;
      FlagTableAdd[a<<8|b]|=((a+b)&0xff==0)*ZF;
      FlagTableAdd[a<<8|b]|=((a+b)&0x80==0x80)*SF;
//Heres the deal,if we xor,that sweitches the bits and tellls us if we carried
      res=a+b;
      FlagTableAdd[a<<8|b]|=ToBool((res^a^b)&1<<8)*CF;
      FlagTableAdd[a<<8|b]|=ToBool((res^a^b)&1<<4)*HF;
      FlagTableAdd[a<<8|b]|=(BCnt(res&0xff)%2==0)*PF;
//Sub
      b=_b;
      res=a-b;
      FlagTableSub[a<<8|_b]=0;
      FlagTableSub[a<<8|_b]|=((res)&0xff==0)*ZF;
      FlagTableSub[a<<8|_b]|=((res)&0x80==0x80)*SF;
//Heres the deal,if we xor,that sweitches the bits and tellls us if we carried
      FlagTableSub[a<<8|_b]|=ToBool((res^a^b)&1<<8)*CF;
      FlagTableSub[a<<8|_b]|=ToBool(~(res^a^b)&1<<4)*HF;
      FlagTableSub[a<<8|_b]|=(BCnt(res&0xff)%2==0)*PF;
//And
      b=_b;
      res=a&b;
      FlagTableAnd[res]=0;
      FlagTableAnd[res]|=(res&0xff==0)*ZF;
      FlagTableAnd[res]|=(res&0x80==0x80)*SF;
      FlagTableAnd[res]|=(BCnt(res&0xff)%2==0)*PF;
//Xor
      b=_b;
      res=a^b;
      FlagTableXor[res]=0;
      FlagTableXor[res]|=(res&0xff==0)*ZF;
      FlagTableXor[res]|=(res&0x80==0x80)*SF;
      FlagTableXor[res]|=(BCnt(res&0xff)%2==0)*PF;
    }
  for(c=0;c!=2;c++)
    for(a=0;a!=0x100;a++)
      for(_b=0;_b!=0x100;_b++) {
//Adc
        b=_b;
        FlagTableAdc[a<<8|b|c<<16]=0;
        FlagTableAdc[a<<8|b|c<<16]|=((a+b+c)&0xff==0)*ZF;
        FlagTableAdc[a<<8|b|c<<16]|=((a+b+c)&0x80==0x80)*SF;
//Heres the deal,if we xor,that sweitches the bits and tellls us if we carried
        res=a+b+c;
        FlagTableAdc[a<<8|b|c<<16]|=ToBool((res^a^b)&1<<8)*CF;
        FlagTableAdc[a<<8|b|c<<16]|=ToBool((res^a^b)&1<<4)*HF;
        FlagTableAdc[a<<8|b|c<<16]|=(BCnt(res&0xff)%2==0)*PF;
//Sbc
        b=_b;
        res=a-b-c;
        FlagTableSbc[a<<8|_b|c<<16]=0;
        FlagTableSbc[a<<8|_b|c<<16]|=(res&0xff==0)*ZF;
        FlagTableSbc[a<<8|_b|c<<16]|=(res&0x80==0x80)*SF;
//Heres the deal,if we xor,that sweitches the bits and tellls us if we carried
        FlagTableSbc[a<<8|_b|c<<16]|=ToBool((res^a^b)&1<<8)*CF;
        FlagTableSbc[a<<8|_b|c<<16]|=ToBool(~(res^a^b)&1<<4)*HF;
        FlagTableSbc[a<<8|_b|c<<16]|=(BCnt(res&0xff)%2==0)*PF;
      }
}
PopulateTables;
U16 Z80Pop() {
  U16 r=zRAM[zSP](U16);
  zSP+=2;
  return r;
}
U0 Z80Push(U16 p) {
  zRAM[zSP-=2](U16)=p;
}
U0 Z80Call(U16 addr) {
  Z80Push(zPC);
  zPC=addr;
}
U0 Z80Run() {
  I64 sum,cy;
  switch(Fetch8(zPC)) {
      break; case 0x00:
      zPC++;
      break; case 0x01:
      zBC=Fetch16(zPC+1);
      zPC+=3;
      break; case 0x02:
      zRAM[zBC]=zA;
      zPC++;
      break; case 0x03:
      zBC++;
      zPC++;
      break; case 0x04:
      zF&=CF;
      zF|=FlagTableInc[++zB];
      zPC++;
      break; case 0x05:
      zF&=CF;
      zF|=FlagTableSub[--zB];
      zPC++;
      break; case 0x06:
      zB=zRAM[zPC+1];
      zPC+=2;
      break; case 0x07:
      zF&=~CF;
      zF|=CF*zA>>7;
      zA=zA<<1|zA>>7;
      zPC++;
      break; case 0x08:
      SwapU16(&zAF,&zAF_);
      zPC++;
      break; case 0x09:
      sum=zHL+zBC;
      zF&=~CF;
      zF|=CF*(sum>>16&1);
      zHL=sum;
      zPC++;
      break; case 0x0a:
      zA=zRAM[zBC];
      zPC++;
      break; case 0x0b:
      zBC--;
      zPC++;
      break; case 0x0c:
      zF&=CF;
      zF|=FlagTableInc[++zC];
      zPC++;
      break; case 0x0d:
      zF&=CF;
      zF|=FlagTableDec[0xff&--zC];
      zPC++;
      break; case 0x0e:
      zC=zRAM[zPC+1];
      zPC+=2;
      break; case 0x0f:
      zF&=~CF;
      zF|=CF*(zA&1);
      zA=zA>>1|(zA&1)<<7;
      zPC++;
      break; case 0x10:
      if(--zB)
        zPC+=2+zRAM[zPC+1](I8);
      else
        zPC+=2;
      break; case 0x11:
      zDE=zRAM[zPC+1](U16);
      zPC+=3;
      break; case 0x12:
      zRAM[zDE]=zA;
      zPC++;
      break; case 0x13:
      zDE++;
      zPC++;
      break; case 0x14:
      zF&=CF;
      zF|=FlagTableInc[++zD];
      zPC++;
      break; case 0x15:
      zF&=CF;
      zF|=FlagTableDec[--zD];
      zPC++;
      break; case 0x16:
      zD=zRAM[zPC+1];
      zPC+=2;
      break; case 0x17:
      sum=zA>>7;
      zA=zA<<1|ToBool(zF&CF);
      zF&=~CF;
      zF|=CF*sum;
      zPC++;
      break; case 0x18:
      zPC+=2+zRAM[zPC+1](I8);
      break; case 0x19:
      sum=zHL+zDE;
      zF&=~CF;
      zF|=CF*(sum>>16&1);
      zHL=sum;
      zPC++;
      break; case 0x1a:
      zA=zRAM[zDE];
      zPC++;
      break; case 0x1b:
      zDE--;
      zPC++;
      break; case 0x1c:
      zF&=CF;
      zF|=FlagTableInc[++zE];
      zPC++;
      break; case 0x1d:
      zF&=CF;
      zF|=FlagTableDec[--zE];
      zPC++;
      break; case 0x1e:
      zE=zRAM[zPC+1];
      zPC+=2;
      break; case 0x1f:
      sum=zA&1;
      zA=zA>>1|ToBool(zF&CF)<<7;
      zF&=~CF;
      zF|=CF*sum;
      zPC++;
      break; case 0x20:
      if(zF&ZF)
        zPC+=2;
      else
        zPC=2+zRAM[zPC+1](I8);
      break; case 0x21:
      zHL=zRAM[zPC+1](U16);
      zPC+=3;
      break; case 0x22:
      zRAM[zRAM[zPC+1](U16)](U16)=zHL;
      zPC+=3;
      break; case 0x23:
      zPC++;
      zHL++; 
      break;case 0x24:
      zF&=CF;
      zF|=FlagTableInc[++zH];
      zPC++;
      break;case 0x25:
      zPC++;
      zF&=CF;
      zF|=FlagTableDec[--zH];
      break;case 0x26:
      zH=zRAM[zPC+1];
      zPC+=2;
      break;case 0x27:
//https://stackoverflow.com/questions/8119577/z80-daa-instruction
      zPC++;
      cy=ToBool(zF&CF);
      sum=0;
      if(zF&HF||zA&0xf>9)
        sum=0x06;
      if(zF&CF||zA>>4>9||(zA>>4>=9&&zA&0xF>9)) {
        sum+=0x60;
        cy=TRUE;
      }
      zF=FlagTableAdd[zA<<8|sum];
      zA+=sum;
      zF&=~CF;
      zF|=cy*CF;
      break; case 0x28:
      if(zF&ZF)
        zPC+=2+zRAM[zPC+1](I8);
      else 
        zPC+=2;
      break;case 0x29:
      sum=zHL+zHL;
      zF&=~CF;
      zF|=CF*(sum>>16&1);
      zHL=sum;
      zPC++;
      break; case 0x2a:
      zHL=zRAM[zRAM[zPC+1](U16)](U16);
      zPC+=3;
      break; case 0x2b:
      zHL--;
      zPC++;
      break; case 0x2c:
      zF&=CF;
      zF|=FlagTableInc[++zL];
      zPC++;
      break; case 0x2d:
      zF&=CF;
      zF|=FlagTableDec[--zL];
      zPC++;
      break; case 0x2e:
      zL=zRAM[zPC+1];
      zPC+=2;
      break; case 0x2f:
      zA=~zA;
      zPC++;
      break; case 0x30:
      if(zF&CF)
        zPC+=2;
      else
        zPC+=2+zRAM[zPC+1](I8);
      break; case 0x31:
      zSP=zRAM[zPC+1](U16);
      zPC+=3;
      break; case 0x32:
      zRAM[zRAM[zPC+1](U16)]=zA;
      zPC+=3;
      break; case 0x33:
      zSP++;
      zPC++;
      break; case 0x34:
      zF&=CF;
      zF|=FlagTableInc[++zRAM[zHL]];
      zPC++;
      break; case 0x35:
      zF&=CF;
      zF|=FlagTableDec[--zRAM[zHL]];
      zPC++;
      break; case 0x36:
      zRAM[zHL]=zRAM[zPC+1];
      zPC+=2;
      break; case 0x37:
      zF|=CF;
      zPC++;     
      break; case 0x38:
      if(zF&CF)
        zPC+=2+zRAM[zPC+1](I8);
      else
        zPC+=2;
      break; case 0x39:
      sum=zHL+zSP;
      zF&=~CF;
      zF|=CF*(sum>>16&1);
      zHL=sum;
      zPC++;
      break; case 0x3a:
      zA=zRAM[zRAM[zPC+1](U16)];
      zPC+=3;
      break; case 0x3b:
      zSP--;
      zPC++;
      break; case 0x3c:
      zF&=CF;
      zF|=FlagTableInc[++zA];
      zPC++;
      break; case 0x3d:
      zF&=CF;
      zF|=FlagTableDec[--zA];
      zPC++;
      break; case 0x3e:
      zA=zRAM[zPC+1];
      zPC+=2;
      break; case 0x3f:
      zF^=CF;
      zPC++;
      break; case 0x40:
      zPC++;
      break; case 0x41:
      zB=zC;
      zPC++;
      break; case 0x42:
      zB=zD;
      zPC++;
      break; case 0x43:
      zB=zE;
      zPC++;
      break; case 0x44:
      zB=zH;
      zPC++;
      break; case 0x45:
      zB=zL;
      zPC++;
      break; case 0x46:
      zB=zRAM[zHL];
      zPC++;
      break; case 0x47:
      zB=zA;
      zPC++;
      break; case 0x48:
      zC=zB;
      zPC++;
      break; case 0x49:
      zPC++;
      break; case 0x4a:
      zC=zD;
      zPC++;
      break; case 0x4b:
      zC=zE;
      zPC++;
      break; case 0x4c:
      zC=zH;
      zPC++;
      break; case 0x4d:
      zC=zL;
      zPC++;
      break; case 0x4e:
      zC=zRAM[zHL];
      zPC++;
      break; case 0x4f:
      zC=zA;
      zPC++;
      break; case 0x50:
      zD=zB;
      zPC++;
      break; case 0x51:
      zD=zC;
      zPC++;
      break; case 0x52:
      zPC++;
      break; case 0x53:
      zD=zE;
      zPC++;
      break; case 0x54:
      zD=zH;
      zPC++;
      break; case 0x55:
      zD=zL;
      zPC++;
      break; case 0x56:
      zD=zRAM[zHL];
      zPC++;
      break; case 0x57:
      zD=zA;
      zPC++;
      break; case 0x58:
      zE=zB;
      zPC++;
      break; case 0x59:
      zE=zC;
      zPC++;
      break; case 0x5a:
      zE=zD;
      zPC++;
      break; case 0x5b:
      zPC++;
      break; case 0x5c:
      zE=zH;
      zPC++;
      break; case 0x5d:
      zE=zL;
      zPC++;
      break; case 0x5e:
      zE=zRAM[zHL];
      zPC++;
      break; case 0x5f:
      zE=zA;
      zPC++;
      break; case 0x60:
      zH=zB;
      zPC++;
      break; case 0x61:
      zH=zC;
      zPC++;
      break; case 0x62:
      zH=zD;
      zPC++;
      break; case 0x63:
      zH=zE;
      zPC++;
      break; case 0x64:
      zPC++;
      break; case 0x65:
      zH=zL;
      zPC++;
      break; case 0x66:
      zH=zRAM[zHL];
      zPC++;
      break; case 0x67:
      zH=zA;
      zPC++;
      break; case 0x68:
      zL=zB;
      zPC++;
      break; case 0x69:
      zL=zC;
      zPC++;
      break; case 0x6a:
      zL=zD;
      zPC++;
      break; case 0x6b:
      zL=zE;
      zPC++;
      break; case 0x6c:
      zL=zH;
      zPC++;
      break; case 0x6d:
      zPC++;
      break; case 0x6e:
      zL=zRAM[zHL];
      zPC++;
      break; case 0x6f:
      zL=zA;
      zPC++;
      break; case 0x70:
      zRAM[zHL]=zB;
      zPC++;
      break; case 0x71:
      zRAM[zHL]=zC;
      zPC++;
      break; case 0x72:
      zRAM[zHL]=zD;
      zPC++;
      break; case 0x73:
      zRAM[zHL]=zE;
      zPC++;
      break; case 0x74:
      zRAM[zHL]=zH;
      zPC++;
      break; case 0x75:
      zRAM[zHL]=zL;
      zPC++;
      break; case 0x76:
      //HALTTODO
      zPC++;
      break; case 0x77:
      zRAM[zHL]=zA;
      zPC++;
      break; case 0x78:
      zA=zB;
      zPC++;
      break; case 0x79:
      zA=zC;
      zPC++;
      break; case 0x7a:
      zA=zD;
      zPC++;
      break; case 0x7b:
      zA=zE;
      zPC++;
      break; case 0x7c:
      zA=zH;
      zPC++;
      break; case 0x7d:
      zA=zL;
      zPC++;
      break; case 0x7e:
      zA=zRAM[zHL];
      zPC++;
      break; case 0x7f:
      zPC++;
      break; case 0x80:
      zF=FlagTableAdd[zA<<8|zB];
      zA+=zB;
      zPC++;
      break; case 0x81:
      zF=FlagTableAdd[zA<<8|zC];
      zA+=zC;
      zPC++;
      break; case 0x82:
      zF=FlagTableAdd[zA<<8|zD];
      zA+=zD;
      zPC++;
      break; case 0x83:
      zF=FlagTableAdd[zA<<8|zE];
      zA+=zE;
      zPC++;
      break; case 0x84:
      zF=FlagTableAdd[zA<<8|zH];
      zA+=zH;
      zPC++;
      break; case 0x85:
      zF=FlagTableAdd[zA<<8|zL];
      zA+=zL;
      zPC++;
      break; case 0x86:
      zF=FlagTableAdd[zA<<8|zRAM[zHL]];
      zA+=zRAM[zHL];
      zPC++;
      break; case 0x87:
      zF=FlagTableAdd[zA<<8|zA];
      zA+=zA;
      zPC++;
      break; case 0x88:
      sum=ToBool(zF&CF);
      zF=FlagTableAdc[zA<<8|zB|ToBool(zF&CF)<<16];
      zA+=zB+sum;
      zPC++;
      break;case 0x89:
      sum=ToBool(zF&CF);
      zF=FlagTableAdc[zA<<8|zC|ToBool(zF&CF)<<16];
      zA+=zC+sum;
      zPC++;
      break;case 0x8a:
      sum=ToBool(zF&CF);
      zF=FlagTableAdc[zA<<8|zD|ToBool(zF&CF)<<16];
      zA+=zD+sum;
      zPC++;
      break;case 0x8b:
      sum=ToBool(zF&CF);
      zF=FlagTableAdc[zA<<8|zE|ToBool(zF&CF)<<16];
      zA+=zE+sum;
      zPC++;
      break;case 0x8c:
      sum=ToBool(zF&CF);
      zF=FlagTableAdc[zA<<8|zH|ToBool(zF&CF)<<16];
      zA+=zH+sum;
      zPC++;
      break;case 0x8d:
      sum=ToBool(zF&CF);
      zF=FlagTableAdc[zA<<8|zL|ToBool(zF&CF)<<16];
      zA+=zL+sum;
      zPC++;
      break;case 0x8e:
      sum=ToBool(zF&CF);
      zF=FlagTableAdc[zA<<8|zRAM[zHL]|ToBool(zF&CF)<<16];
      zA+=zRAM[zHL]+sum;
      zPC++;
      break;case 0x8f:
      sum=ToBool(zF&CF);
      zF=FlagTableAdc[zA<<8|zA|ToBool(zF&CF)<<16];
      zA+=zA+sum;
      zPC++;
      break;case 0x90:
      zF=FlagTableSub[zA<<8|zB];
      zA-=zB;
      zPC++;
      break;case 0x91:
      zF=FlagTableSub[zA<<8|zC];
      zA-=zC;
      zPC++;
      break;case 0x92:
      zF=FlagTableSub[zA<<8|zD];
      zA-=zD;
      zPC++;
      break;case 0x93:
      zF=FlagTableSub[zA<<8|zE];
      zA-=zE;
      zPC++;
      break;case 0x94:
      zF=FlagTableSub[zA<<8|zH];
      zA-=zH;
      zPC++;
      break;case 0x95:
      zF=FlagTableSub[zA<<8|zL];
      zA-=zL;
      zPC++;
      break;case 0x96:
      zF=FlagTableSub[zA<<8|zRAM[zHL]];
      zA-=zRAM[zHL];
      zPC++;
      break;case 0x97:
      zF=FlagTableSub[zA<<8|zA];
      zA-=zA;
      zPC++;
      break;case 0x98: 
      sum=ToBool(zF&CF);
      zF=FlagTableSbc[zA<<8|zB|ToBool(zF&CF)<<16];
      zA-=zB;
      zA-=sum;
      zPC++;
      break;case 0x99: 
      sum=ToBool(zF&CF);
      zF=FlagTableSbc[zA<<8|zC|ToBool(zF&CF)<<16];
      zA-=zC;
      zA-=sum;
      zPC++;
      break;case 0x9a:
      sum=ToBool(zF&CF);
      zF=FlagTableSbc[zA<<8|zD|ToBool(zF&CF)<<16];
      zA-=zD;
      zA-=sum;
      zPC++;
      break;case 0x9b:
      sum=ToBool(zF&CF);
      zF=FlagTableSbc[zA<<8|zE|ToBool(zF&CF)<<16];
      zA-=zE;
      zA-=sum;
      zPC++;
      break;case 0x9c:
      sum=ToBool(zF&CF);
      zF=FlagTableSbc[zA<<8|zH|ToBool(zF&CF)<<16];
      zA-=zH;
      zA-=sum;
      zPC++;
      break;case 0x9d:
      sum=ToBool(zF&CF);
      zF=FlagTableSbc[zA<<8|zL|ToBool(zF&CF)<<16];
      zA-=zL;
      zA-=sum;
      zPC++;
      break;case 0x9e:
      sum=ToBool(zF&CF);
      zF=FlagTableSbc[zA<<8|zRAM[zHL]|ToBool(zF&CF)<<16];
      zA-=zRAM[zHL];
      zA-=sum;
      zPC++;
      break;case 0x9f:
      sum=ToBool(zF&CF);
      zF=FlagTableSbc[zA<<8|zA|ToBool(zF&CF)<<16];
      zA-=zA;
      zA-=sum;
      zPC++;
      break;case 0xa0:
      zPC++;
      sum=zA;
      zF=FlagTableAnd[zA&=zB]|((sum|zB)&0x8!=0)*HF;
      break;case 0xa1:
      sum=zA;
      zPC++;
      zF=FlagTableAnd[zA&=zC]|((sum|zC)&0x8!=0)*HF;
      break;case 0xa2:
      sum=zA;
      zPC++;
      zF=FlagTableAnd[zA&=zD]|((sum|zD)&0x8!=0)*HF;
      break;case 0xa3:
      sum=zA;
      zPC++;
      zF=FlagTableAnd[zA&=zE]|((sum|zE)&0x8!=0)*HF;
      break;case 0xa4:
      zPC++;
      sum=zA;
      zF=FlagTableAnd[zA&=zH]|((sum|zH)&0x8!=0)*HF;
      break;case 0xa5:
      zPC++;
      sum=zA;
      zF=FlagTableAnd[zA&=zL]|((sum|zL)&0x8!=0)*HF;
      break;case 0xa6:
      zPC++;
      sum=zA;
      zF=FlagTableAnd[zA&=zRAM[zHL]]|((sum|zRAM[zHL])&0x8!=0)*HF;
      break;case 0xa7:
      sum=zA;
      zPC++;
      zF=FlagTableAnd[zA&=zA]|((sum|zA)&0x8!=0)*HF;
      break;case 0xa8:
      zPC++;
      zF=FlagTableXor[zA^=zB];
      break;case 0xa9:
      zPC++;
      zF=FlagTableXor[zA^=zC];
      break;case 0xaa:
      zPC++;
      zF=FlagTableXor[zA^=zD];
      break;case 0xab:
      zPC++;
      zF=FlagTableXor[zA^=zE];
      break;case 0xac:
      zPC++;
      zF=FlagTableXor[zA^=zH];
      break;case 0xad:
      zPC++;
      zF=FlagTableXor[zA^=zL];
      break;case 0xae:
      zPC++;
      zF=FlagTableXor[zA^=zRAM[zHL]];
      break;case 0xaf:
      zPC++;
      zF=FlagTableXor[zA^=zA];
      break;case 0xb0:
      zPC++;
      zF=FlagTableXor[zA|=zB];
      break;case 0xb1:
      zPC++;
      zF=FlagTableXor[zA|=zC];
      break;case 0xb2:
      zPC++;
      zF=FlagTableXor[zA|=zD];
      break;case 0xb3:
      zPC++;
      zF=FlagTableXor[zA|=zE];
      break;case 0xb4:
      zPC++;
      zF=FlagTableXor[zA|=zH];
      break;case 0xb5:
      zPC++;
      zF=FlagTableXor[zA|=zL];
      break;case 0xb6:
      zPC++;
      zF=FlagTableXor[zA|=zRAM[zHL]];
      break;case 0xb7:
      zPC++;
      zF=FlagTableXor[zA|=zA];
      break;case 0xb8:
      zPC++;
      zF=FlagTableSub[zA<<8|zB];
      break;case 0xb9:
      zPC++;
      zF=FlagTableSub[zA<<8|zC];
      break;case 0xba:
      zPC++;
      zF=FlagTableSub[zA<<8|zD];
      break;case 0xbb:
      zPC++;
      zF=FlagTableSub[zA<<8|zE];
      break;case 0xbc:
      zPC++;
      zF=FlagTableSub[zA<<8|zH];
      break;case 0xbd:
      zPC++;
      zF=FlagTableSub[zA<<8|zL];
      break;case 0xbe:
      zPC++;
      zF=FlagTableSub[zA<<8|zRAM[zHL]];
      break;case 0xbf:
      zPC++;
      zF=FlagTableSub[zA<<8|zA];
      break;case 0xc0:
      zPC++;
      if(!(zF&ZF==ZF))
        zPC=Z80Pop;
      break;case 0xc1:
      zBC=Z80Pop;
      zPC++;
      break;case 0xc2:
      zPC+=3;
      if(!(zF&ZF==ZF))
        zPC=zRAM[zPC-2](U16);
      break;case 0xc3:
      zPC=zRAM[zPC+1](U16);
      break;case 0xc4:
      zPC+=3;
      if(!(zF&ZF==ZF)) {
        Z80Call(zRAM[zPC-2](U16));
      }
      break;case 0xc5:
      zPC++;
      Z80Push(zBC);
      break;case 0xc6:
      zF=FlagTableAdd[zA<<8|zRAM[zPC+1]];
      zA+=zRAM[zPC+1];
      zPC+=2;
      break;case 0xc7:
      zPC++;
      Z80Push(zPC);
      zPC=0;
      break;case 0xc8:
      zPC++;
      if(zF&ZF)
        zPC=Z80Pop;
      break;case 0xc9:
      zPC=Z80Pop;
      break;case 0xca:
      zPC+=3;
      if(zF&ZF)
        zPC=zRAM[zPC-2](U16);
      break;case 0xcb:
      //Undoc jump
      zPC=zRAM[zPC+1](U16);
      break;case 0xcc:
      zPC+=3;
      if(zF&ZF)
        Z80Call(zRAM[zPC-2](U16));
      break;case 0xcd:
      zPC+=3;
      Z80Call(zRAM[zPC-2](U16));
      break;case 0xce:
      zPC+=2;
      sum=ToBool(zF&CF);
      zF=FlagTableAdc[zA<<8|zRAM[zPC-1]|ToBool(zF&CF)<<16];
      zA+=zRAM[zPC-1]+sum;
      break;case 0xcf:
      zPC++;
      Z80Push(zPC);
      zPC=8;
      break;case 0xd0:
      zPC++;
      if(!(zF&CF))
        zPC=Z80Pop;
      break;case 0xd1:
      zPC++;
      zDE=Z80Pop;
      break;case 0xd2:
      zPC+=3;
      if(!(zF&CF))
        zPC=zRAM[zPC-2](U16);
      break;case 0xd3:
      break;case 0xd4:
      zPC+=3;
      if(!(zF&CF))
        Z80Call(zRAM[zPC-2](U16));
      break;case 0xd5:
      zPC++;
      Z80Push(zDE);
      break;case 0xd6:
      zPC+=2;
      zF=FlagTableSub[zA<<8|zRAM[zPC-1]];
      zA-=zRAM[zPC-1];
      break;case 0xd7:
      Z80Push(zPC);
      z80=0x10;
      break;case 0xd8:
      zPC++;
      if(zF&CF)
        zPC=Z80Pop;
      break;case 0xd9:
      SwapU16(&zBC,&z80->_zBC_);
      SwapU16(&zDE,&z80->_zDE_);
      SwapU16(&zHL,&z80->_zHL_);
      break;case 0xda:
      zPC+=3;
      if(zF&CF)
        zPC=zRAM[zPC-2](U16);
      break;case 0xdb:
      break;case 0xdc:
      zPC+=3;
      if(zF&CF)
        Z80Call(zRAM[zPC-2](U16));
      break;case 0xdd:
      //Undoc call
      zPC+=3;
      Z80Call(zRAM[zPC-2](U16));
      break;case 0xde:
      zPC+=2;
      sum=ToBool(zF&CF);
      zF=FlagTableSbc[zA<<8|zRAM[zPC-1]|ToBool(zF&CF)<<16];
      zA-=zRAM[zPC-1]+sum;
      break;case 0xdf:
      zPC++;
      Z80Push(zPC);
      z80=0x18;
      break;case 0xe0:
      zPC++;
      if(!(zF&PF))
        zPC=Z80Pop;
      break;case 0xe1:
      zPC++;
      zHL=Z80Pop;
      break;case 0xe2:
      zPC+=3;
      if(!(zF&PF))
        zPC=zRAM[zPC-2](U16);
      break;case 0xe3:
      SwapU16(&zRAM[zSP],&z80->_zHL);
      zPC++;
      break;case 0xe4:
      zPC+=3;
      if(!(zF&PF))
        Z80Call(zRAM[zPC-2](U16));
      break;case 0xe5:
      zPC++;
      Z80Push(zHL);
      break;case 0xe6:
      zPC+=2;
      zF=FlagTableAnd[zA&=zRAM[zPC-1]]|((zA|zRAM[zPC-1])&0x8!=0)*HF;
      break;case 0xe7:
      zPC++;
      Z80Push(zPC);
      zPC=0x20;
      break;case 0xe8:
      zPC++;
      if(zF&PF)
        zPC=Z80Pop;
      break;case 0xe9:
      zPC=zHL;
      break;case 0xea:
      zPC+=3;
      if(zF&PF)
        zPC=zRAM[zPC-2](U16);
      break;case 0xeb:
      SwapU16(&zDE,&zHL);
      zPC++;
      break;case 0xec:
      zPC+=3;
      if(zF&PF)
        Z80Call(zRAM[zPC-2](U16));
      break;case 0xed:
      zPC+=3;
      Z80Call(zRAM[zPC-2](U16));
      break;case 0xee:
      zF=FlagTableXor[zA^=zRAM[zPC+1]];
      zPC+=2;
      break;case 0xef:
      zPC++;
      Z80Push(zPC);
      zPC=0x28;
      break;case 0xf0:
      zPC++;
      if(!(zF&SF))
        zPC=Z80Pop;
      break;case 0xf1:
      zPC++;
      zAF=Z80Pop;
      zF&=0b11010101;
      zF|=0b10;
      break;case 0xf2:
      zPC+=3;
      if(!ToBool(zF&SF))
        zPC=zRAM[zPC-2](U16);
      break;case 0xf3:
      zPC++;
      break;case 0xf4:
      zPC+=3;
      if(!ToBool(zF&SF))
        Z80Call(zRAM[zPC-2](U16));
      break;case 0xf5:
      zPC++;
//In 8080,bit 1 is always set 
      zAF|=0b10;
      Z80Push(zAF);
      break;case 0xf6:
      zPC+=2;
      zF=FlagTableXor[zA|=zRAM[zPC-1]];
      break;case 0xf7:
      zPC++;
      Z80Push(zPC);
      zPC=0x30;
      break;case 0xf8:
      zPC++;
      if(zF&SF)
        zPC=Z80Pop;
      break;case 0xf9:
      zSP=zHL;
      zPC++;
      break;case 0xfa:
      zPC+=3;
      if(zF&SF)
        zPC=zRAM[zPC-2](U16);
      break;case 0xfb:
      break;case 0xfc:
      zPC+=3;
      if(zF&SF)
        Z80Call(zRAM[zPC-2](U16));
      break;case 0xfe:
      zPC+=2;
      zF=FlagTableSub[zA<<8|zRAM[zPC-1]];
      break;case 0xff:
      zPC++;
      Z80Push(zPC);
      zPC=0x38;
  }
}
class CFCB {
  U8 DR; //Drive
  U8 F[8]; //File.8
  U8 T[3]; //File.3
  U8 EX; //0-31 extent number
  U8 S[2]; //Zero this stuff
  U8 RC; //Record count  0-127
  U8 D[16]; //Do not use
  U8 CR; // curent record
  U8 R[3]; //0-655535 random record
};
#define BOOT 0x0
#define FDOS (0xffff)
#define TBASE (BOOT+0x100)

#define FCB_F1 0x5C
#define FCB_F2 0x6C

#define CBLK_SZ 128
U0 TerminalWriteChr(U8 chr) {
  U8 buf[2];
  buf[0]=chr;
  buf[1]=0;
  TermPrint(buf);
}
class CCPM {
  U8 drive,user;
  U16 DMA_ADDR,DP_ADDR;
  CFifoI64 *keys;
} CPM;
MemSet(&CPM,0,sizeof CCPM);
CPM.keys=FifoI64New(0x100);
U8 *SkipWhitespace(U8 *ptr) {
  while(*ptr&&Bt(char_bmp_white_space,*ptr)) ptr++;
  return ptr;
}
extern U0 CPM_LoadProgram(U8 *bin,I64 len,Bool run_once=FALSE,U8 *fa=NULL,U8 *fb=NULL,U8 *prompt=NULL);
Bool IsSeperator(U8 c) {
  switch(c) {
    case ' ':
    case ':':
    case '=':
    case ';':
    case '<':
    case '>':
    return TRUE;
  }
  return FALSE;
}
U0 CCP(U8 *buffer=NULL,Bool sub=FALSE) {
  U8 prompt[0x100],*path,com_buf[0x100],f1[0x100],f2[0x200],*ptr,*ptr2,*ptr3,*hn,*bptr=buffer;
  CDirEntry *ents,*c_ent,ent;
  I64 pages;
  TermPrint("Welcome to Holy Control-Program/Monitor\n");
  loop2:
  if(!sub){
    StrPrint(prompt,"%c%d> ",CPM.drive+'A',CPM.user);
    TermPrint(prompt);
    buffer=TermGetStr;
    TermPrint("\n");
  } else if(*bptr) {
    ptr=StrFirstOcc(bptr,"\r\n");
    if(!ptr) ptr=bptr+StrLen(bptr);
    buffer=MAlloc(ptr-bptr+1);
    buffer[ptr-bptr]=0;
    MemCpy(buffer,bptr,ptr-bptr);
    bptr=ptr;
    while(StrOcc("\n\r",*bptr))
      bptr++;
    bptr=SkipWhitespace(bptr);
  } else {
    return;
  }
  path=MStrPrint("%c/%d",CPM.drive+'A',CPM.user);
  if(!FileFind(path))
    DirMk(path);
  Free(path);

  ptr=SkipWhitespace(buffer);
  ptr2=com_buf;
  while(Bt(char_bmp_alpha_numeric,*ptr)||*ptr=='.')
    *ptr2++=*ptr++;
  ptr=SkipWhitespace(ptr);
  *ptr2++=0;
  ptr2=f1;
  while(Bt(char_bmp_alpha_numeric,*ptr)||*ptr=='.')
    *ptr2++=*ptr++;
  while(*ptr&&IsSeperator(*ptr))
    ptr++;
  *ptr2++=0;
  if(StrLen(f1))
    CatPrint(f1,".CPM");
  ptr2=f2;
  while(Bt(char_bmp_alpha_numeric,*ptr)||*ptr=='.')
    *ptr2++=*ptr++;
  *ptr2++=0;
  if(StrLen(f2))
    CatPrint(f2,".CPM");
  if(!StrICmp(com_buf,"HELP")) {
    TermPrint("LISTEN UP,HERE ARE THE COMMANDS DUDE\n");
    TermPrint("RENAME FILE:\n");
    TermPrint("    REN NEW_NAME=OLD_NAME\n");
    TermPrint("SAVE 10 RAM PAGES TO A FILE\n");
    TermPrint("    SAVE 10 RAM.BAM\n");
    TermPrint("TYPE A FILE TO THE SCREENY\n");
    TermPrint("    TYPE TOADS.TXT\n");
    TermPrint("EXIT OUT OF EMULATOR\n");
    TermPrint("    EXIT\n");
    TermPrint("RUN COMMANDS IN A FILE\n");
    TermPrint("    STUFF.SUB\n");
    TermPrint("LOAD A BINARY LUMP\n");
    TermPrint("    POOP.COM\n");
    TermPrint("HAVE FUN!!!\n");
  } else if(!StrICmp(com_buf,"REN")) {
    ptr=SkipWhitespace(prompt)+StrLen(com_buf);
    if(!StrFirstOcc(ptr,"=")) {
      TermPrint("REN X=Y\n");
    } else {
       ptr=SkipWhitespace(ptr);
       ptr2=f1;
       while((Bt(char_bmp_alpha_numeric,*ptr)||*ptr=='.')&&*ptr!='=')
         *ptr2++=*ptr++;
       *ptr2++=0;
       ptr=StrFirstOcc(ptr,"=")+1;
       ptr2=f2;
       while((Bt(char_bmp_alpha_numeric,*ptr)||*ptr=='.')&&*ptr!='=')
         *ptr2++=*ptr++;
       *ptr2++=0;
       ptr=MStrPrint("%C/%d/%s",CPM.drive+'A',CPM.user,f1);
       ptr2=MStrPrint("%C/%d/%s",CPM.drive+'A',CPM.user,f2);
       Move(ptr,ptr2);
      Free(ptr);Free(ptr2);
    }
  } else if(!StrICmp(com_buf,"SAVE")) {
    pages=Str2I64(f1)*0x100;
    if(0x10000>pages+0x100) {
      TermPrint("ONLY 64KB OF RAM(CHOOSE A SMALLER SIZE)\n");
    } else {
      hn=MStrPrint("%C/%d/%s",CPM.drive+'A',CPM.user,f2);
      FileWrite(hn,&Z80.RAM[0x100],pages);
      Free(hn);
    }
  } else if(!StrICmp(com_buf,"TYPE")) {
     if(FileFind("A/0/TAIL.COM.CPM")) {
       ptr=FileRead("A/0/TAIL.COM.CPM",&pages);
       if(*f1) ptr2=MStrPrint("%C/%d/%s",CPM.drive+'A',CPM.user,f1);
       if(*f2) ptr3=MStrPrint("%C/%d/%s",CPM.drive+'A',CPM.user,f2);
       CPM_LoadProgram(ptr,pages,,ptr2,ptr3,SkipWhitespace(buffer)+StrLen(com_buf));
       Free(ptr);Free(ptr2);Free(ptr3);
     } else 
      TermPrint("IM LOOKING FOR A/0/TAIL.COM\n");
  } else if(!StrICmp("USER",com_buf)) {
    CPM.user=Str2I64(f1)&0xf;
  } else if(!StrICmp("EXIT",com_buf)) {
    Free(buffer);
    return;
  } else {
    if(StrOcc(com_buf,'.'))
      hn=MStrPrint("%C/%d/%s.CPM",CPM.drive+'A',CPM.user,com_buf);
    else
      hn=MStrPrint("%C/%d/%s.COM.CPM",CPM.drive+'A',CPM.user,com_buf);
    if(!FileFind(hn,&ent)) {
      TermPrint("PROGRAM NOT FOUND,TYPE 'HELP' FOR HELP.\n");
    } else {
     ptr=FileRead(ent.full_name,&pages);
     Free(ent.full_name);
     if(!StrICmp(FileExtDot(ent.name),".COM.CPM")) {
       ptr2=NULL;ptr3=NULL;
       if(*f1) ptr2=MStrPrint("%C/%d/%s",CPM.drive+'A',CPM.user,f1);
       if(*f2) ptr3=MStrPrint("%C/%d/%s",CPM.drive+'A',CPM.user,f2);
       CPM_LoadProgram(ptr,pages,,ptr2,ptr3,SkipWhitespace(buffer)+StrLen(com_buf));
       Free(ptr);Free(ptr2);Free(ptr3);
     } else if(!StrICmp(FileExtDot(ent.name),".SUB.CPM")) {
       if(ptr2=StrFirstOcc(ptr,"\x1a"))
         *ptr2=0;
       CCP(ptr,TRUE);
     } else {
       StrPrint(prompt,"I DONT KNOW HOW TO RUN %s\n",ent.name);
       TermPrint(prompt);
     }
    }
    Free(hn);
    TermPrint("\n");
  }
  Free(buffer);
  goto loop2;
}
Bool *FCBMatchName(CFCB *fcb,U8 *name) {
  I64 i=0;
  U8 next;
  for(i;i!=8;i++) {
    if(fcb->F[i]==' ') {
      if(*name++!='.') return FALSE;
      break;
    } else if(fcb->F[i]=='?') {
      if(*name++=='.') goto ext;
    } else if(fcb->F[i]=='*') {
      next=fcb->F[i+1];
      if(next=='?'||next==' '){
        if(StrFirstOcc(name,"."))
	  name=StrFirstOcc(name,".")+1;
        else
	  name+=StrLen(name);
        goto ext;
      }
      while(*name!='.'&&*name!=next&&*name) {
        name++;
      }
      if(*name!=next) {
         return FALSE;
      }
    } else if(fcb->F[i]!=*name++)
      return FALSE;
  }
ext:
  for(i=0;i!=3;i++){
    if(fcb->T[i]==' ') {
      return *name==0;
    } else if(fcb->T[i]=='*') {
      if(i==2) return TRUE;
      next=fcb->T[i+1];
      if(next==' ') return TRUE;
      while(*name!=next&&*name) {
        name++;
      }
      if(!*name) return TRUE;
    } else if(fcb->T[i]=='?') {
      if(fcb->T[i+1]==' ')
        return !*name;
      else
	name++;
    } else if(fcb->T[i]!=*name++) {
      return FALSE;
    }
  }
  return TRUE;
}
U8 *FCBToHostname(CFCB *fcb) {
  U8 *name=MAlloc(64),*nptr=name,*nptr2;
  I64 i;
  if(fcb->DR&&fcb->DR!='?') {
    *nptr='A'+fcb->DR-1;
    nptr[1]='/';
    nptr+=2;
  } else {
    *nptr++=CPM.drive+'A';
    *nptr++='/';
  }
  StrPrint(nptr,"%d/",CPM.user);
  nptr+=StrLen(nptr);
  for(i=0;i!=8;i++) {
    if(fcb->F[i]!=' ')
      *nptr++=fcb->F[i];
  }
  *nptr++='.';
  for(i=0;i!=3;i++) {
    if(fcb->T[i]!=' ')
      *nptr++=fcb->T[i];
  }
  *nptr=0;
  if(!StrNCmp("??????????.",name,10)) {
    MemCpy(name,"*         .",10);
  }
  nptr2=StrLastOcc(name,".")-1;
  i=0;
  while(nptr2>name)
    if(*nptr2=='?') {
      i=1;
      *nptr2=' ';
      nptr2--;
    } else break;
  if(i) nptr2[1]='*';
  nptr2=StrLastOcc(name,".");
  if(nptr2) {
    i=0;
    nptr2+=StrLen(nptr2)-1;
    while(*nptr2!='.')
      if(*nptr2=='?'){
        *nptr2--==' ';
        i=0;
      } else break;
    if(i)
      nptr2[1]='*';
  }
  StrUtil(name,SUF_REM_SPACES);
  while(nptr=StrFirstOcc(name,"\d"))
    *nptr='D';
  CatPrint(name,".CPM");
  return name;
}
I64 FCBOffset(CFCB*fcb) {
  I64 pos=fcb->CR*128;
  pos+=fcb->EX*128*128;
  return pos;
}
I64 Read(U8 *fn,I64 off) {
  I64 len,olen;
  U8 *ftxt=FileRead(fn,&len),*ftxt2;
  if(!ftxt) return 0xff;
  olen=len;
  if(len%128||olen<off) {
    len+=128-len%128;
    if(!len||off>=olen)
      len+=128;
    ftxt2=MAlloc(len);
    MemCpy(ftxt2,ftxt,olen);
    MemSetU8(ftxt2+olen,0x1a,len-olen);
    Free(ftxt);
    ftxt=ftxt2;
  }
  MemCpy(&z80->RAM[CPM.DMA_ADDR],ftxt+off,MaxI64(0,MinI64(128,len-off)));
  Free(ftxt);
  if(off+128<=len) return 0x0;
  return 0x01;
}
I64 Write(U8 *fn,I64 off) {
  enter:;
  I64 len,olen,ret=0x00;
  U8 *ftxt=FileRead(fn,&len),*ftxt2;
  if(!ftxt) {
    FileWrite(fn,"",0);
    goto enter;
  }
  olen=len;
  if(len%128||off>=olen) {
    len+=128-len%128;
    if(off==len)
      len+=128;
    ftxt2=MAlloc(len);
    MemCpy(ftxt2,ftxt,olen);
    MemSetU8(ftxt2+olen,0x1a,len-olen);
    Free(ftxt);
    ftxt=ftxt2;
  }
  if(off+128<=len) {
    MemCpy(ftxt+off,&z80->RAM[CPM.DMA_ADDR],128);
    FileWrite(fn,ftxt,len);
  } else
    ret=0xff;
  Free(ftxt);
  return ret;
}
U0 FCBNext(CFCB *fcb) {
  if(++fcb->CR>128) {
    fcb->CR=1;
    if(++fcb->EX>128) {
      fcb->EX=1;
    }
  }
}
static I64 dir_pos;
U0 CPMScanKey() {
  I64 ch,sc;
  Sleep(10);
  if(ScanKey(&ch,&sc)) {
    if(ch&0xff=='\n') ch='\r';
    if(ch&0xff==CH_BACKSPACE) ch=127;
    switch(sc&0xff) {
      start:
        FifoI64Ins(CPM.keys,'\x1b');
        FifoI64Ins(CPM.keys,'[');
        case SC_CURSOR_UP:
	  FifoI64Ins(CPM.keys,'A');
	  break;
        case SC_CURSOR_DOWN:
	  FifoI64Ins(CPM.keys,'B');
	  break;
        case SC_CURSOR_RIGHT:
	  FifoI64Ins(CPM.keys,'C');
	  break;
        case SC_CURSOR_LEFT:
	  FifoI64Ins(CPM.keys,'D');
	  break;
      end:;
        break;
      default:
        if(!(ch&0xff)) return;
        if(sc&SCF_CTRL&&'A'<=ToUpper(ch&0xff)<='Z')  {
	  FifoI64Ins(CPM.keys,ch&0x1f);
        } else
	  FifoI64Ins(CPM.keys,ch);
    }
  }
}
U0 HostnameToFCB(CFCB*fcb,U8 *hn,Bool create=FALSE) {
  U8 *ext;
  CDirEntry ent;
  I64 i,i2;
  loop2:
  if(hn&&FileFind(hn,&ent)) {
    Free(ent.full_name);
//All files here end in .CPM to avoid being interpeted as text files
//Remove the .CPM 
    if(!StrICmp(ent.name+StrLen(ent.name)-4,".CPM"))
      ent.name[StrLen(ent.name)-4]=0;
    fcb->DR=CPM.drive; //TODO use drive of file
    fcb->EX=0;
    fcb->S[0]=0;
    fcb->S[1]=0;
    for(i2=0;i2!=8&&ent.name[i2]&&ent.name[i2]!='.';i2++)
      fcb->F[i2]=ent.name[i2];
    for(;i2!=8;i2++)
      fcb->F[i2]=' ';
    ext=FileExtDot(hn);
    i2=0;
    if(ext++) //skip dot
      for(;i2!=3&&ext[i2];i2++)
        fcb->T[i2]=ext[i2];
    for(;i2!=3;i2++)
      fcb->T[i2]=' ';
    zHL=zA=0x0;
  } else {
    if(hn&&create) {
      FileWrite(hn,"",0);
      goto loop2;
    }
    zHL=zA=0xff;
   }
}

U0 Bdos() {
  I64 ch;
  U16 optr,ptr,cap,i,i2;
  U8 *buffer,*buffer2;
  static CFCB find_fcb;
  CFCB *fcb;
  CDirEntry *ents,*c_ent;
  static CDirEntry *ents_static=NULL;
  Yield;
  switch(zC) {
case 0: //Reboot
  throw('Reboot');
  break;
case 1:
  getch:
  //Get a charactor
  while(!FifoI64Rem(CPM.keys,&ch))
    CPMScanKey;
  TerminalWriteChr(ch);
  zE=zHL=ch;
  break;
case 2:
  //Write a charactor
  TerminalWriteChr(zE);
  break;
case 6:
  //Write a charactor or get one
  if(zE==0x0ff) {
    while(!FifoI64Rem(CPM.keys,&ch))
      CPMScanKey;
    zE=zHL=ch;
  } else
    TerminalWriteChr(zHL=zE);
  break;
case 9: //Write out
  optr=zDE;
  while(Fetch8(zDE)!='\d') {
    TerminalWriteChr(Fetch8(zDE++));
  }
  zDE=optr;
  break;
case 10: //Read console line
  optr=ptr=zDE;
  cap=Fetch8(ptr);
  ptr+=2;
  buffer=TermGetStr;
  for(i=0;buffer[i]&&i<cap;i++)
    Write8(ptr+i,buffer[i]);
  Write8(optr+1,i);
  zHL=i;
  Free(buffer);
  break;
case 11:
  //Is key ready
  if(FifoI64Cnt(CPM.keys))
    zHL=0xff;
  else
    zHL=0x0;
  break;
case 12: //version
 zHL=0x22;
 break;
case 14:
  //Set drive
  CPM.drive=zE;
  break;
case 15: //Open file
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  open:
  zHL=HostnameToFCB(fcb,buffer,TRUE);
  Free(buffer);
  break;
case 16:
  //Close file
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  if(FileFind(buffer)) zA=0x0;
  else zA=0xff;
  Free(buffer);
  break;
case 17:
  //Search for first
  dir_pos=0;
  fcb=&z80->RAM[zDE];
  if(ents_static) DirEntryDel(ents_static);
  buffer2=MStrPrint("%C/%d/*.CPM",CPM.drive+'A',CPM.user);
  ents=ents_static=FilesFind(buffer2,FUF_JUST_FILES);
  if(ents) {
    MemCpy(&find_fcb,fcb,sizeof CFCB);
    zHL=zA=0;
  } else 
    zHL=zA=0xff;
  Free(buffer2);
  break;
case 18:
  //Search for next
  i2=dir_pos++;
  fcb=&z80->RAM[zDE];
  ents=ents_static;
  buffer=NULL;
  if(ents) {
    i=0;
    for(c_ent=ents;c_ent;c_ent=c_ent->next) {
      if(StrIMatch(".CPM",c_ent->name)) {
	if(!StrICmp(c_ent->name+StrLen(c_ent->name)-4,".CPM"))
	  c_ent->name[StrLen(c_ent->name)-4]=0;
      }
      if(FCBMatchName(&find_fcb,c_ent->name)){
        i++;
      } else
        goto nextf;
      if(i-1<i2)
        ;
      else{
        break;
      }
nextf:
    }
    if(i-1!=i2)
      goto find_fin;
    zHL=zA=0;
    buffer=MStrPrint("%C/%d/%s.CPM",'A'+CPM.drive,CPM.user,c_ent->name); 
    goto open;
  }
find_fin:
  DirEntryDel(ents_static);
  ents_static=NULL;
  zHL=zA=0xff;
  Free(buffer);
  break;
case 19:
  //Delete
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  Del(buffer);
  Free(buffer);
  break;
case 20:
  //Read seq
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  i=Read(buffer,FCBOffset(fcb));
  FCBNext(fcb);
  Free(buffer);
  zHL=i;
  break;
case 21:
  //Write seq
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  i=Write(buffer,FCBOffset(fcb));
  FCBNext(fcb);
  Free(buffer);
  zHL=i;
  break;
case 22:
  //Make file
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  if(!FileFind(buffer)) {
    FileWrite(buffer,"",0);
  }
  Free(buffer);
  zHL=0;
  break;
case 23:
  //Rename
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  buffer2=FCBToHostname(&z80->RAM[zDE+16]);
  Move(buffer,buffer2);
  Free(buffer),Free(buffer2);
  zHL=0;
  break;
case 24:
  //Login vector
  zHL=0;
  for(i=0;i!=16;i++) {
    buffer=MStrPrint("%c",i+'A');
    if(FileFind(buffer)&&IsDir(buffer))
      Bts(&zHL,i);
    Free(buffer);
  }
  break;
case 25:
  //GEt drive
  zHL=CPM.drive;
  break;
case 26:
  //Set dma
  CPM.DMA_ADDR=zDE;
  break;
case 29:
  zA=zHL=0;
  break;
case 31:
  zA=zHL=CPM.DP_ADDR;
  break;
case 32:
  //Set/get user code
  if(zE==0xff)
    zHL=CPM.user;
  else
    CPM.user=zE;
  break;
case 33:
  //Read random
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  i=(fcb->R[2]<<16)|(fcb->R[1]<<8)|fcb->R[0];
  zA=zHL=Read(buffer,i*0x80);
  fcb->CR=i&0x7F;
  fcb->EX=(i>>7)&0x1F;
  Free(buffer);
  break;
case 34:
  //Write random
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  i=(fcb->R[2]<<16)|(fcb->R[1]<<8)|fcb->R[0];
  zA=zHL=Write(buffer,i*0x80);
  fcb->CR=i&0x7F;
  fcb->EX=(i>>7)&0x1F;
  Free(buffer);
  break;
case 35:
  //Compute filesize
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  if(FileFind(buffer)) {
    i=VFsFSize(buffer); //TODO
    i>>=7;
    fcb->R[0]=i.u8[0];
    fcb->R[1]=i.u8[1];
    fcb->R[2]=i.u8[2];
  }
  Free(buffer);
  break;
case 36:
  //Set random recrod
  fcb=&z80->RAM[zDE];
  i=fcb->CR&0x7f;
  i+=(fcb->EX&0x1f)<<7;
  fcb->R[0]=i.u8[0];
  fcb->R[1]=i.u8[1];
  fcb->R[2]=i.u8[2];
  break;
case 40:
  //Write random(zero fill)
  fcb=&z80->RAM[zDE];
  buffer=FCBToHostname(fcb);
  i=(fcb->R[2]<<16)|(fcb->R[1]<<8)|fcb->R[0];
  zA=zHL=Write(buffer,i);
  fcb->CR=i&0x7F;
  fcb->EX=(i>>7)&0x1F;
  Free(buffer);
  break;
  }
  zBC=0;
  zA=zL;
  zB=zH;
}
#define BIOS_VECTOR_START (0x10000-3*30)
U0 Bios() {
  I64 call=(zPC-BIOS_VECTOR_START)/3,ch;
  switch(call) {
    case 1:
    case 0:
    throw('Boot');
    case 2:
    if(FifoI64Cnt(CPM.keys))
      zA=0xff;
    else
      zA=0;
    break;
    case 3:
    while(!FifoI64Rem(CPM.keys,&ch))
      CPMScanKey;
    zA=ch;
    break;
    case 4:
    TerminalWriteChr(zC);
    break;
    case 7:
    zA=0x1a;
    break;
    case 9:
    CPM.drive=zC&0xf;
    zHL=1;
    break;
    case 12:
    zHL=zBC;
    CPM.DMA_ADDR=zHL;
    break;
  }
}
U0 CPM_Z80_Run() {
  static I64 cnt;
  if(cnt++>0x8000) {
    Yield;
    cnt=0;
  }
  U0 (*foo)();
  if(zPC==FDOS) {
    Bdos;
    zPC=Z80Pop;
    return ;
  }
  if(zPC>=BIOS_VECTOR_START) {
    Bios;
    zPC=Z80Pop;
    return;
  }
  if(zPC==BOOT) {
    throw('exit');
  }
  Z80Run;  
}
U0 CPM_LoadProgram(U8 *bin,I64 len,Bool run_once=FALSE,U8 *fa=NULL,U8 *fb=NULL,U8 *prompt=NULL) {
  CDirEntry ent;
  I64 i,i2;
  CFCB *fcb;
  //Make room for BIOS vector and them some
  Z80.RAM[1](U16)=BIOS_VECTOR_START+3; //Points to WBOOT,not boot
  Z80.RAM[5](U16)=0xC3; //MAke a jump to FDOS 
  Z80.RAM[6](U16)=FDOS; //Make some room for fdos
  Z80._zSP=BIOS_VECTOR_START-2; //Right below our FDOS and bios
  Z80.RAM[Z80._zSP](U16)=0;
  Z80._zPC=0x100;
  if(!run_once)
    Z80._zDE=0x80;
  MemCpy(Z80.RAM+0x100,bin,len);
  CPM.DMA_ADDR=0x80;
  fcb=&Z80.RAM[FCB_F1];
  if(fa&&*fa) {
    HostnameToFCB(fcb,fa,TRUE);
  } else { 
    MemSetU8(fcb,0,sizeof(CFCB));
    MemSetU8(&fcb->F,' ',11);
  }
  fcb=&Z80.RAM[FCB_F2]; 
  if(fb&&*fb) {
    HostnameToFCB(fcb,fb,TRUE);
  } else { 
    MemSetU8(fcb,0,sizeof(CFCB));
    MemSetU8(&fcb->F,' ',11);
  }
  Z80.RAM[0x80]=StrLen(prompt);
  StrCpy(&Z80.RAM[0x81],prompt);
  try {
    while(zPC) {
      CPM_Z80_Run;
      if(run_once) break;
    }
  } catch {
    Fs->catch_except=TRUE;
  }
}
CCP;
Exit;
