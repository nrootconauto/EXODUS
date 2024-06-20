#ifndef MOD_H
#define MOD_H "Be Good"
#define TK_WORD 0x100
#define TK_STR 0x101
#define TK_I64 0x102
U8 *GetWord(U8 **_text) {
  U8 *text=*_text,*o=text,*ret;
  I64 len=0;
  while(Bt(char_bmp_alpha,text[len])) {
   len++;
  }
  if(len) {
    ret=MAlloc(len+1);
    MemCpy(ret,o,len);
    ret[len]=0;
  } else
    ret=NULL;
  *_text=text;
  return ret;
}
class CBEXState {
  I64 cur_thing;
  I64 tok;
  U8 *str,*src_ptr;
  I64 ln,st;
  U8 cur_section[STR_LEN];
};
I64 Lex(CBEXState *st) {
enter:;
  U8 *word;
  if(word=GetWord(&st->src_ptr)) {
    Free(st->str);
    st->str=word;
    return Tst->tok=TK_WORD;
  }
  if(Bt(char_bmp_white_space,*st->src_ptr)) {
    if(*st->src_ptr++=='\n')
      st->ln++;
    goto enter;
  }
  switch(*st->st_ptr) {
    case '#':
      while(*st->st_ptr) {
        if(*st->st_ptr++=='\n') {
	  st->ln++;
	  goto enter;
        }
      }
      return 0;
    case '0'...'9':
      st->i64=Str2I64(st->st_ptr,,&st->st_ptr);
      return st->tok=TK_I64;
  }
  return st->tok=*st->st_ptr++;
}
U0 ParseDeh(U8 *text) {
  CBEXState st;
  MemSet(&st,0,sizeof CBEXState);
  st.src_ptr=text;
  while(Lex(&st)) {
    if(!StrICmp(st.cur_section,"")) { //Empty(Things?)
      switch(st.tok) {
      }
    }
  }
}
#enedif