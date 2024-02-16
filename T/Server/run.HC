Cd("T:/");; //We are not serving from RootFS
Cd("/Server");;
#define WIKI_ADMIN_EMAILS "example@example.com"
#define WIKI_SERVER_PORT 8080

U0 ServerYield() {
  I64 to=FramePtr("TIMEOUT");
  if(to) {
    if(to(F64)<=tS)
      Exit;
  }
  Yield;
}

//This dude will refresh the search index for find.hC
extern class CServer;
extern class CURL;
extern class CHTTPRequest;
extern U0 ReleaseCache();
extern U0 ReleaseUsers();
extern U0 FinalizeHTTPHeader(CDyadStream*);
extern U8 *GetCurrentUserName();
extern U8 *GetCurrentUser();
extern Bool CurrentUserIsBanned();
extern U0 GenertateStyleSheet(CDyadStream *s,I64 len);
//Checks if not logged in too
extern Bool UserPrivCheck(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,U8 *file);
extern Bool FileIsSalted(U8 *file);
extern Bool CurrentUserIsAdmin();
#define WIKI_EDIT "/EDIT"
#define WIKI_CHANGE_PASS "/CHPASS" 
#define WIKI_ROOT "/Wiki"
#define WIKI_NAME "TempleOS Tiki"
#define WIKI_HOME "/"
#define WIKI_INDEX "/INDEX"
#define WIKI_SEARCH "/FIND"
#define WIKI_PREVIEW "/Wiki/Preview"
#define WIKI_UPLOAD "/UPLOAD"
#define WIKI_BACKUP "/WikiBackups"
#define WIKI_CHANGES "/CHANGES"
#define WIKI_CHANGES_FOR_FILE "/FCHANGE"
#define WIKI_RESTORE "/RESTORE" //Takes FILE and REVISION 
#define WIKI_SESSION_COOKIE "usrsescook"
#define WIKI_LOGIN "/LOGIN"
#define WIKI_LOGIN2 "/LOGIN2" //Used when sending a forum
#define WIKI_SIGNUP2 "/SIGNUP2" //Used when sending a forum
#define WIKI_ACCOUNT "/ACCOUNT"
#define WIKI_LOGOUT "/LOGOUT"
#define WIKI_DELETE_ACCOUNT "/DEL_ACNT"
#define WIKI_ADMIN "/ADMIN"
#define WIKI_SALT "/SALT"
#define WIKI_UNSALT "/UNSALT"
#define WIKI_VIEW_FILE "/VIEWFILE"
#define WIKI_DELETE "/DELETE"
if(!FileFind(WIKI_ROOT))
  DirMk(WIKI_ROOT);
if(!FileFind(WIKI_PREVIEW))
  DirMk(WIKI_PREVIEW);
if(!FileFind(WIKI_BACKUP))
  DirMk(WIKI_BACKUP);
#include "DynamStr.HC"
#include "utils.HC"
#include "etags.HC"
#include "http.HC"
#include "header_footer.HC"
#include "find.HC"
#include "diff.HC"
#include "backup.HC"
#include "edit.HC"
#include "index.HC"
#include "cache.HC"
#include "users.HC"
#include "touch_all.HC"
RegDft("Server/init","TouchAll;;");
RegExe("Server/init");
RegWrite("Server/init",";");
#include "syntax.HC"
#include "gen_html.HC"; 
