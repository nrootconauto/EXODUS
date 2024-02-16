
#define MAXCOL 80	  /* Number of columns on your terminal		*/

#define NBYTES 10	  /* Number of bytes in configuration block	*/

#define defdsk cblock[0]  /* default library disk byte			*/
#define defusr cblock[1]  /* default library user area byte		*/
#define defsub cblock[2]  /* default submit file disk drive byte	*/
#define conpol cblock[3]  /* console interrupt polling flag byte	*/
#define wboote cblock[4]  /* warm-boot control byte			*/
#define pstrip cblock[5]  /* parity stripping control byte		*/
#define nouser cblock[6]  /* ignore user areas control byte		*/
#define werrs  cblock[7]  /* write PROGERRS.$$$ for RED control byte	*/
#define optim  cblock[8]  /* optimization control byte			*/
#define cdbrst cblock[9]  /* CDB default restart vector			*/

#define p(text) prnt(text); /* maximizes source text line width 	*/

int column;		/* current column position for prnt() function	*/
int made_changes;	/* true if any options re-configured		*/
char old_val;		/* old value of each option, to detect changes	*/

char cblock[NBYTES];
int (*funcs[NBYTES])();

int fd_cc, fd_clink;	/* file descriptors				*/
char secbuf[128];	/* sector buffer for reading/writing CC, CLINK	*/
char strbuf[120], c;

char jbuf[JBUFSIZE];
