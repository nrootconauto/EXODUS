#define IRCD_LIMIT_MAX      20
#define IRCD_PING_INTERVAL  60000
#define IRCD_PORT           6667
#define IRCD_RXBUF_SIZE     4096
#define IRCD_TXBUF_SIZE     4096
#define IRCD_TXFIFO_SIZE    128

U8 *ircd_hostname = "irc.gihon.local";
I64 ircd_chans_total = 0;
I64 ircd_clients_total = 0;

#include "Motd";
#include "Service";
#include "Arg";
#include "Client";
#include "Channel";
#include "Command";


I64 Gihon()
{
    DyadInit;
    CDyadStream *server=DyadNewStream;
    DyadSetListenCallback(server,DYAD_EVENT_ACCEPT,
                           &IrcClientHandler,server);
    DyadListen(server,6667);
    try {
        while(TRUE) {
            Sleep(100);
            DyadUpdate; //Updating will run the events
        }
    } catch
        PutExcept;
    DyadShutdown;
    return 0;
}
Gihon;
