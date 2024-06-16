U8 *LstSub(I64 sub, U8 *lst)
{//Point to lst entry.
//Not efficient.  Use an array of U8 ptrs for efficiency.
  if (!lst) return NULL;
  while (*lst && sub>0) {
    while (*lst)	//Advance to end of cur entry.
      lst++;
    lst++;		//Skip trailing zero.
    if (*lst=='@')	//Check for '@' alias lst entry.
      lst++;
    else
      sub--;
  }
  if (sub||!*lst)
    return NULL;
  else
    return lst;
}

I64 LstMatch(U8 *needle, U8 *haystack_lst,I64 flags=0)
{//-2 if Ambiguous
// -1 if not found
  // Not efficient. Use hash tables for efficiency.
  I64 n,sub=0,res=-1;
  U8 *ptr;
  Bool exact_match=FALSE;
  if (!haystack_lst) return -1;
  n=StrLen(needle);
  while (*haystack_lst) {
    if (*haystack_lst=='@') {	//Check for '@' alias haystack_lst entry
      sub--;
      haystack_lst++;
    }
    ptr=needle;
    if (flags & LMF_IGNORE_CASE)
      while (*ptr && ToUpper(*ptr)==ToUpper(*haystack_lst)) {
	ptr++;
	haystack_lst++;
      }
    else
      while (*ptr && *ptr==*haystack_lst) {
	ptr++;
	haystack_lst++;
      }
    if (!*ptr) {		//Did we reach end of needle?
      if (!*haystack_lst)	//Did we reach end of haystack_lst?
	return sub;		//Found Exact match
      else {
	if (res!=-1) {
	  if (!exact_match)
	    res=-2;		//Ambiguous unless later exact match.
	} else {
	  if (!(flags & LMF_EXACT))
	    res=sub;
	}
      }
    }
    while (*haystack_lst)	//Advance to end of cur entry.
      haystack_lst++;
    haystack_lst++;		//Skip trailing zero
    sub++;
  }
  return res;
}

I64 StrOcc(U8 *src, I64 ch)
{//Count occurrences of a char.
  I64 i=0;
  if (!src) return 0;
  while (*src)
    if (*src++==ch)
      i++;
  return i;
}

I64 Spaces2Tabs(U8 *dst,U8 *src)
{//Src buf with spaces to dst buf without.
  U8 *src2;
  I64 chged=0,space_cnt,space_cnt2,col=0;
  if (*src)
    while (TRUE) {
      src2=src;
      while (*src2==CH_SPACE)
	src2++;
      space_cnt=src2-src;
      while (col+space_cnt>=8) {
	space_cnt2=8-col;
	if (space_cnt2==1)
	  *dst++=CH_SPACE;
	else {
	  *dst++='\t';
	  chged+=space_cnt2-1;
	}
	space_cnt-=space_cnt2;
	col=0;
      }
      if (*src2=='\t') {
	if (space_cnt==1 && col==7)
	  *dst++=CH_SPACE;
	else
	  chged+=space_cnt;
	*dst++='\t';
	col=0;
      } else {
	while (space_cnt--) {
	  *dst++=CH_SPACE;
	  if (++col==8)
	    col=0;
	}
	if (*src2) {
	  *dst++=*src2;
	  if (++col==8)
	    col=0;
	} else
	  break;
      }
      src=++src2;
    }
  *dst=0;
  return chged;
}

U8 *StrUtil(U8 *_src,I64 flags)
{//Modifies in place. See $LK,"flags",A="MN:SUF_REM_SPACES"$ for all the options.
  U8 *src=_src,*dst=_src;
  I64 ch;

  if (flags & SUF_REM_LEADING)
    while (Bt(char_bmp_white_space,*src))
      src++;
  while (ch=*src++)
    if (Bt(char_bmp_white_space,ch)) {
      if (!(flags & SUF_REM_SPACES)) {
	if (flags & SUF_SINGLE_SPACE) {
	  *dst++ = CH_SPACE;
	  while ((ch=*src++) && Bt(char_bmp_white_space,ch));
	  src--;
	} else
	  *dst++ = ch;
      }
    } else if (!(flags & SUF_REM_CTRL_CHARS) || ch>=CH_SHIFT_SPACE)
      *dst++=ch;
  *dst=0;

  if (flags & SUF_REM_TRAILING)
    while (dst!=_src && (!*dst || Bt(char_bmp_white_space,*dst)))
      *dst-- =0;
  if (flags & SUF_TO_UPPER)
    for (dst=_src;*dst;dst++) {
      ch=*dst;
      if ('a'<=ch<='z')
	*dst=ch-0x20;
    }
  if (flags & SUF_TO_LOWER)
    for (dst=_src;*dst;dst++) {
      ch=*dst;
      if ('A'<=ch<='Z')
	*dst=ch+0x20;
    }
  if (flags & SUF_SAFE_DOLLAR)
    for (dst=_src;*dst;dst++) {
      ch=*dst;
      if (!Bt(char_bmp_safe_dollar,*dst))
	*dst='.';
    }
  if (flags & SUF_S2T)
    Spaces2Tabs(_src,_src);
  return _src;
}

U8 *StrFirstOcc(U8 *src,U8 *marker)
{//Point to 1st occurrence of marker set in str.
  I64 ch;
  while ((ch=*src++) && !StrOcc(marker,ch));
  if (ch)
    return src-1;
  else
    return NULL;
}

U8 *StrFirstRem(U8 *src,U8 *marker,U8 *dst=NULL)
{//Remove first str segment and place in dst buf or NULL.
  I64 ch;
  U8 *ptr=src,*res=dst;
  if (dst) {
    while ((ch=*ptr++) && !StrOcc(marker,ch))
      *dst++=ch;
    *dst=0;
  } else
    while ((ch=*ptr++) && !StrOcc(marker,ch));
  if (ch)
    StrCpy(src,ptr);
  else
    *src=0;
  return res;
}

U8 *StrLastOcc(U8 *src,U8 *marker)
{//Point to last occurrence of market set in str.
  I64 ch;
  U8 *res=NULL;
  while (ch=*src++)
    if (StrOcc(marker,ch))
      res=src-1;
  return res;
}

U8 *StrLastRem(U8 *src,U8 *marker,U8 *dst=NULL)
{//Remove last str segment and place in dst buf or NULL.
  U8 *ptr;
  if (ptr=StrLastOcc(src,marker)) {
    if (dst)
      StrCpy(dst,ptr+1);
    *ptr=0;
  } else {
    if (dst)
      StrCpy(dst,src);
    *src=0;
  }
  return dst;
}

U8 *StrFind(U8 *needle,U8 *haystack_str,I64 flags=0)
{//Find needle_str in haystack_str with options.
  Bool cont;
  U8 *saved_haystack_str=haystack_str;
  I64 plen=StrLen(needle);
  do {
    cont=FALSE;
    if (flags & SFF_IGNORE_CASE)
      haystack_str=StrIMatch(needle,haystack_str);
    else
      haystack_str=StrMatch(needle,haystack_str);
    if (haystack_str && flags & SFF_WHOLE_LABELS_BEFORE &&
	  haystack_str!=saved_haystack_str &&
	  Bt(char_bmp_alpha_numeric,*(haystack_str-1))) {
      haystack_str++;
      if (*haystack_str)
	cont=TRUE;
      else
	haystack_str=NULL;
    }
    if (haystack_str && flags & SFF_WHOLE_LABELS_AFTER &&
	  Bt(char_bmp_alpha_numeric,*(haystack_str+plen))) {
      haystack_str++;
      if (*haystack_str)
	cont=TRUE;
      else
	haystack_str=NULL;
    }
  } while (cont);
  return haystack_str;
}

Bool WildMatch(U8 *test_str,U8 *wild_str)
{//Wildcard match with '*' and '?'.
  I64 ch1,ch2;
  U8 *fall_back_src=NULL,*fall_back_wild=NULL;
  while (TRUE) {
    if (!(ch1=*test_str++)) {
      if (*wild_str && *wild_str!='*')
	return FALSE;
      else
	return TRUE;
    } else {
      if (!(ch2=*wild_str++))
	return FALSE;
      else {
	if (ch2=='*') {
	  fall_back_wild=wild_str-1;
	  fall_back_src=test_str;
	  if (!(ch2=*wild_str++))
	    return TRUE;
	  while (ch2!=ch1)
	    if (!(ch1=*test_str++))
	      return FALSE;
	} else
	  if (ch2!='?' && ch1!=ch2) {
	    if (fall_back_wild) {
	      wild_str=fall_back_wild;
	      test_str=fall_back_src;
	      fall_back_wild=NULL;
	      fall_back_src=NULL;
	    } else
	      return FALSE;
	  }
      }
    }
  }
}

U8 *Tabs2Spaces(U8 *src)
{//MAlloc str with tabs to spaces.
  I64 ch,i,j,l=StrLen(src)<<1+2,col=0;
  U8 *dst=MAlloc(l),*tmp;
  while (ch=*src++) {
    if (ch=='\t') {
      j=(col+8) & ~7;
      for (i=col;i<j;i++) {
	dst[i]=CH_SPACE;
	if (i>=l-2) {
	  tmp=MAlloc(l<<1);
	  MemCpy(tmp,dst,i+1);
	  Free(dst);
	  l<<=1;
	  dst=tmp;
	}
      }
      col=j;
    } else {
      dst[col]=ch;
      if (col>=l-2) {
	tmp=MAlloc(l<<1);
	MemCpy(tmp,dst,col+1);
	Free(dst);
	l<<=1;
	dst=tmp;
      }
      col++;
    }
  }
  dst[col]=0;
  return dst;
}

U8 *ScaleIndent(U8 *src,F64 indent_scale_factor)
{//MAlloced str.  8*0.25-->2 or 8*2.0-->16
  I64 ch,i,col=0;
  U8 *dst,*dst2;
  while (ch=*src++) {
    if (ch=='\t')
      col=(col+8) & -0x8;
    else if (ch==CH_SPACE)
      col++;
    else
      break;
  }
  src--;
  col=Round(indent_scale_factor*col);
  dst=dst2=MAlloc(StrLen(src)+col/8+col&7+1);
  for (i=col/8;i>0;i--)
    *dst2++='\t';
  for (i=col&7;i>0;i--)
    *dst2++=CH_SPACE;
  StrCpy(dst2,src);
  return dst;
}

U8 *MStrUtil(U8 *src,I64 flags,F64 indent_scale_factor=0)
{//MAlloc $LK,"StrUtil",A="MN:StrUtil"$().
  U8 *dst=StrNew(src),*dst2,*tmp;
  StrUtil(dst,flags);
  if (flags & SUF_T2S) {
    tmp=Tabs2Spaces(dst);
    Free(dst);
    dst=tmp;
  }
  if (flags & SUF_SCALE_INDENT)
    dst2=ScaleIndent(dst,indent_scale_factor);
  else
    dst2=StrNew(dst); //Shorten to just right size.
  Free(dst);
  return dst2;
}
Bool YorN()
{//Wait for user to answer Y or N.
  I64 ch;
  "(y or n)? ";
  while (TRUE) {
    ch=ToUpper(GetChar(,FALSE));
    if (ch=='Y') {
      "$$PT$$YES$$FG$$\n";
      return TRUE;
    } else if (ch=='N') {
      "$$PT$$NO$$FG$$\n";
      return FALSE;
    }
  }
}

I64 PressAKey()
{//Print "Press a key" and wait for non-zero $LK,"ASCII",A="MN:CH_CTRLA"$ key.
  "PRESS ENTER\n";
  I64 ch;
  U8 *s=GetStr;
  ch=*s;
  Free(s);
  return ch;
}

Bool AreYouSure()
{//Print "Are you sure" and waits for Y or N.
  "ARE YOU SURE ";
  return YorN;
}
//TODO TODO TODO

U0 Help()
{//Dbg help or master help index file.
  if (HashFind("DFs",Fs->hash_table,HTT_GLBL_VAR))
    DbgHelp;
  else
    PopUp("Type(\"::/Doc/HelpIndex.DD\");DocTop;View;");
}

U0 ScanFlags(U8 *_dst_flags,U8 *lst,U8 *src)
{/*More than 64 flags. Flags passed by ref.

Examples:
$LK,"ScanFlags",A="FF:::/Adam/Opt/Utils/Diff.HC,ScanFlags:2"$(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);

I64 flags=0;
ScanFlags(&flags,"R\0L\0Dump\0Scan\0","+Dump-R"); //Sets Bit#2, Clears Bit#0.
*/
  I64 i;
  U8 *buf,*ptr;
  if (src) {
    buf=MAlloc(StrLen(src)+1);
    while (*src) {
      while (*src && *src!='+' && *src!='-')
	src++;
      if (*src=='+') {
	src++;
	if (*src) {
	  ptr=buf;
	  while (*src && *src!='+' && *src!='-' &&
		*src!=CH_SPACE && *src!=CH_SHIFT_SPACE)
	    *ptr++=*src++;
	  *ptr=0;
	  i=LstMatch(buf,lst);
	  if (i>=0)
	    LBts(_dst_flags,i);
	  else {
	    Free(buf);
	    throw('ScanFlag');
	  }
	}
      } else if (*src=='-') {
	src++;
	if (*src) {
	  ptr=buf;
	  while (*src && *src!='+' && *src!='-' &&
		*src!=CH_SPACE && *src!=CH_SHIFT_SPACE)
	    *ptr++=*src++;
	  *ptr=0;
	  i=LstMatch(buf,lst);
	  if (i>=0)
	    LBtr(_dst_flags,i);
	  else {
	    Free(buf);
	    throw('ScanFlag');
	  }
	}
      }
    }
    Free(buf);
  }
}

U8 *StrPrintFlags(U8 *dst,U8 *lst,I64 flags)
{//Only 64 flags. Flags passed by value.
  I64 i;
  *dst=0;
  while (flags) {
    i=Bsf(flags);
    Btr(&flags,i);
    CatPrint(dst,"+%z",i,lst);
  }
  return dst;
}

I64 Str2I64(U8 *st,I64 radix=10,U8 **_end_ptr=NULL)
{//String to I64. Similar to strtoul().
//Allows radix change with "0x20" "0b1010" "0d123" "0o18".
  //Be careful of Str2I64("0b101",16)-->0xB101.
  Bool neg=FALSE;
  I64 ch,res=0;
  if (!st || !(2<=radix<=36)) {
    if (_end_ptr) *_end_ptr=st;
    return 0;
  }
  while (Bt(char_bmp_white_space,*st))
    st++;
  while (TRUE)
    switch (*st) {
      case '-':
	st++;
	neg=!neg;
	break;
      case '+':
	st++;
	break;
      case '0':
	st++;
	ch=ToUpper(*st);
	if (ch>='B' && (radix<=10 || ch>'A'+radix-11))
	  switch (ch) {
	    case 'B': radix=2;	st++; break;
	    case 'D': radix=10; st++; break;
	    case 'X': radix=16; st++; break;
	  }
      default:
	goto ai_cont;
    }
ai_cont:
  while (ch=ToUpper(*st++)) {
    if (radix>10) {
      if ('0'<=ch<='9')
	res=res*radix+ch-'0';
      else if ('A'<=ch<='A'+radix-11)
	res=res*radix+ch-'A'+10;
      else
	break;
    } else if ('0'<=ch<='0'+radix-1)
      res=res*radix+ch-'0';
    else
      break;
  }
  if (_end_ptr) *_end_ptr=st-1;
  if (neg)
    return -res;
  else
    return res;
}

F64 Str2F64(U8 *src,U8 **_end_ptr=NULL)
{/*String to F64.
Does not allow more than 18-digits
before or after the decimal point
because the numbers before and after
the decimal point are stored
in 64-bits.  Use exponentiated forms
to avoid this.
*/
  I64 i,j,k,ch;
  F64 d;
  Bool neg=FALSE,neg_e=FALSE;

  ch=*src++;
  while (Bt(char_bmp_white_space,ch))
    ch=*src++;
  if (ch=='-') {
    neg=TRUE;
    ch=*src++;
  }
  if (!StrNCmp(src-1,"inf",3)) {
    d=inf;
    src+=3;
    goto a2f_end;
  }
  i=0;
  while (TRUE) {
    if (Bt(char_bmp_dec_numeric,ch))
      i=i*10+ch-'0';
    else {
      if (ch=='.' || ch=='e' || ch=='E')
	break;
      d=i;
      goto a2f_end;
    }
    ch=*src++;
  }
  if (ch=='.')
    ch=*src++;
  k=0;
  while (TRUE) {
    if (Bt(char_bmp_dec_numeric,ch)) {
      i=i*10+ch-'0';
      k++;
    } else {
      if (ch=='e' || ch=='E')
	break;
      d=i*Pow10I64(-k);
      goto a2f_end;
    }
    ch=*src++;
  }
  ch=*src++;
  if (ch=='-') {
    neg_e=TRUE;
    ch=*src++;
  }
  j=0;
  while (TRUE) {
    if (Bt(char_bmp_dec_numeric,ch))
      j=j*10+ch-'0';
    else {
      if (neg_e)
	d=i*Pow10I64(-j-k);
      else
	d=i*Pow10I64(j-k);
      goto a2f_end;
    }
    ch=*src++;
  }
a2f_end:
  if (_end_ptr) *_end_ptr=src-1;
  if (neg)
    return -d;
  else
    return d;
}
U8 *StrScan(U8 *src,U8 *fmt,...)
{/*Opposite of sprintf().  Pass ptrs to data to be scanned-in.
For "%s", pass ptr to ptr (be careful because addr
of array is the same as array--create ptr to array
and take addr.
*/
  U8 *buf,*ptr,**pptr;
  Bool left_justify=FALSE;
  I64 ch,cur_arg=0,i,len,*i_ptr,dec_len;
  F64 *d_ptr;
  if (!fmt)
    throw('Scan');
  while (ch = *fmt++) {
    if (ch=='%') {
      if (*fmt=='%') {
	src++;
	fmt++;
      } else {
	if (*fmt=='-') {
	  left_justify=TRUE;
	  fmt++;
	} else
	  left_justify=FALSE;
	len=0;
	while ('0'<=*fmt<='9')
	  len=len*10+ (*fmt++ -'0');
	if (*fmt=='*') {
	  fmt++;
	  if (cur_arg>=argc)
	    throw('Scan');
	  len=argv[cur_arg++];
	}
	ch=*fmt++;
	if (ch && !len) {
	  ptr=src;
	  while (*ptr && *ptr!=*fmt)
	    ptr++;
	  len=ptr-src;
	} else {
	  if (ch=='.') {
	    dec_len=0;
	    while ('0'<=*fmt<='9')
	      dec_len=dec_len*10+ (*fmt++-'0');
	    if (*fmt=='*') {
	      fmt++;
	      if (cur_arg>=argc)
		throw('Scan');
	      dec_len=argv[cur_arg++];
	    }
	    ch=*fmt++;
	  }
	}
	buf=MAlloc(len+1);
	for (i=0;i<len;i++)
	  buf[i]=*src++;
	buf[i]=0;
	switch (ch) {
	  case 's':
	    if (cur_arg>=argc)
	      throw('Scan');
	    pptr=argv[cur_arg++];
	    StrCpy(*pptr,buf);
	    break;
	  case 'c':
	    if (cur_arg>=argc)
	      throw('Scan');
	    ptr=argv[cur_arg++];
	    *ptr=*buf;
	    break;
	  case 'C':
	    if (cur_arg>=argc)
	      throw('Scan');
	    ptr=argv[cur_arg++];
	    *ptr=ToUpper(*buf);
	    break;
	  case 'z':
	    if (cur_arg+1>=argc)
	      throw('Scan');
	    i_ptr=argv[cur_arg++];
	    *i_ptr=LstMatch(buf,argv[cur_arg++]);
	    break;
	  case 'Z':
	    if (cur_arg+1>=argc)
	      throw('Scan');
	    i_ptr=argv[cur_arg++];
	    *i_ptr=DefineMatch(buf,argv[cur_arg++]);
	    break;
	  case 'd':
	    if (cur_arg>=argc)
	      throw('Scan');
	    i_ptr=argv[cur_arg++];
	    *i_ptr=Str2I64(buf);
	    break;
	  case 'x':
	  case 'X':
	    if (cur_arg>=argc)
	      throw('Scan');
	    i_ptr=argv[cur_arg++];
	    *i_ptr=Str2I64(buf,16);
	    break;
	  case 'b':
	    if (cur_arg>=argc)
	      throw('Scan');
	    i_ptr=argv[cur_arg++];
	    *i_ptr=Str2I64(buf,2);
	    break;
	  case 'e':
	  case 'f':
	  case 'g':
	  case 'n':
	    if (cur_arg>=argc)
	      throw('Scan');
	    d_ptr=argv[cur_arg++];
	    *d_ptr=Str2F64(buf);
	    break;
	  case 'D':
	    if (cur_arg>=argc)
	      throw('Scan');
	    i_ptr=argv[cur_arg++];
		*i_ptr=Str2Date(buf);
	    break;
	}
	Free(buf);
      }
    } else
      src++;
  }
  return src;
}
U0 GetOutOfDollar()
{//If a $$ has been printed, print another $$ to exit mode.
  CDoc *doc;
  if (IsRaw&&text.raw_flags&RWF_IN_DOLLAR)
      '$$';
  if (fp_doc_put && (doc=(*fp_doc_put)(Fs)) && doc->flags&DOCF_IN_DOLLAR)
    '$$';
}
CDate Now() {
  return Unix2CDate(UnixNow);
}
CDate Str2Date(U8 *_src)
{/*"*+nnnn", "*-nnnn", "mm/dd", "mm/dd/yy"
It also supports some funs
SM() start of mon
EM() end of mon
SY() start of year
EY() end of year
Full expressions are not implimented
but you can do stuff like SM(*-7)+3
and it will return the 3rd day after
the start of mon for seven days before
today.
*/
  CDate res=0;
  CDateStruct ds,ds_now;
  U8 *src=MStrUtil(_src,SUF_REM_SPACES|SUF_TO_UPPER),
	*v=StrNew(src),
	*ptr=src;
  Bool start_mon=FALSE,end_mon=FALSE,
	start_year=FALSE,end_year=FALSE;

  MemSet(&ds,0,sizeof(CDateStruct));
  if (!StrNCmp(ptr,"SM(",3)) {
    ptr+=3;
    start_mon=TRUE;
  } else if (!StrNCmp(ptr,"EM(",3)) {
    ptr+=3;
    end_mon=TRUE;
  } else if (!StrNCmp(ptr,"SY(",3)) {
    ptr+=3;
    start_year=TRUE;
  } else if (!StrNCmp(ptr,"EY(",3)) {
    ptr+=3;
    end_year=TRUE;
  }
  if (*ptr=='*') {
    ptr++;
    if (*ptr=='+' || *ptr=='-')
      res.date=Str2I64(ptr,,&ptr);
    res+=Now;
  } else {
    StrFirstRem(ptr,"/",v); //Put mon into v
    ds.mon=Str2I64(v);
    if (StrOcc(ptr,'/')) {
      StrFirstRem(ptr,"/",v); //Put day into v leaving year in ptr
      ds.day_of_mon=Str2I64(v);
      ds.year=Str2I64(ptr,,&ptr);
      if (ds.year<100) //if not 4 digit year
	ds.year+=2000;
    } else {
      ds.day_of_mon=Str2I64(ptr,,&ptr);
      Date2Struct(&ds_now,Now);
      ds.year=ds_now.year;
    }
    res=Struct2Date(&ds);
  }
  if (*ptr==')') ptr++;

  if (start_mon)
    res.date=FirstDayOfMon(res.date);
  else if (end_mon)
    res.date=LastDayOfMon(res.date);
  else if (start_year)
    res.date=FirstDayOfYear(res.date);
  else if (end_year)
    res.date=LastDayOfYear(res.date);

  if (*ptr=='+' || *ptr=='-')
    res.date+=Str2I64(ptr);
  Free(src);
  Free(v);
  return res;
}
