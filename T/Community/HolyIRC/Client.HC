
/**
 * Type ':JOIN #anonchan' after the Client logs you in
 * Usage ClientNew(hn="chat.freenode.org",port=6667,user_name);
 * I don't know how to use IRC so you are on your own
 */
class CClient {
  CDyadStream *srv;
  U8 name[STR_LEN];
  U8 host[STR_LEN];
  U8 channel[STR_LEN];
  CDoc *doc;
  CDocEntry *prompt;
  CTask *bg_thread;
  Bool first_run;
};
U0 ClientPrint(CClient *cl,U8 *fmt,...) {
  //StrPrintJoin takes argc and argc
  U8 *fmted=StrPrintJoin(NULL,fmt,argc,argv);
  CDocEntry *cur=cl->doc->cur_entry;
  DocLock(cl->doc);
  cl->doc->cur_entry=cl->prompt->last;
  DocPrint(cl->doc,"%s",fmted);
  cl->doc->cur_entry=cur;
  DocUnlock(cl->doc);
  Free(fmted);
}
U0 ServerWrite(CClient *cl,U8 *fmt,...) {
  U8 to_send;
  //StrPrintJoin takes argc and argc
  to_send=StrPrintJoin(NULL,fmt,argc,argv);
  DyadWrite(cl->srv,to_send,StrLen(to_send)); 
  DyadWrite(cl->srv,"\r\n",2); 
  Free(to_send);
}
U8 *Skip(U8 *str,U8 chr) {
  while(*str&&*str!=chr)
   str++;
  if(*str!=0)
    *str++=0;
  return str;
}
U0 ServerConnect(CDyadStream *s,CClient *cl) {
  if(cl->first_run) {
    cl->first_run=FALSE;
// This is optional
// PASS passwd
//
//    ServerWrite(cl,"PASS %s",cl->passwd);

//
// NICK namae
//
    ServerWrite(cl,"NICK %s",cl->name);
//
// USER username hostname servername :realname
//
    ServerWrite(cl,"USER %s localhost %s :%s",
	  cl->name,
	  cl->host,
	  cl->name
	  );
  }

}
U0 ServerReadCb(CDyadStream *s,U8 *text,I64 len,U8 *user_data) {
  TOSPrint("%s\n",text);
  CClient *cl=user_data;
  U8 *cmd=text,*usr=NULL,*txt=NULL,*par=NULL,*tmp;
//
// Server stuff has this format
// ':',servername,'!',nick,' ',params \r\n
// params = ' ',':',stuff,params*
//
  if(text[0]==':') {
//Command ends at space,so we skip it 
    usr=cmd+1; //$BK,1$servername can also be a nickname$BK,0$
    cmd=Skip(cmd,' ');
//User comes after '!'
    Skip(usr,'!');    
  }
  par=Skip(cmd,' ');
  txt=Skip(par,':');
  //TOSPrint("CMD:%s\n",cmd);
  if(!StrCmp("PONG",cmd)) {
    return;
  }
  if(!StrCmp("PRIVMSG",cmd)) {
    ClientPrint(cl,"<%s> %s",usr,txt);
    return;
  }
  if(!StrCmp("PING",cmd)) {
    TOSPrint("PONG%s\n",txt);
    ServerWrite(cl,"PONG %s",txt);
    return;
  }
  ClientPrint(cl,"(%s)>>> %s (%s): %s",usr,cmd,par,txt);
}

U0 ServerLoop(CClient *cl) {
  while(TRUE) {
    DyadUpdate;
    Sleep(1000);
  }
}
U0 MsgChannel(CClient *cl,U8 *channel,U8 *msg) {
  ClientPrint(cl,"<%s> %s\n",channel,msg);
  ServerWrite(cl,"PRIVMSG %s :%s",channel,msg);
}
CClient *ClientNew(U8 *server="irc.libera.chat",I64 port=6667,U8 *name="Terry") {
  Bool cont=TRUE;
  U8 *s,*p;
  U8 who[STR_LEN],msg[STR_LEN];
  I64 i;
  WinMax;
  DyadInit;
  CClient *cl=CAlloc(sizeof(CClient));
  cl->srv=DyadNewStream;
  DyadSetListenCallback(cl->srv,DYAD_EVENT_CONNECT,&ServerConnect,cl);
  DyadSetReadCallback(cl->srv,DYAD_EVENT_LINE,&ServerReadCb,cl);
  StrCpy(cl->name,name);
  StrCpy(cl->host,server);
  StrCpy(cl->channel,"#anonchan");
  cl->doc=DocPut; //The current document
  cl->first_run=TRUE;
  DyadConnect(cl->srv,server,port);
  cl->bg_thread=Spawn(&ServerLoop,cl,,,Fs);
  while(cont) {
    DocLock(cl->doc);
    if(cl->prompt)
      DocEntryDel(cl->doc,cl->prompt);
    DocBottom(cl->doc);
    cl->prompt=DocPrint(cl->doc,">>>$$PT$$");
    DocUnlock(cl->doc);
    s=GetStr(,"");
    if(s) {
      //Things without a ':' automagically go to the current channel
      if(s[0]!=':') {
        MsgChannel(cl,cl->channel,s);
      } else {
        if(!StrNICmp(s+1,"JOIN",4)) {
	  //If we are in a channel,quit
	  if(*cl->channel) {
	    ServerWrite(cl,"PART %s",cl->channel);
	  }
	  //Join a channel
	  StrCpy(cl->channel,s+5);
	  StrUtil(cl->channel,SUF_REM_LEADING|SUF_REM_TRAILING);
//
// JOIN #channel
//
	  ServerWrite(cl,"JOIN %s",cl->channel);
//
// TOPIC #channel
//
	  ServerWrite(cl,"TOPIC %s",cl->channel);
        }
        if(!StrNICmp(s+1,"LIST",4)) {
//
// LIST
//
	  ServerWrite(cl,"LIST");
        }
        if(!StrNICmp(s+1,"WHO",3)) {
//
// NAMES #channel //What do you think it does
//
	  ServerWrite(cl,"NAMES %s",cl->channel);  
	}
        if(!StrNICmp(s+1,"PART",4)) {
//
// PART #channel,leave a channel
//
	  StrCpy(who,s+5);
	  StrUtil(who,SUF_REM_LEADING|SUF_REM_TRAILING);
	  ServerWrite(cl,"PART %s",who);
	}
        if(!StrNICmp(s+1,"MSG",3)) {
	  //Join a channel
	  i++;
	  StrCpy(who,s+4);
	  StrUtil(who,SUF_REM_LEADING|SUF_REM_TRAILING);
          if(!StrLen(who)) {
	    ClientPrint(cl,"WHODOIMESSAGE.\n");
	    goto next;
          }
          while(who[i]&&!Bt(char_bmp_white_space,who[i]))
            i++;
          who[i]=0;
          if(!who[i+1]) {
	    ClientPrint(cl,"IWANTAMESSAGETOSENDTO'%s'.\n",who);
	    goto next;
          }
          StrCpy(msg,who+i+1);
	  StrUtil(msg,SUF_REM_LEADING|SUF_REM_TRAILING);
	  MsgChannel(cl,who,msg);
        }
        if(!StrNICmp(s+1,"PING",4)) {
	  ServerWrite(cl,"PING %s",cl->channel);
	}
        if(!StrNICmp(s+1,"EXIT",4)) {
	  if(*cl->channel) {
	    ServerWrite(cl,"PART %s",cl->channel);
	  }
	  ServerWrite(cl,"QUIT");
	  DyadEnd(cl->srv);
	  ClientPrint(cl,"BYE BYE!!!\n");
	  cont=FALSE;
	}
	if(!StrNICmp(s+1,"HELP",4)) {
	  ClientPrint(cl,"PART --- Leave a channel.\n");
	  ClientPrint(cl,"LIST --- What are the channels.\n");
	  ClientPrint(cl,"WHO --- Who is on.\n");
	  ClientPrint(cl,"HELP --- Display this message.\n");
	  ClientPrint(cl,"JOIN <chan> --- What do you think it does.\n");
	  ClientPrint(cl,"MSG <dude> <msg> --- Msg a dude.\n");
	  ClientPrint(cl,"EXIT --- Leave this sexy client.\n");
	  cont=FALSE;
	}
      }
    }
next:
    Free(s);
  }
  Kill(cl->bg_thread);
}
CClient *cl=ClientNew("localhost",6668,"Bungis");
