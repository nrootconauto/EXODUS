#define WHF_EDIT (1<<0)
#define WHF_CHANGES (1<<1)
#define WHF_SALT (1<<2)
#define WHF_DELETE (1<<3)
U0 WikiHeader(CDyadStream *s,I64 *len_ptr,U8 *points_to,I64 flags=TRUE) {
  U8 *user_str;
  WriteLn(s,len_ptr,"<!DOCTYPE html>");
  WriteLn(s,len_ptr,"<HTML>");
  WriteLn(s,len_ptr,"<HEAD>");
  WriteLn(s,len_ptr,"<LINK REL=\"stylesheet\" HREF=\"/paper.css\">");
  WriteLn(s,len_ptr,"<LINK REL=\"stylesheet\" HREF=\"/syntax.css\">");
  WriteLn(s,len_ptr,"<TITLE>%s</TITLE>",points_to);
  WriteLn(s,len_ptr,"</HEAD>");
  WriteLn(s,len_ptr,"<BODY>");
  WriteLn(s,len_ptr,"<NAV CLASS=\"fixed border split-nav\">");
  WriteLn(s,len_ptr,"<DIV class=\"nav-brand\"><H3><A HREF=\"/WikiHome\">" WIKI_NAME "</A></H3></DIV>");
  WriteLn(s,len_ptr,"<DIV CLASS=\"collapsible\">");
  WriteLn(s,len_ptr,"<INPUT id=\"collapsible1\" type=\"checkbox\" name=\"collapsible1\">");
  WriteLn(s,len_ptr,"<LABEL for=\"collapsible1\">");
  WriteLn(s,len_ptr,"<DIV class=\"bar1\"></div>");
  WriteLn(s,len_ptr,"<DIV class=\"bar2\"></div>");
  WriteLn(s,len_ptr,"<DIV class=\"bar3\"></div>");
  WriteLn(s,len_ptr,"</LABEL>");
  WriteLn(s,len_ptr,"<DIV CLASS=\"collapsible-body\">");
  WriteLn(s,len_ptr,"<UL CLASS=\"inline\">");
  WriteLn(s,len_ptr,"<LI><A HREF=\""WIKI_INDEX"\">INDEX</A></LI>");
  if(flags&WHF_EDIT){
    if(GetCurrentUser)
      WriteLn(s,len_ptr,"<LI><A HREF=\""WIKI_EDIT"?PAGENAME=%s\">EDIT</A></LI>",points_to);
  }
  if(flags&WHF_SALT)
    if(CurrentUserIsAdmin) {
      if(!FileIsSalted(points_to))
        WriteLn(s,len_ptr,"<LI><A HREF=\""WIKI_SALT"?PAGENAME=%s\">SALT PAGE</A></LI>",points_to);
      else
        WriteLn(s,len_ptr,"<LI><A HREF=\""WIKI_UNSALT"?PAGENAME=%s\">UNSALT PAGE</A></LI>",points_to);
    }
  if(flags&WHF_CHANGES)
    WriteLn(s,len_ptr,"<LI><A HREF=\""WIKI_CHANGES"?FILE=%s\">CHANGE-LOG</A></LI>",points_to);
  if(flags&WHF_DELETE)
    if(CurrentUserIsAdmin)
      WriteLn(s,len_ptr,"<LI><A HREF=\""WIKI_DELETE"%s\">DELETE PAGE</A></LI>",points_to);
  WriteLn(s,len_ptr,"<LI><A HREF=\""WIKI_SEARCH"\">SEARCH</A></LI>",points_to);
  user_str=GetCurrentUserName;
  if(user_str) {
    WriteLn(s,len_ptr,"<LI><A HREF=\""WIKI_ACCOUNT"\">ACCOUNT(%s)</A></LI>",user_str);
  } else
    WriteLn(s,len_ptr,"<LI><A HREF=\""WIKI_LOGIN"\">LOGIN</A></LI>");
  WriteLn(s,len_ptr,"</UL></DIV></DIV>");
  WriteLn(s,len_ptr,"</NAV>");
  WriteLn(s,len_ptr,"<DIV CLASS=\"sm-12 md-12 col\"><DIV CLASS=\"paper\">");
}
U0 WikiFooter(CDyadStream *s,I64 *len_ptr,CURL *url) {
	WriteLn(s,len_ptr,"</DIV></DIV></BODY></HTML>");
}
