U0 Lint(U8 *file) {
  U8 *ftxt=FileRead(file);
  I64 tok;
  CCmpCtrl*cc=CmpCtrlNew(ftxt,,file);
  while(tok=Lex(cc)) {
    if(tok=='=') {
      Lex(cc);
      if('='==Lex(cc))
        LexPutPos(cc);
    }
  }
  Free(ftxt);
}
Lint("MainDrawer.HC");
