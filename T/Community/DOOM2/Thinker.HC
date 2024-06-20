#ifndef THINKER_H
#define THINKER_H "BigBrain"
class CDoomThinkerBase:CQue {
  U8 cls_name[64];
  U8 (*fun_ptr)(CDoomLevel *,CDoomThinkerBase *);
};
class CDoomThinker:CDoomThinkerBase {
  I64 user_data1;
  I64 user_data2;
  I64 user_data3;
  I64 user_data4;
  I64 user_data5;
  I64 user_data6;
  I64 user_data7;
  I64 user_data8;
  I64 user_data9;
  I64 user_data10;
};
U0 UpdateThinkers(CDoomLevel *l) {
//There are lots of monsters,be sure to only update about 10 times a second(game runs at 30 fps)
  static I64 tick=0;
  Bool do_monster=FALSE;
  if(tick++&1==0) do_monster=TRUE;
  CDoomThinker *head=&l->thinkers,*cur,*next;
  for(cur=head->next;head!=cur;cur=next) {
    next=cur->next; //thinker may be deleted
    if(!do_monster&&!StrCmp(cur->cls_name,"CMonsterThinker"))
     goto skip;
    (*cur->fun_ptr)(l,cur);
skip:
  }
}
CDoomThinker *AddThinker(CDoomLevel *l,U8 (*fun_ptr)(CDoomLevel *,CDoomThinker *),U8 *cls_name) {
  CHashClass *cls=HashFind(cls_name,Fs->hash_table,HTT_CLASS);
  if(!cls) throw('Class');
  CDoomThinker *t=CAlloc(cls->size,doom_task);
  StrCpy(t->cls_name,cls_name);
  QueIns(t,l->thinkers.next);
  t->fun_ptr=fun_ptr;
  return t;
}
U0 DestroyThinkers(CDoomLevel *l) {
  QueDel(&l->thinkers);
  QueInit(&l->thinkers);
}
#endif