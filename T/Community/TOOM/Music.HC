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
U0 PlaySoundTask(U8 *name) {
  if(cur_snd_task) return;
  cur_snd_task=Fs;
  U8 buf[16];
  CWadDirectory *wad_dir;
  I64 s;
  StrPrint(buf,"DP%s",name);
  if(!W_GetLumpPtrFromName(buf))
    return name;
again:
  CPCSpkSnd *freqs=FramePtr(buf,doom_task);
  if(freqs) {
    music.mute++;
    for(s=0;s!=freqs->samples;s++) {
      if(!freqs->body[s])
        Snd;
      else
        Snd(22+freqs->body[s]>>1);
      Sleep(JIFFY_FREQ/140.);
    }
    Snd;
    music.mute--;
  } else {
    
    FramePtrAdd(buf,W_GetLumpPtrFromName(buf),doom_task);
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
