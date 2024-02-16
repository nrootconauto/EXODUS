#ifndef GOD_HC
#define GOD_HC

#define GWORD_EXPIRE 4
#define GTEXT_LINES 4
#define GLINE_LEN 30
#define GWORD_Y 0
#define GWORD_W FONT_WIDTH*30+6
#define GWORD_H FONT_HEIGHT*4+6

#include "Vector";

class GWord {
  CD3 pos;
  U8* str;
  F64 ttl;
};

class GLine {
  I64 len;
  U8 c[GLINE_LEN];
};

class GText {
  I64 godWallet;
  I64 activeL; // init to 0
  GLine *ol[GTEXT_LINES]; // ordered line ptr
  GLine l[GTEXT_LINES]; // lines on the stack
  U8 walletStr[32]; // unrealistically high numbers will overflow this
};

U0 InitGText(GText* t) {
  I64 i;
  t->godWallet = 0;
  t->activeL = 0;
  StrCpy(t->walletStr, "God Words: 0");
  //t->al = t->l[0];
  for (i=0; i<GTEXT_LINES; i++) {
    t->l[i].len = 0;
    t->ol[i] = &t->l[i];
  }
}

Bool CheckGText(GText *t) {
  if (t->ol[t->activeL]->len >= GLINE_LEN) {
    t->activeL++;
    if (t->activeL >= GTEXT_LINES) {
      GLine* l0 = t->ol[0];
      t->ol[0] = t->ol[1];
      t->ol[1] = t->ol[2];
      t->ol[2] = t->ol[3];
      t->ol[3] = l0;
      l0->len = 0;
      t->activeL = 3;
    }
    return TRUE;
  }
  return FALSE;
}

U0 AddGText(GText *t, U8* c) {
  I64 i=0;
  // Add Wallet
  t->godWallet++;
  StrPrint(t->walletStr, "Wallet: %d", t->godWallet);

  // Add Log
  GLine *l = t->ol[t->activeL];
  while (c[i] != '\0') {
    l->c[l->len++] = c[i];
    if (CheckGText(t))
      l = t->ol[t->activeL];
    i++;
  }
  l->c[l->len++] = ' ';
  CheckGText(t);
}

I64 GameGodBits(I64 num_bits) {
  U8 b;
  I64 res=0;
  while (num_bits) {
    if (FifoU8Rem(god.fifo,&b)) {
      res=res<<1+b;
      num_bits--;
    } else
      GodBitsIns(GOD_GOOD_BITS,RandI64>>GOD_BAD_BITS);
  }
  return res;
}

public U8* GameGodWord() {
  return god.words[GameGodBits(17)%god.num_words];
}

public U0 ProcessGodWords(Vector* vec, F64 delta) {
  I64 i;
  GWord *gwords = vec->d;
  for (i=0; i<vec->len; i++) {
    gwords[i].ttl += delta;
    if (gwords[i].ttl >= GWORD_EXPIRE)
      VectorDel(vec, i--);
  }
}

public U0 AddGodWord(Vector *vec, CD3 *pos, GText *t) {
  GWord gword;
  gword.pos.x = pos->x;
  gword.pos.y = pos->y;
  gword.pos.z = pos->z;
  gword.str = GameGodWord;
  gword.ttl = 0.0;
  VectorAdd(vec, &gword);
  AddGText(t, gword.str);
}

#endif