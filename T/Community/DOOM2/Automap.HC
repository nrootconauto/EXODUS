#ifndef AUTOMAP_H 
#define AUTOMAP_H "Poopsauce"
class CAutomapState {
  F64 x,y;
  F64 zoom,angle;
  Bool follow,active,all;
} am_state;
MemSet(&am_state,0,sizeof CAutomapState);
am_state.follow=TRUE;
am_state.zoom=1;
#ifdef DOOM2
#define HUSTR_1	"level 1: entryway"
#define HUSTR_2	"level 2: underhalls"
#define HUSTR_3	"level 3: the gantlet"
#define HUSTR_4	"level 4: the focus"
#define HUSTR_5	"level 5: the waste tunnels"
#define HUSTR_6	"level 6: the crusher"
#define HUSTR_7	"level 7: dead simple"
#define HUSTR_8	"level 8: tricks and traps"
#define HUSTR_9	"level 9: the pit"
#define HUSTR_10	"level 10: refueling base"
#define HUSTR_11	"level 11: 'o' of destruction!"

#define HUSTR_12	"level 12: the factory"
#define HUSTR_13	"level 13: downtown"
#define HUSTR_14	"level 14: the inmost dens"
#define HUSTR_15	"level 15: industrial zone"
#define HUSTR_16	"level 16: suburbs"
#define HUSTR_17	"level 17: tenements"
#define HUSTR_18	"level 18: the courtyard"
#define HUSTR_19	"level 19: the citadel"
#define HUSTR_20	"level 20: gotcha!"

#define HUSTR_21	"level 21: nirvana"
#define HUSTR_22	"level 22: the catacombs"
#define HUSTR_23	"level 23: barrels o' fun"
#define HUSTR_24	"level 24: the chasm"
#define HUSTR_25	"level 25: bloodfalls"
#define HUSTR_26	"level 26: the abandoned mines"
#define HUSTR_27	"level 27: monster condo"
#define HUSTR_28	"level 28: the spirit world"
#define HUSTR_29	"level 29: the living end"
#define HUSTR_30	"level 30: icon of sin"

#define HUSTR_31	"level 31: wolfenstein"
#define HUSTR_32	"level 32: grosse"
#else
#define HUSTR_E1M1	"E1M1: Hangar"
#define HUSTR_E1M2	"E1M2: Nuclear Plant"
#define HUSTR_E1M3	"E1M3: Toxin Refinery"
#define HUSTR_E1M4	"E1M4: Command Control"
#define HUSTR_E1M5	"E1M5: Phobos Lab"
#define HUSTR_E1M6	"E1M6: Central Processing"
#define HUSTR_E1M7	"E1M7: Computer Station"
#define HUSTR_E1M8	"E1M8: Phobos Anomaly"
#define HUSTR_E1M9	"E1M9: Military Base"

#define HUSTR_E2M1	"E2M1: Deimos Anomaly"
#define HUSTR_E2M2	"E2M2: Containment Area"
#define HUSTR_E2M3	"E2M3: Refinery"
#define HUSTR_E2M4	"E2M4: Deimos Lab"
#define HUSTR_E2M5	"E2M5: Command Center"
#define HUSTR_E2M6	"E2M6: Halls of the Damned"
#define HUSTR_E2M7	"E2M7: Spawning Vats"
#define HUSTR_E2M8	"E2M8: Tower of Babel"
#define HUSTR_E2M9	"E2M9: Fortress of Mystery"

#define HUSTR_E3M1	"E3M1: Hell Keep"
#define HUSTR_E3M2	"E3M2: Slough of Despair"
#define HUSTR_E3M3	"E3M3: Pandemonium"
#define HUSTR_E3M4	"E3M4: House of Pain"
#define HUSTR_E3M5	"E3M5: Unholy Cathedral"
#define HUSTR_E3M6	"E3M6: Mt. Erebus"
#define HUSTR_E3M7	"E3M7: Limbo"
#define HUSTR_E3M8	"E3M8: Dis"
#define HUSTR_E3M9	"E3M9: Warrens"

#define HUSTR_E4M1	"E4M1: Hell Beneath"
#define HUSTR_E4M2	"E4M2: Perfect Hatred"
#define HUSTR_E4M3	"E4M3: Sever The Wicked"
#define HUSTR_E4M4	"E4M4: Unruly Evil"
#define HUSTR_E4M5	"E4M5: They Will Repent"
#define HUSTR_E4M6	"E4M6: Against Thee Wickedly"
#define HUSTR_E4M7	"E4M7: And Hell Followed"
#define HUSTR_E4M8	"E4M8: Unto The Cruel"
#define HUSTR_E4M9	"E4M9: Fear"
#endif
U0 AutomapInteract() {
  static F64 button_delay=0;
  if(Bt(kbd.down_bitmap,Char2ScanCode('\t')))
    if(button_delay+.1<tS)
      am_state.active^=TRUE,button_delay=tS;
  if(!am_state.active) return;

  if(Bt(kbd.down_bitmap,Char2ScanCode('f')))
    if(button_delay+.1<tS)
      am_state.follow^=TRUE,button_delay=tS;
  if(am_state.follow) {
    am_state.x=p->x;
    am_state.y=p->y;
    am_state.angle=p->angle;
  } else {
    if(Bt(kbd.down_bitmap,Char2ScanCode('w')))
      am_state.y-=am_state.zoom;
    else if(Bt(kbd.down_bitmap,Char2ScanCode('s')))
      am_state.y+=am_state.zoom;
    else if(Bt(kbd.down_bitmap,Char2ScanCode('a')))
      am_state.x-=am_state.zoom;
    else if(Bt(kbd.down_bitmap,Char2ScanCode('d')))
      am_state.x+=am_state.zoom;
  }
  if(Bt(kbd.down_bitmap,Char2ScanCode('='))) {
    am_state.zoom+=.1;
  } else if(Bt(kbd.down_bitmap,Char2ScanCode('-'))) {
    am_state.zoom-=.1;
  }
  am_state.zoom=Clamp(am_state.zoom,1/16.,1.);
}
U0 DrawAutomap(CDC *dc,CDoomLevel *l) {
  I64 mat;
  Bool all=l->has_map;
  U8 buf[STR_LEN],*title;
  F64 x=am_state.x;
  F64 y=am_state.y;
  F64 zoom=am_state.zoom;
  F64 rot=am_state.angle;
  dc->flags|=DCF_TRANSFORMATION;
  DCFill(dc,BLACK);
  Mat4x4IdentEqu(dc->r);
  Mat4x4TranslationEqu(dc->r,-x,-y,0);
  Mat4x4RotZ(dc->r,-rot+pi/2);
  Mat4x4RotX(dc->r,pi); //Our view is flipped in TOOM
  Mat4x4Scale(dc->r,am_state.zoom);
  Mat4x4TranslationAdd(dc->r,GR_WIDTH/2,GR_HEIGHT/2,0);
  CDoomLinedef *ld,*head;
  CDoomActionSector *special;
  CDoomThing *t;
  head=&l->linedefs;
#ifdef DOOM2
  StrScan(l->map_name,"MAP%d",&mat);
  StrPrint(buf,"HUSTR_%d",mat);
#else
  StrPrint(buf,"HUSTR_%s",l->map_name);
#endif
  title=Define(buf);   
  for(ld=head->next;ld!=head;ld=ld->next) {
    if(!ld->seen&&!all)
      goto skip;
//RED is solid line
      //YELLOW is door/ceil
      //BROWN is floor 
      //GRAY not yet seen
    if(!ld->seen&&all) {
      dc->color=LTGRAY;
    } else if(special=ld->special_type) {
      if(special->door.type=='Ceil') {
        dc->color=YELLOW;
      } else if(special->door.type=='Door') {
        dc->color=YELLOW;
      } else if(special->door.type=='Lift') {
        dc->color=BROWN;
      } else if(special->door.type=='Stairs') {
        dc->color=BROWN;
      } else if(special->door.type=='Donut') {
        dc->color=BROWN;
      }
    } else {
      dc->color=RED;
    }
    dc->thick=3;
    GrLine3(dc,ld->start->x,ld->start->y,0,ld->end->x,ld->end->y,0);
skip:;
  }
  dc->color=WHITE;
  GrArrow3(dc,
        p->x,
        p->y,
        0,
        p->x+32*Cos(p->angle),
        p->y+32*Sin(p->angle),
        0);
 if(title)
    DoomPrint(dc,10,GR_HEIGHT-64-25,"%s",title);
}
#endif;