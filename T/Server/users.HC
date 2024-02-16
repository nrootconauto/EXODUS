CHeapCtrl *user_heap=Fs->data_heap;
#define UF_ADMIN 1
#define UF_BANNED 2
#define UF_ALLOWED 4
#define USER_REG_FMT "InitUser(\"%s\",\"%s\",%d);" //name,password_hash,flags


U8 *root_dft=MStrPrint(USER_REG_FMT,"root",FNV64Str("root"),UF_ADMIN|UF_ALLOWED);
RegDft("Server/users",root_dft);
class CSrvUser:CQue {
  U8 name[STR_LEN];
  I64 flags;
  U8 pass_hash[17];
  U8 session_cookie[17];
};

I64 user_mtx=0;
I64 user_mtx_lock_cnt=0;
CTask *user_mtx_task=NULL;
CQue *users=MAlloc(sizeof CQue);
QueInit(users);


U0 LockUsers() {
  static I64 lock_cnt=0;
  while(LBts(&user_mtx,0)) {
    if(user_mtx_task==Fs)
      break;
    ServerYield;  
  }
  user_mtx_lock_cnt++;
  user_mtx_task=Fs;
}
U0 UnlockUsers() {
  if(--user_mtx_lock_cnt==0) {
    user_mtx_lock_cnt=0;
    user_mtx_task=NULL;
    LBtr(&user_mtx,0); 
  }
}
U0 ReleaseUsers() {
  if(Bt(&user_mtx,0)) {
    if(user_mtx_task==Fs) {
      user_mtx_lock_cnt=0;
      user_mtx_task=NULL;
      LBtr(&user_mtx,0); 
    }
  }
}
//
//Here's the,we spawn this on Core 0(as TempleOS likes
// registry accesses on Core 0)
//
U0 UpdateUserRegistry(I64) {
  LockUsers;
  CSrvUser*u;
  RegWrite("Server/users","");
  for(u=users->next;u!=users;u=u->next) {
    if(StrLen(u->session_cookie))
      RegAppend("Server/users","InitUser(\"%q\",\"%s\",%d,\"%s\");;",u->name,u->pass_hash,u->flags,u->session_cookie);
    else
      RegAppend("Server/users","InitUser(\"%q\",\"%s\",%d);;",u->name,u->pass_hash,u->flags);
  }
  UnlockUsers;
}

CSrvUser *InitUser(U8 *name,U8 *pass_hash,I64 flags=0,U8 *session_token=NULL) {
  CSrvUser *user=CAlloc(sizeof(CSrvUser),user_heap);
  StrCpy(user->name,name);
  StrCpy(user->pass_hash,pass_hash);
  user->flags=flags;
  if(session_token)
    StrCpy(user->session_cookie,session_token);
  QueIns(user,users);
  return user;
}

RegExe("Server/users");


CSrvUser *AddUser(U8 *name,U8 *pwd_hash,I64 flags=0) {
  CSrvUser *user;
  LockUsers;
  user=InitUser(name,pwd_hash,flags);
  UnlockUsers;
//This new task with aquire the users lock 
  Spawn(&UpdateUserRegistry,,,0);
  return user;
}
U0 RemoveUser(U8 *name) {
  CSrvUser*u;
  LockUsers;
  for(u=users->next;u!=users;u=u->next) {
    if(!StrCmp(name,u->name)) {
      QueRem(u);
      Free(u);
    }
  }
  UnlockUsers;
//Task will be locked by UpdateUserRegistry
  Spawn(&UpdateUserRegistry,,,0);
}

U0 SignupPostGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,CHashTable *tab) {
  CHashGeneric *un=HashFind("username",tab,-1),*ps=HashFind("password",tab,-1),
        *ps2=HashFind("password2",tab,-1);
  CSrvUser*u;
  U8 *hash,*session_cookie;
  I64 idx;
  CConnection *con=Fs->user_data;
  if(!un||!ps||!ps2) {
fail0:
    con->response_code=200;
    StrCpy(con->response_mime,"text/html");
    FramePtrDel(WIKI_SESSION_COOKIE);
    WikiHeader(stream,NULL,"Sign-UpInternal Failure:",0);
    WriteLn(stream,,"<H2>Whoops!!!</H2>");
    WriteLn(stream,,"<P>Something went strange in the server.</P>");
    WikiFooter(stream,NULL,url); 
    return ;
  }
  for(idx=0;un->user_data1(U8*)[idx];idx++) {
    if(!Bt(char_bmp_alpha_numeric_no_at,un->user_data1(U8*)[idx])) {
      con->response_code=200;
      StrCpy(con->response_mime,"text/html");
      FramePtrDel(WIKI_SESSION_COOKIE);
      WikiHeader(stream,NULL,"Username must be alpha-numeric only:",0);
      WriteLn(stream,,"<H2>Only use alpha-numeric charactors in the username</H2>");
      WriteLn(stream,,"<P>Try again.</P>");
      WikiFooter(stream,NULL,url);
      return;
    }
  }
  if(StrLen(un->user_data1)>=STR_LEN) {
    WikiHeader(stream,NULL,"Username is too long!",0);
    WriteLn(stream,,"<H2>Username is too long</H2>");
    WriteLn(stream,,"<P>Try again.</P>");
    WikiFooter(stream,NULL,url);
    return;
  }
  if(StrCmp(ps->user_data1,ps2->user_data1)) {
    con->response_code=200;
    StrCpy(con->response_mime,"text/html");
    FramePtrDel(WIKI_SESSION_COOKIE);
    WikiHeader(stream,NULL,"Passwords don't Match:",0);
    WriteLn(stream,,"<H2>You passwords you entered dont match</H2>");
    WriteLn(stream,,"<P>Try again.</P>");
    WikiFooter(stream,NULL,url);
    return;
  }
  LockUsers;
  for(u=users->next;u!=users;u=u->next) {
    if(!StrCmp(u->name,un->user_data1)){
//User already exists
      con->response_code=200;
      StrCpy(con->response_mime,"text/html");
      WikiHeader(stream,NULL,"Sign-Up Failure:(User already exists)",0);
      WriteLn(stream,,"<H2>User \"%s\" Already Exists</H2>",u->name);
      WriteLn(stream,,"<P>Try a different user name.</P>");
      WikiFooter(stream,NULL,url); 
      UnlockUsers;
      goto fin;
    }
  }
  UnlockUsers;
  hash=FNV64Str(ps->user_data1);
  u=AddUser(un->user_data1,hash,0);
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  session_cookie=MStrPrint("%s.%D.%T",un->user_data1,Now,Now);
  hash=FNV64Str(session_cookie);
  StrCpy(u->session_cookie,hash);
//  FramePtrAdd(WIKI_SESSION_COOKIE,u->session_cookie);
  WikiHeader(stream,NULL,"Account Creation Successful!",0);
  WriteLn(stream,,"<H2>Epic,You Created an Account</H2>");
  WriteLn(stream,,"<P>You need to get allowed to enter by an Admin first</P>");
  WriteLn(stream,,"<P>(The admin(s) emails(s) are <B>%s</B>)</P>",WIKI_ADMIN_EMAILS);
  WikiFooter(stream,NULL,url);
  Free(hash);
fin:
}

U0 LoginPostGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,CHashTable *tab) {
  CHashGeneric *un=HashFind("username",tab,-1),*ps=HashFind("password",tab,-1);
  CConnection *con=Fs->user_data;
  LockUsers;
  CSrvUser*u;
  Bool logged_in=FALSE;
  if(!un||!ps) {
    goto fail;
  }
  U8 *hash=NULL,*session_cookie=NULL;
  for(u=users->next;u!=users;u=u->next) {
    if(!StrCmp(un->user_data1,u->name)) {
      hash=FNV64Str(ps->user_data1);
      if(!StrCmp(u->pass_hash,hash)) {
        con->response_code=200;
        StrCpy(con->response_mime,"text/html");
        if(u->flags&UF_BANNED) {
	  WikiHeader(stream,NULL,"You were banned!",0);
	  WriteLn(stream,,"<H2>You got banned!</H2>");
	  WikiFooter(stream,NULL,url);
	  UnlockUsers;
	  return;
        }
        if(!(u->flags&UF_ALLOWED)) {
	  WikiHeader(stream,NULL,"You need to be allowed in!",0);
	  WriteLn(stream,,"<H2>An Admin must let you in!!</H2>");
	  WriteLn(stream,,"<P>You need to get allowed to enter by an Admin first</P>");
	  WriteLn(stream,,"<P>(The admin(s) emails(s) are <B>%s</B>)</P>",WIKI_ADMIN_EMAILS);
	  WikiFooter(stream,NULL,url);
	  UnlockUsers;
	  return;
        }
        session_cookie=MStrPrint("%s.%D.%T",un->user_data1,Now,Now);
        hash=FNV64Str(session_cookie);
        FramePtrAdd(WIKI_SESSION_COOKIE,hash);
        StrCpy(u->session_cookie,hash);
        WikiHeader(stream,NULL,"Login Successful:",0);
        WriteLn(stream,,"<H2>Epic,You logged In.</H2>");
        WriteLn(stream,,"<P>Have fun!!!;)</P>");
        WikiFooter(stream,NULL,url);
        logged_in=TRUE;
        Free(session_cookie);
        goto en;
      } else{
        goto fail;
      }
    }
  }
fail:
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  FramePtrDel(WIKI_SESSION_COOKIE);
  WikiHeader(stream,NULL,"Login Failed:",0);
  WriteLn(stream,,"<H2>Whoops!!!</H2>");
  WriteLn(stream,,"<P>Maybe you have the wrong password?!?</P>");
  WikiFooter(stream,NULL,url); 
en:
  UnlockUsers;
//Update session cookie
  if(logged_in)
    Spawn(&UpdateUserRegistry,,,0);
} 
//Will logout if called with WIKI_SESSION_COOKIE in HTTP cookies
U0 LoginGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  FramePtrDel(WIKI_SESSION_COOKIE);
  WikiHeader(stream,NULL,"Login/Sign-Up:",0);
  WriteLn(stream,,"<H2>Login:</H2>");
  WriteLn(stream,,"<FORM CLASS=\"form-group\" ACTION=\"" WIKI_LOGIN2 "\" METHOD=\"POST\">");
    WriteLn(stream,,"<LABEL FOR=\"username\">Username</LABEL>");
    WriteLn(stream,,"<INPUT NAME=\"username\" TYPE=\"text\">");
    WriteLn(stream,,"<LABEL FOR=\"password\" >Password</LABEL>");
    WriteLn(stream,,"<INPUT NAME=\"password\" TYPE=\"password\">");
    WriteLn(stream,,"<INPUT TYPE=\"submit\" VALUE=\"Login\">");
  WriteLn(stream,,"</FORM>");
  WriteLn(stream,,"<H2>Sign-Up:</H2>");
  WriteLn(stream,,"<FORM CLASS=\"form-group\" ACTION=\"" WIKI_SIGNUP2 "\" METHOD=\"POST\">");
    WriteLn(stream,,"<LABEL FOR=\"username\">Username</LABEL>");
    WriteLn(stream,,"<INPUT NAME=\"username\" TYPE=\"text\">");
    WriteLn(stream,,"<LABEL FOR=\"password\" >Password</LABEL>");
    WriteLn(stream,,"<INPUT NAME=\"password\" TYPE=\"password\">");
    WriteLn(stream,,"<LABEL FOR=\"password2\" >Password</LABEL>");
    WriteLn(stream,,"<INPUT NAME=\"password2\" TYPE=\"password\">");
    WriteLn(stream,,"<INPUT TYPE=\"submit\" VALUE=\"Sign Up\">");
  WriteLn(stream,,"</FORM>");
  WikiFooter(stream,NULL,url);
}

CSrvUser *GetCurrentUser() {
  U8 *cookie=FramePtr(WIKI_SESSION_COOKIE);
  CSrvUser*ret=NULL,*u;
  if(!cookie) return NULL;
  LockUsers;
  for(u=users->next;u!=users;u=u->next) {
    if(!StrCmp(cookie,u->session_cookie)) {
      ret=u;
      break;
    }
  }
  UnlockUsers;
  return ret;
}
U8 *GetCurrentUserName() {
  CSrvUser *u=GetCurrentUser;
  if(u) return StrNew(u->name);
  return NULL;
}

Bool CurrentUserIsAdmin() {
  CSrvUser *u;
  Bool r=FALSE;
  LockUsers;
  u=GetCurrentUser;
  if(u)
    r=ToBool(u->flags&UF_ADMIN);
  UnlockUsers;
  return r;
}
Bool CurrentUserIsBanned() {
  CSrvUser *u;
  Bool r=FALSE;
  LockUsers;
  u=GetCurrentUser;
  if(u)
    r=ToBool(u->flags&UF_BANNED);
  UnlockUsers;
  return r;
}


Bool BanUser(U8 *name) {
  CSrvUser *u=NULL,*cur;
  LockUsers;
  for(cur=users->next;cur!=users;cur=cur->next) {
    if(!StrCmp(cur->name,name)) {
      u=cur;
      u->flags|=UF_BANNED;
      QueRem(u);
      break;
    }
  }
  UnlockUsers;
  //Must spawn with users unlocked
  Spawn(&UpdateUserRegistry,,,0);
}

U0 DeleteUserPost(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,CHashTable *tab) {
  CHashGeneric *hash=HashFind(tab,"user",-1);
  CSrvUser *cur=GetCurrentUser;
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  if(!hash||!cur) {
fail:
    WikiHeader(stream,NULL,"Banned failed!!!",0);
    WriteLn(stream,,"<H2>Maybe you areMissing the Admin Priveledge</H2>");
    WriteLn(stream,,"<P>Or maybe the server messed up.</P>");
    WikiFooter(stream,NULL,url);
    return;
  }
  if(!(cur->flags&UF_ADMIN)){
    WikiHeader(stream,NULL,"Banned failed!!!",0);
    WriteLn(stream,,"<H2>You areMissing the Admin Priveledge</H2>");
    WikiFooter(stream,NULL,url);
    return;
  }
  if(BanUser(hash->user_data1)) {
    WikiHeader(stream,NULL,"Banned Successful!!!",0);
    WriteLn(stream,,"<H2>User \"%s\" just got banned</H2>",hash->user_data1);
    WikiFooter(stream,NULL,url);
    return;
  }
  goto fail;
}

U0 DeleteSelfPost(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,CHashTable *tab) {
  LockUsers;
  CSrvUser *cur=GetCurrentUser;
  CHashGeneric *d_yes=HashFind("d_yes",tab,-1);
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  if(cur&&d_yes) {
    FramePtrDel(WIKI_SESSION_COOKIE);
    WikiHeader(stream,NULL,"Account Deletion Succesful!!!",0);
    WriteLn(stream,,"<H2>You deleted your account.</H2>");
    WikiFooter(stream,NULL,url);
    RemoveUser(cur->name);
    UnlockUsers;
    return;
  }
  WikiHeader(stream,NULL,"Account Deletion Failed!!!",0);
  WriteLn(stream,,"<H2>Make sure you want to delete your account and that you are logged in</H2>");
  WikiFooter(stream,NULL,url);
  UnlockUsers;
}


U0 ChangePassPost(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,CHashTable *tab) {
  CHashGeneric *cur=HashFind("old",tab,-1),*new=HashFind("new",tab,-1),*new2=HashFind("new2",tab,-1);
  if(!UserPrivCheck(srv,stream,url,req,"none")) {
    return;
  }
  LockUsers;
  CSrvUser *u=GetCurrentUser;
  U8 *t;
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  if(!cur||!new||!new2) {
    WikiHeader(stream,NULL,"Internal Error!!!",0);
    WriteLn(stream,,"<H2>Password not changed!!!</H2>");
    WikiFooter(stream,NULL,url);
    goto fin;
  }
  t=FNV64Str(cur->user_data1);
  if(StrCmp(u->pass_hash,t)) {
    Free(t);
    WikiHeader(stream,NULL,"Current password  is incorrect!!!",0);
    WriteLn(stream,,"<H2>Password not changed!!!</H2>");
    WriteLn(stream,,"<P>Passwords don't match</P>");
    WikiFooter(stream,NULL,url);
    goto fin;
  }
  Free(t);
  if(StrCmp(new->user_data1,new2->user_data1)) {
    WikiHeader(stream,NULL,"Passwords dont match!!!",0);
    WriteLn(stream,,"<H2>Password not changed!!!</H2>");
    WriteLn(stream,,"<P>You entered your old password wrong!</P>");
    WikiFooter(stream,NULL,url);
    goto fin;
  }
  WikiHeader(stream,NULL,"Password Change Successful!!!",0);
  WriteLn(stream,,"<H2>Yay!!!</H2>");
  t=FNV64Str(new->user_data1);
  StrCpy(u->pass_hash,t);
  Spawn(&UpdateUserRegistry,,,0);
  Free(t);
  WikiFooter(stream,NULL,url);
fin:
  UnlockUsers;
}

U0 LogoutPost(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,CHashTable *tab) {
  LockUsers;
  CSrvUser *cur=GetCurrentUser;
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  if(cur) {
    StrCpy(cur->session_cookie,"");
    FramePtrDel(WIKI_SESSION_COOKIE);
    WikiHeader(stream,NULL,"Logout Successful!!!",0);
    WriteLn(stream,,"<H2>You logged out.</H2>");
    WikiFooter(stream,NULL,url);
    UnlockUsers;
    //Update session cookie
    Spawn(&UpdateUserRegistry,,,0);
    return;
  }
  WikiHeader(stream,NULL,"Logout Failed!!!",0);
  WriteLn(stream,,"<H2>You weren't logged in!!!</H2>");
  WikiFooter(stream,NULL,url);
  UnlockUsers;
}

U0 AdminPanelPost(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,CHashTable *tab) {
  I64 i;
  CHashGeneric *hash;
  U8 *com,*name;
  CSrvUser *u;
  Bool on;
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  if(u=GetCurrentUser) {
    if(!(u->flags&UF_ADMIN))
      goto need_admin;
  } else {
need_admin:
    WikiHeader(stream,NULL,"Admin Priveledges required!!!",0);
    WriteLn(stream,,"<H2>You aren't permitted to do this.</H2>");
    WikiFooter(stream,NULL,url);
    return;
  }
  LockUsers;
  for(u=users->next;u!=users;u=u->next) {
    u->flags=0;
  }
  for(i=0;i<=tab->mask;i++) {
    for(hash=tab->body[i];hash;hash=hash->next) {
      name=hash->str;
      on=!StrCmp(hash->user_data1,"on");
//username_command
      if((com=StrLastOcc(name,"_"))&&on) {
        *com++=0; //Also nullifes the last '_'
        for(u=users->next;u!=users;u=u->next) {
	  if(!StrCmp(name,u->name)) {
	    if(!StrCmp(com,"admin")) {
	      u->flags|=UF_ADMIN;
	    }
	    if(!StrCmp(com,"banned")) {
	      u->flags|=UF_BANNED;
	      DeleteUserEdits(u->name);
	    }
	    if(!StrCmp(com,"allowed")) {
	      u->flags|=UF_ALLOWED;
	    }
	    break;
	  }
        }
      }
    }
  }
  UnlockUsers;
//The new task will lock users
  Spawn(&UpdateUserRegistry,,,0);
  WikiHeader(stream,NULL,"User settings updated",0);
  WriteLn(stream,,"<H2>User settings updated</H2>");
  WikiFooter(stream,NULL,url);
  return;
}

U0 SaltGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,Bool salt=TRUE) {
  U8 *file=GetQueryValue(url->query,"PAGENAME");
  if(!UserPrivCheck(srv,stream,url,req,file)) {
    Free(file);
    return;
  }
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  if(!file) {
    WikiHeader(stream,NULL,"You've Gone to a Weird Place",0);
    WriteLn(stream,,"<H2>You've Gone to a Weird Place on this Server.</H2>");
    WikiFooter(stream,NULL,url);
    return ;
  }
  SaltFile(file,salt);
  if(salt) {
    WikiHeader(stream,NULL,"File Salted",0);
    WriteLn(stream,,"<H2>File \"%s\" Salted.</H2>",file);
    WriteLn(stream,,"<P>Now only admins can edit the file.</P>");
  } else {
    WikiHeader(stream,NULL,"File Unsalted",0);
    WriteLn(stream,,"<H2>File \"%s\" Unsalted.</H2>",file);
    WriteLn(stream,,"<P>Now everyone can edit the file.</P>");
  }
  WikiFooter(stream,NULL,url);
  Free(file);
}

U0 UserPannelGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
  LockUsers;
  CSrvUser *user=GetCurrentUser,*cur;
  U8 *t1,*checked="";
  I64 i;
  if(!user) {
    UnlockUsers;
    LoginGet(srv,stream,url,req);
    return ;
  }
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  t1=MStrPrint("Account panel for \"%s\"\n",user->name);
  WikiHeader(stream,NULL,t1,0);
  Free(t1);
  WriteLn(stream,,"<H2>Welcome %s:</H2>",user->name);
  WriteLn(stream,,"<H3>Delete Account</H3>");
  WriteLn(stream,,"<FORM ACTION=\"" WIKI_DELETE_ACCOUNT "\" METHOD=\"POST\" CLASS=\"form-group\">");
  WriteLn(stream,,"<FIELDSET CLASS=\"form-group\">");
  WriteLn(stream,,"<LEGEND>Are you sure?</LEGEND>");
  WriteLn(stream,,"<LABEL CLASS=\"paper-radio\" FOR=\"d_yes\">");
  WriteLn(stream,,"<INPUT TYPE=\"radio\" NAME=\"d_yes\" ID=\"d_yes\" VALUE=\"d_yes\">");
  WriteLn(stream,,"<SPAN>Yes,I want to delete my account</SPAN>");
  WriteLn(stream,,"</LABEL>");
  WriteLn(stream,,"<LABEL CLASS=\"paper-radio\" FOR=\"d_no\">");
  WriteLn(stream,,"<INPUT TYPE=\"radio\" NAME=\"d_no\" ID=\"d_no\" VALUE=\"d_no\">");
  WriteLn(stream,,"<SPAN>No,I don't want to delete my account</SPAN>");
  WriteLn(stream,,"</LABEL>");
  WriteLn(stream,,"</FIELDSET>");
  WriteLn(stream,,"<INPUT TYPE=\"submit\" VALUE=\"Delete Account\">");
  WriteLn(stream,,"</FORM>");
  WriteLn(stream,,"<H3>Logout</H3>");  
  WriteLn(stream,,"<FORM ACTION=\"" WIKI_LOGOUT "\" CLASS=\"form-group\" METHOD=\"POST\">");
  WriteLn(stream,,"<INPUT TYPE=\"submit\" VALUE=\"Logout\">");
  WriteLn(stream,,"</FORM>");
  WriteLn(stream,,"<H3>Change Password</H3>");  
  WriteLn(stream,,"<FORM ACTION=\"" WIKI_CHANGE_PASS "\" CLASS=\"form-group\" METHOD=\"POST\">");
    WriteLn(stream,,"<LABEL FOR=\"old\">Old Password</LABEL>");
    WriteLn(stream,,"<INPUT NAME=\"old\" TYPE=\"password\">");
    WriteLn(stream,,"<LABEL FOR=\"new\" >Password</LABEL>");
    WriteLn(stream,,"<INPUT NAME=\"new\" TYPE=\"password\">");
    WriteLn(stream,,"<LABEL FOR=\"new2\" >Confirm New Password</LABEL>");
    WriteLn(stream,,"<INPUT NAME=\"new2\" TYPE=\"password\">");
  WriteLn(stream,,"<INPUT TYPE=\"submit\" VALUE=\"Change password\">");
  WriteLn(stream,,"</FORM>");
  if(user->flags&UF_ADMIN){
    WriteLn(stream,,"<H2>Admin Panel</H2>");
    WriteLn(stream,,"<P>Click a User to edit thier flags,then click the submit "
	  "button to update them.Banning a user will delete thier edits</P>");
    WriteLn(stream,,"<FORM CLASS=\"form-group\" ACTION=\"" WIKI_ADMIN "\" METHOD=\"POST\">");
    WriteLn(stream,,"<DIV CLASS=\"row\">");
    /*
     * $BK,1$paper.css wants the things to be named "collapsibleNNN" $BK,0$
     */
    i=0;
    for(cur=users->next;cur!=users;cur=cur->next,i++) {
      t1=cur->name;
      WriteLn(stream,,"<DIV CLASS=\"collapsible\">");
      WriteLn(stream,,"<INPUT ID=\"collapsible%d\" TYPE=\"checkbox\" NAME=\"collapsible\">",i,t1);
      WriteLn(stream,,"<LABEL FOR=\"collapsible%d\">%s</LABEL>",i,t1);
      WriteLn(stream,,"<DIV CLASS=\"collapsible-body row\">",t1);
      WriteLn(stream,,"<FIELDSET class=\"form-group\">");
      WriteLn(stream,,"<label for=\"%s_admin\" class=\"paper-check\">",t1);
      if(cur->flags&UF_ADMIN)
	checked="checked";
      else
	checked="";
      WriteLn(stream,,"<input type=\"checkbox\" name=\"%s_admin\" id=\"%s_admin\" %s> <span>Admin</span>",t1,t1,checked);
      WriteLn(stream,,"</label>");
      WriteLn(stream,,"<label for=\"%s_banned\" class=\"paper-check\">",t1);
      if(cur->flags&UF_BANNED)
	checked="checked";
      else
	checked="";
      WriteLn(stream,,"<input type=\"checkbox\" name=\"%s_banned\" id=\"%s_banned\" %s> <span>Banned</span>",t1,t1,checked);
      WriteLn(stream,,"</label>");
      if(cur->flags&UF_ALLOWED)
	checked="checked";
      else
	checked="";
      WriteLn(stream,,"<label for=\"%s_allowed\" class=\"paper-check\">",t1);
      WriteLn(stream,,"<input type=\"checkbox\" name=\"%s_allowed\" id=\"%s_allowed\" %s> <span>Approved by Admin</span>",t1,t1,checked);
      WriteLn(stream,,"</label>");
      WriteLn(stream,,"</FIELDSET>");
      WriteLn(stream,,"</SPAN>");
      WriteLn(stream,,"</DIV>");
      WriteLn(stream,,"</DIV>");
    }
    WriteLn(stream,,"</DIV>");
    WriteLn(stream,,"<INPUT TYPE=\"submit\" VALUE=\"Update Accounts\">");
    WriteLn(stream,,"</FORM>");
  }
  WikiFooter(stream,NULL,url);
  UnlockUsers;
}
//Checks for 
// 1. if logged in
// 2. if not banned
Bool UserPrivCheck(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,U8 *file) {
  U8 *t1=GetCurrentUserName;
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  if(!t1){
      WikiHeader(stream,NULL,"Login to Edit.",FALSE);
      WriteLn(stream,NULL,"<H1>Create an account to edit pages!!!</H1>");
      WikiFooter(stream,NULL,url);
      Free(t1);
      return FALSE;
  }
  if(CurrentUserIsBanned) {
      WikiHeader(stream,NULL,"You were banned.",FALSE);
      WriteLn(stream,NULL,"<H1>You were banned!!!</H1>");
      WikiFooter(stream,NULL,url);
      Free(t1);
      returnFALSE;
  }
  if(!CurrentUserIsAdmin&&FileIsSalted(file)) {
      WikiHeader(stream,NULL,"This File is Salted.",FALSE);
      WriteLn(stream,NULL,"<H1>This File is Salted</H1>");
      WriteLn(stream,NULL,"<P>You must be an admin to edit this file</P>");
      WikiFooter(stream,NULL,url);
      Free(t1);
      return FALSE;
  }
  Free(t1);
  return TRUE;
}
