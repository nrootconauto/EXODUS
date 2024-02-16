/*
	CASM Image Hex-to-Crl Converter

	Copyright (c) 1983 William C. Colley III

	Created 10 March 1983 by William C. Colley III

This utility converts the Intel hex image that results from the CASM/ASM
process to a BDS C relocatable object image. CLOAD is necessary due to the
CP/M LOAD.COM utility's inability to handle binary images having an origin
address at anywhere other than 0100h. 

To use the program, you do the following:

	A>cload <hexfile>[.hex] [-o <crlfile>[.crl]]

The optional -o option allows you to specify the name of the output file.  If
you don't use -o, the output file will be named <hexfile>.crl.  The input file-
name extension defaults to ".hex" if none is specified.  The output filename
extension defaults to ".crl".

Compile & Link:
	cc cload.c
	clink cload -n

*/

#include <stdio.h>

#define	HARD	1
#define	SOFT	0

#define	STACKSZ	1024

/*  These things are used to manipulate the input and output files.	*/

char hexname[MAXLINE], crlname[MAXLINE];
FILE *hex;  int crl;

/*  These things are used to manipulate the core buffer.		*/

char *bbase, *bend, *bsize;

/*  These things are used to do the reading of the Intel hex file.	*/

char bcnt, chks;
union {
    struct { char l, h; } b;
    unsigned w;
} addr;

/*  These things are reserved for the use of the main() function.	*/

char *p;  int i;

/*  This thing is reserved for the use of the hgetc() function.		*/

int j;

/*  This thing is reserved for the use of the hgetn() function.		*/

int k;

main(argc,argv)
int argc;
char *argv[];
{
    char hgetc(), *endext(), *topofmem();

    puts("CASM Image Hex-to-Crl Converter -- v1.6\n");
    puts("Copyright (c) 1983 William C. Colley III\n\n");

    for (p = hexname; --argc && p; ) {
	if (**++argv == '-') p = (*++*argv == 'O' ? crlname : NULL);
	else {
	    if (*p) p = NULL;
	    else {
		makename(p,*argv,p == hexname ? ".HEX" : ".CRL",SOFT);
		p = hexname;
	    }
	}
    }

    if (!p || !hexname[0]) {
	puts("Usage:  A>cload hexname[.ext] [-o crlname[.ext]]\n");
	exit();
    }
    if (!crlname[0]) makename(crlname,hexname,".CRL",HARD);

    if ((hex = fopen(hexname,"r")) == ERROR) die(NULL);
    if ((crl = creat(crlname)) == ERROR) die(NULL);

    bbase = bsize = sbrk(5000);  bend = topofmem() - STACKSZ;

    for (;;) {
	while ((i = getc(hex)) != ':')
	    if (i == ERROR || i == CPMEOF) badfile();
	chks = 0;  bcnt = hgetc();  addr.b.h = hgetc();
	addr.b.l = hgetc();  hgetc();
	if (bcnt == 0) {
	    if (hgetc(),chks) badfile();
	    break;
	}
	for (p = bbase + addr.w - 0x100; bcnt; --bcnt) {
	    if (p > bend) die("Out of memory");
	    if (p > bsize) bsize = p;
	    *p++ = hgetc();
	}
	if (hgetc(),chks) badfile();
    }

    i = (bsize - bbase + SECSIZ) / SECSIZ;

    if(write(crl,bbase,i) != i || fclose(hex) == ERROR || close(crl) == ERROR)
	die(NULL);

    puts(crlname);
    puts(" successfully generated.\n");
}

makename(new,old,ext,flg)
char *new, *old, *ext;
int flg;
{
     while (*old) {
	if (*old == '.') { strcpy(new,flg ? ext : old);  return; }
	*new++ = *old++;
    }
    strcpy(new,ext);
}

int hgetc()
{
    int j;

    j = hgetn() << 4;  chks += (j += hgetn());  return j;
}

int hgetn()
{
    int k;

    if ((k = getc(hex)) >= '0' && k <= '9') return k - '0';
    if (k >= 'A' && k <= 'F') return k - ('A' - 10);
    badfile();
}

badfile()
{
    die("Defective Intel hex file");
}

die(msg)
char *msg;
{
    puts(msg ? msg : errmsg(errno()));  putchar('\n');  exit();
}

