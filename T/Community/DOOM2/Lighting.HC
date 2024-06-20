#ifndef LIGHTING_H
#define LIGHTING_H "Asshole Lightbulb"
I64 LowestSurrondingLight(CDoomSector *s) {
  I64 idx,min=255;
  CDoomLinedef *ld;
  CDoomSector *s2;
  for(idx=0;idx!=s->linedef_cnt;idx++) {
    ld=s->linedefs[idx];
    if(ld->back) {
      s2=ld->back->sector;
      if(s2&&s2!=s)
        min=MinI64(s2->base_light_level,min);
    }
    if(ld->front) {
      s2=ld->front->sector;
      if(s2&&s2!=s)
        min=MinI64(s2->base_light_level,min);
    }
  }
  return min;
}


I64 HighestSurrondingLight(CDoomSector *s) {
  I64 idx,max=0;
  CDoomLinedef *ld;
  CDoomSector *s2;
  for(idx=0;idx!=s->linedef_cnt;idx++) {
    ld=s->linedefs[idx];
    if(ld->back) {
      s2=ld->back->sector;
      if(s2&&s2!=s)
        max=MaxI64(s2->base_light_level,max);
    }
    if(ld->front) {
      s2=ld->front->sector;
      if(s2&&s2!=s)
        max=MaxI64(s2->base_light_level,max);
    }
  }
  return max;
}


class CLight1:CDoomThinkerBase {
  CDoomSector *s;
  F64 end_tS;
};
U0 Light1Thinker(CDoomLevel *l,CLight1 *t) {
  I64 tick=32*Server_tS;
  F64 r=Rand;
  CDoomSector *s=t->s;
  I64 min=LowestSurrondingLight(s);
  if(Server_tS>t->end_tS) {
    s->cur_light_level=s->base_light_level; //in case no change
    if(s->cur_light_level>min) {
      if(tick&0xf==0) {
        if(r>.75) {
	  t->end_tS=Server_tS+.75*Rand;
	  s->cur_light_level=min;
        }
      }
    }
  }
}
class CLightStrobe:CDoomThinkerBase {
  CDoomSector *s;
//rand_offset is used for not shyhcronised strobes
//0 for synchronized
  F64 end_tS,rand_offset;
  I64 mask;
};

U0 LightStrobeThinker(CDoomLevel *l,CLightStrobe *t) {
  I64 tick=32*(t->rand_offset+Server_tS);
  CDoomSector *s=t->s;
  I64 min=LowestSurrondingLight(s);
  if(Server_tS>t->end_tS) {
    s->cur_light_level=s->base_light_level;  //in case no change
    if(s->cur_light_level>min) {
change:
      if(tick&t->mask==0) {
        t->end_tS=Server_tS+.2;
        s->cur_light_level=min;
      }
    } else {
      min=0;
      goto change;
    }
  }
}

class CLightFire:CDoomThinkerBase {
  CDoomSector *s;
  F64 end_tS;
};

U0 LightFireThinker(CDoomLevel *l,CLight1 *t) {
  I64 tick=32*Server_tS;
  F64 r=Rand;
  CDoomSector *s=t->s;
  I64 min=LowestSurrondingLight(s);
  if(Server_tS>t->end_tS) {
    if(s->cur_light_level>min) {
      if(tick&0x3==0) {
        if(r>.5) {
	  t->end_tS=Server_tS+.09;
	  s->cur_light_level=min;
        }
      }
    }
  } else {
    s->cur_light_level=s->base_light_level;
  }
}
U0 LoadLightingThinkers(CDoomLevel *l) {
  CDoomSector *head=&l->sectors,*cur;
  CLight1 *l1;
  CLightStrobe *strobe;
  CLightFire *fire;
  for(cur=head->next;cur!=head;cur=cur->next) {
    switch(cur->special_type) {
      case 1:
        l1=AddThinker(l,&Light1Thinker,"CLight1");
        l1->s=cur;
        break;
      case 2:
        strobe=AddThinker(l,&LightStrobeThinker,"CLightStrobe");
        strobe->s=cur;
        strobe->mask=0x1f;
        strobe->rand_offset=Rand*64;
        break;
      case 3:
        strobe=AddThinker(l,&LightStrobeThinker,"CLightStrobe");
        strobe->s=cur;
        strobe->mask=0xf;
        strobe->rand_offset=Rand*64;
        break;
      case 12:
        strobe=AddThinker(l,&LightStrobeThinker,"CLightStrobe");
        strobe->s=cur;
        strobe->mask=0x1f;
        break;
      case 13:
        strobe=AddThinker(l,&LightStrobeThinker,"CLightStrobe");
        strobe->s=cur;
        strobe->mask=0xf;
        break;
      case 17:
        fire=AddThinker(l,&LightFireThinker,"CLightFire");
	fire->s=cur;
	break;
    }
  }
}
#endif
