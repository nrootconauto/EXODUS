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
  CDoomThinker *head=&l->thinkers,*cur,*next;
  for(cur=head->next;head!=cur;cur=next) {
    next=cur->next; //thinker may be deleted
    (*cur->fun_ptr)(l,cur);
  }
}
CDoomThinker *AddThinker(CDoomLevel *l,U8 (*fun_ptr)(CDoomLevel *,CDoomThinker *),U8 *cls_name) {
  CHashClass *cls=HashFind(cls_name,Fs->hash_table,HTT_CLASS);
  if(!cls) throw('Class');
  CDoomThinker *t=CAlloc(cls->size);
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