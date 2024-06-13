#ifndef IRCD_ACCOUNT_HH
#define IRCD_ACCOUNT_HH 'poop'
class CIrcAccount {
  CDate last_login;
  I64 password_hash;
  U8 realname[STR_LEN];
};
#define IRC_ACNT_REGISTRY "Gihon/Accounts"

CIrcAccount *_IrcAccountGet(U8 *realname,I64 password_hash,CDate last_login) {
  CIrcAccount *acnt=CAlloc(sizeof(CIrcAccount),gihon_task);
  acnt->password_hash=password_hash;
  StrCpy(acnt->realname,realname);
//Dumb hack,if no assume assume throw-away account
  if(HashStr("")==acnt->password_hash)
    acnt->last_login=0;
  else
    acnt->last_login=last_login;
  return acnt;
}
CIrcAccount *IrcAccountLogin(IrcClient *client,U8 *realname,U8 *password="") {
  CIrcAccount *account;
  I64 hash=HashStr(password);
  U8* path=MStrPrint("%s/%s",IRC_ACNT_REGISTRY,realname,password),*dft;
  dft=MStrPrint("_IrcAccountGet(\"%Q\",%d,%d);",realname,hash,0);
  RegDft(path,dft);
  account=RegExe(path);
  Free(path);
  Free(dft);
  client->last_connect=account->last_login;
  if(hash!=account->password_hash) {
    if(account->password_hash==HashStr("")) { //Server has Empty password,use new one
      StrCpy(client->password,password);
    } else {
      GihonFifoIns(client->msgs,MStrPrint("%s 464 * %s:Password mismatch\r\n",ircd_hostname,client->username));
      client->disconnected=TRUE;
    }
    return NULL;
  } else   if(HashStr("")==hash) {
    GihonFifoIns(client->msgs,MStrPrint(":%s 372 %s : Please set a password(all trafic in here is logged so be careful)\r\n", ircd_hostname, client->username));
  }
  return account;
}
U0 IrcClientAccountLogout(IrcClient *c) {
  CIrcAccount *acc=c->account;
  if(!acc) return;
  U8 *realname=acc->realname;
  I64 password_hash=HashStr(c->password);
  U8 *path=MStrPrint("%s/%s",IRC_ACNT_REGISTRY,realname);
  U8 *new=MStrPrint("_IrcAccountGet(\"%Q\",%d,%d);",realname,password_hash,Now);
  RegWrite(path,new);
  Free(path);Free(new);Free(acc);
}
#endif