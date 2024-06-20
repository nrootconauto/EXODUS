#ifndef MUS_H
#define MUS_H "Tee Hee Oh Shamona"
class CPCSpkSnd {
  I8 pad[2];
  I16 samples;
  U8 body[0];
};

class CMUSHeader {
  U8 mus[4];
  I16 score_len;
  I16 score_start;
  I16 channels;
  I16 sec_channels;
  I16 instrument_cnt;
  I16 instrument_types[0];
};
class CMusicUnit {
  F64 time;
  I64 freq;
};
I64 LookUpTable(I8 n) {
  return n+1;
}
CMusicUnit *MUS2Freqs(U8 *lump,I64 *freq_cnt=NULL) {
  CMUSHeader *hd=lump;
  I64 score_ptr,channel,best,worst,want_delay;
  Bool *cur_inst_freqs=CAlloc(hd->channels*128);
  CMusicUnit *freqs=CAlloc(0x100*sizeof(CMusicUnit)),*tmp;
  if(StrNCmp("MUS",hd->mus,3))
    throw('DoomMUS');
  I64 note_cnt=0,idx,idx2;
  I64 cur_inst=0;
  F64 time,avg,sum,hits;
  score_ptr=hd->score_start;
  while(TRUE) {
//https://moddingwiki.shikadi.net/wiki/MUS_Format
    channel=lump[score_ptr]&0b1111;
    want_delay=lump[score_ptr]&0x80;
    switch((lump[score_ptr]>>4)&0b111) {
      case 0: //Release note
        score_ptr++;
        cur_inst_freqs[channel*128+lump[score_ptr]]=0;
        score_ptr++;
        break;
      case 1: //Play note
        score_ptr++;
        idx=lump[score_ptr]&0x7f;
        if(lump[score_ptr]&0x80) {
//volume present TODO decrease pitch(correctly?)
	  score_ptr++;
	  cur_inst_freqs[channel*128+idx]=lump[score_ptr]&0x7f;
        } else
	  cur_inst_freqs[channel*128+idx]=127;
        score_ptr++;
        break;
      case 2: //Pitch wheel(Give me more freqenuces then maybe ill do something)
        score_ptr+=2;
        break;
      case 3: //System event
        score_ptr++;
        switch(lump[score_ptr]) {
	  case 10: //All notes halt
	  case 11: //All notes fade(TODO)
	    MemSet(cur_inst_freqs,0,hd->channels*128);
	    break;
        }
      default:
        score_ptr++;
        break;
      case 7:
        score_ptr+=2;
        break;
      case 4: //Change controller
        score_ptr++;
        if(lump[score_ptr]&0x7f==0) {
	  cur_inst=lump[score_ptr+1]&0x7f;
        }
        score_ptr+=2;
        break;
      case 6: //End
fin:
        freqs[note_cnt++].freq=-1;
	Free(cur_inst_freqs);
        if(freq_cnt) *freq_cnt=note_cnt;
        return freqs;
    }
    time=0;
time_info:
    if(want_delay) {
      time*=128;
      time+=lump[score_ptr]&0x7f;
      if(lump[score_ptr]&0x80) {
        score_ptr++;
        goto time_info;
      }
      score_ptr++;
      time/=140.;
      freqs[note_cnt].time=time;
//TODO TODO TODO do some magic
      worst=0,best=0;
      for(idx=0;idx!=hd->channels;idx++) {
        for(idx2=0;idx2!=127;idx2++) {
	  if(cur_inst_freqs[idx*128+idx2]) {
	    if(!worst)
	      worst=idx2;
	    worst=MinI64(worst,idx2);
	    best=MaxI64(best,idx2);
          }
        }
      }
//      best=ToF64(best+worst)/2+best-worst;
      if(MSize(freqs)<(note_cnt+1)*sizeof(CMusicUnit)) {
        tmp=freqs;
        freqs=MAlloc((note_cnt+0x100)*sizeof(CMusicUnit));
        MemCpy(freqs,tmp,note_cnt*sizeof(CMusicUnit));
        Free(tmp);
      }
      if(best)
        best=LookUpTable(best); //best is 0 for off,otherwise C,octave 0
      best=Ceil(best);
//If we have multiple instruments ending (on same note),use last stop
      if(note_cnt&&freqs[note_cnt-1].freq==best) {
        freqs[note_cnt-1].freq=best;
        freqs[note_cnt-1].time=Max(freqs[note_cnt-1].time,time);
      } else {
        freqs[note_cnt].freq=best;
        note_cnt++;
      }
    }
  }
  goto fin;
}
CTask *cur_snd_task=NULL;
music.mute=0;
F64 Samp2Freq(I8 n) {
//https://www.doomworld.com/idgames/sounds/pcspkr10
  switch(n) {
    case 1: return 175.00;
    case 2: return 180.02;
    case 3: return 185.01;
    case 4: return 190.02;
    case 5: return 196.02;
    case 6: return 202.02;
    case 7: return 208.01;
    case 8: return 214.02;
    case 9: return 220.02;
    case 10: return 226.02;
    case 11: return 233.04;
    case 12: return 240.02;
    case 13: return 247.03;
    case 14: return 254.03;
    case 15: return 262.00;
    case 16: return 269.03;
    case 17: return 277.03;
    case 18: return 285.04;
    case 19: return 294.03;
    case 20: return 302.07;
    case 21: return 311.04;
    case 22: return 320.05;
    case 23: return 330.06;
    case 24: return 339.06;
    case 25: return 349.08;
    case 26: return 359.06;
    case 27: return 370.09;
    case 28: return 381.08;
    case 29: return 392.10;
    case 30: return 403.10;
    case 31: return 415.01;
    case 32: return 427.05;
    case 33: return 440.12;
    case 34: return 453.16;
    case 35: return 466.08;
    case 36: return 480.15;
    case 37: return 494.07;
    case 38: return 508.16;
    case 39: return 523.09;
    case 40: return 539.16;
    case 41: return 554.19;
    case 42: return 571.17;
    case 43: return 587.19;
    case 44: return 604.14;
    case 45: return 622.09;
    case 46: return 640.11;
    case 47: return 659.21;
    case 48: return 679.10;
    case 49: return 698.17;
    case 50: return 719.21;
    case 51: return 740.18;
    case 52: return 762.41;
    case 53: return 784.47;
    case 54: return 807.29;
    case 55: return 831.48;
    case 56: return 855.32;
    case 57: return 880.57;
    case 58: return 906.67;
    case 59: return 932.17;
    case 60: return 960.69;
    case 61: return 988.55;
    case 62: return 1017.20;
    case 63: return 1046.64;
    case 64: return 1077.85;
    case 65: return 1109.93;
    case 66: return 1141.79;
    case 67: return 1175.54;
    case 68: return 1210.12;
    case 69: return 1244.19;
    case 70: return 1281.61;
    case 71: return 1318.43;
    case 72: return 1357.42;
    case 73: return 1397.16;
    case 74: return 1439.30;
    case 75: return 1480.37;
    case 76: return 1523.85;
    case 77: return 1569.97;
    case 78: return 1614.58;
    case 79: return 1661.81;
    case 80: return 1711.87;
    case 81: return 1762.45;
    case 82: return 1813.34;
    case 83: return 1864.34;
    case 84: return 1921.38;
    case 85: return 1975.46;
    case 86: return 2036.14;
    case 87: return 2093.29;
    case 88: return 2157.64;
    case 89: return 2217.80;
    case 90: return 2285.78;
    case 91: return 2353.41;
    case 92: return 2420.24;
    case 93: return 2490.98;
    case 94: return 2565.97;
  };
  return 0;
}
U0 PlaySoundTask(U8 *name) {
  if(cur_snd_task) Kill(cur_snd_task,FALSE);
  cur_snd_task=Fs;
  U8 buf[16];
  CWadDirectory *wad_dir;
  StrPrint(buf,"DP%s",name);
  CPCSpkSnd *freqs=FramePtr(buf,doom_task);
  if(freqs) goto again;
  I64 s;
  if(!W_GetLumpPtrFromName(buf)) {
    cur_snd_task=NULL;
    return;
  }
again:
  if(freqs) {
    music.mute++;
    for(s=0;s!=freqs->samples;s++) {
      if(!freqs->body[s])
        Snd;
      else
        Snd(22+Freq2Ona(freqs->body[s]));
      Sleep(1000./140.);
    }
    Snd;
    music.mute--;
  } else {    
    FramePtrAdd(buf,freqs=W_GetLumpPtrFromName(buf),doom_task);
    goto again;
  }
  cur_snd_task=NULL;
}

U0 PlayMusicTask(CMusicUnit *head) {
enter:
  CMusicUnit *cur=head;
  while(TRUE) {
    if(cur->freq==-1) {
      Yield;
      goto enter;
    }
    if(!music.mute)
      Snd(cur->freq);
    Sleep(cur->time*JIFFY_FREQ);
    cur++;
  }
}
#endif