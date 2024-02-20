/*
	CCONFIG2.C: Second primary source file for the CCONFIG
		    utility. See CCONFIG.C for essential information
*/

#include <stdio.h>
#include "cconfig.h"

dooptim()
{
	char c;
	int i;

	p("CODE OPTIMIZATION CONTROL:\n")
	p("Compiled BDS C code can be optimized for either speed or space,")
	p("through the use of several unique 'tuning' controls. The")
	p("configuration you are about to perform sets only the default")
	p("optimization mode; any")
	p("compilation may be individually tailored by using the -o and -z")
	p("CC command-line options.\n\n")
	p("There are three code optimization modes for BDS C: ")
	p("'fast', 'short' and 'extended-short'.\n\n")
	p("FAST mode causes all code sequences to run")
	p("as fast as possible; this can be achieved by using the \"-o\" and")
	p("\"-e <xxxx>\" CC command-line options while making all variables")
	p("in the program external.\n")
	p("SHORT mode replaces several common code sequences by")
	p("calls to equivalent subroutines in the run-time package.")
	p("This slows execution down a bit, due to the subroutine overhead,")
	p("but saves considerable space. This is the default")
	p("mode set in the distribution package.\n")

	p("(Press RETURN to continue)"); getch();

	p("EXTENDED-SHORT mode does everything that simple-short mode does,")
	p("but")
	p("also takes advantage of any unused system restart vectors that")
	p("may be available on a SPECIFIC target computer system.")
	p("This is accomplished by collapsing")
	p("certain very common, short (3-6 byte) code sequences into")
	p("1-byte RST instructions. To use this mode you must first know")
	p("which RST vectors")
	p("are available on the target system. Then you change the")
	p("appropriate symbols (ZOPT1-ZOPT7)")
	p("in the run-time package source file and re-assemble the run-time")
	p("package. Finally, the \"-z\" CC command-line option is")
	p("used to tell CC which RST vectors are available.\n")

  go:	p("\nPlease choose the default optimization mode:\n")
	p("Fast (F), Short (S), or Extended-Short (E): ")

	switch(c = toupper(getch()))
	{
 	  case 'F': optim = 0;
		    break;

	  case 'S': optim = 0x80;
		    break;

	  case 'E': optim = 0x80;
		    p("For extended mode, you need to specifiy those restart")
		    p("vectors that are guaranteed to be unused by any other")
		    p("software on the target system. Any restart vector")
		    p("except RST 0 may be used, i.e., RST 1 through RST 7.\n")
		    p("Answer 'y' or 'n' to each query to specify if the")
		    p("respective RST vector is available")
		    p("for extended-short RST optimization:\n")
		    for (i = 1; i < 8; i++)
		    {
			p("RST ")
			putchar(i+'0');
			p(" ? ")
			optim |= yesp() << (i - 1);
		    }
		    break;

	  default:  p("Invalid selection. Try again:\n");
		    goto go;
	} 
}

char *gets0(str)	/* Accept text input, ^Z aborts back to menu level */
char *str;
{
	gets(str);
	if (igsp(str) == 'Z'-0x40)
		longjmp(jbuf);
	return str;
}


int yesp()
{
	char c;
	while (1)
	{
		column = 1;		/* prevent spurious newlines */

		if ((c = toupper(igsp(gets0(strbuf)))) == 'Y')
			return TRUE;
		else if (c == 'N')
			return FALSE;
		p("Please answer 'yes' or 'no'... ? ")
	}
}


display()
{
	int i;

	p("\nThe configuration options are currently set as follows:\n\n")

	p(" Code#	Option			 Current Setting\n")
	p(" -----	------			 ---------------")
	p("\n  0:	Default Drive		")
	if (defdsk == 0xff)
		p("Currently logged drive")
	else
		printf("Drive %c:", defdsk + 'A');

	p("\n  1:	Default User Area	")
	if (defusr == 0xff)
		p("Currently logged user area")
	else
		printf("User %d", defusr);

	p("\n  2:	Submit File Drive	")
	if (defsub == 0xff)
		p("Currently logged drive")
	else
		printf("Drive %c:", defsub + 'A');

	p("\n  3:	Console Interrupts	")
	if (conpol) p("Enabled") else p("Disabled")

	p("\n  4:	Suppress Warm Boot?	")
	if (wboote) p("No") else p("Yes")

	p("\n  5:	Strip Source Parity?	")
	if (pstrip) p("Yes") else p("No")

	p("\n  6:	Recognize User Areas?	")
	if (nouser) p("No") else p("Yes")

	p("\n  7:	Write RED Error File?	")
	if (werrs) p("Yes") else p("No")

	p("\n  8:	Optimization Mode	")
	if (optim == 0)
		p("Fast Execution, Long Code Sequences")
	else
	{
		p("Short Code, ")
		if (optim == 0x80)
			p("No Restarts")
		else
		{
			p("Use RST vectors: ")
			for (i = 1; i < 8; i++)
			if (optim & (1 << (i - 1)))
				printf("%d ",i);
		}
	}

	p("\n  9:	Default CDB RST Vector	")
	printf("RST %d", cdbrst);	

	p("\n\n")
}

read_block()
{
	if ((fd_cc = open("CC.COM", 2)) == ERROR ||
	    (fd_clink = open("CLINK.COM", 2)) == ERROR)
	{
	   p("\nCCONFIG requires copies of both CC.COM and CLINK.COM")
	   p("to be present in the currently logged directory. Please copy")
	   p("them to this directory now, then run CCONFIG again.\n")
		exit();
	}
	if (read(fd_cc, secbuf, 1) != 1)
	{
		p("Disk error reading CC.COM.")
		exit();
	}
	movmem(&secbuf[0x55], cblock, NBYTES);
}

write_block()
{
	movmem(cblock, &secbuf[0x55], NBYTES);
	seek(fd_cc, 0, 0);
	if (write(fd_cc, secbuf, 1) == 1)
		close(fd_cc);
	else
	{
	  	p("\nError writing CC.COM.")
	 foo:   p("Please place fresh copies of CC.COM and")
		p("CLINK.COM in the current directory, and run CCONFIG")
		p("again. Sorry, but I don't know why this happened.\n")
		exit();
	}

	read(fd_clink, secbuf, 1);
	movmem(cblock, &secbuf[0x03], NBYTES);
	seek(fd_clink, 0, 0);
	if (write(fd_clink, secbuf, 1) == 1)
		close(fd_clink);
	else
	{
		p("\nError writing CLINK.COM.")
		goto foo;
	}

	p("\nCC.COM and CLINK.COM successfully updated.\n");
}

prnt(str)	/* print given text, automatically filling to length of line */
char *str;
{
	char c;

	while (c = *str++)
	{
		if (c != '\n' && (wdlen(str) + column++) < (MAXCOL - 3))
		{
			putchar(c);
			if (!*str)
				putchar(' ');
			continue;
		}

		putchar('\n');

		if (!isspace(c))
			putchar(c);

		column = 1;
	}
}


int getch()	/* get a char of text */
{
	int c;
	if ((c = getchar()) == -1)
		longjmp(jbuf);
	p("\n")
	return c;
}


int wdlen(txt)	/* return length of text word */
char *txt;
{
	int i;
	for (i = 0; *txt && !isspace(*txt++); i++)
		;
	return i;
}


int ask(txt)
char *txt;
{
	char strbuf[30];

	if (txt)
		p(txt)

	gets(strbuf);

	column = 0;

	if (tolower(igsp(strbuf)) == 'y')
		return TRUE;
	else
		return FALSE;
}

char igsp(txt)		/* return first non-space character */
char *txt;
{
	char c;
	while (isspace(c = *txt++))
		;
	return c;
}

init()
{

	int dodefdsk(), dodefusr(), dodefsub(), doconpol(), dowboote();
	int dopstrip(), donouser(), dowerrs(), dooptim(), docdbrst();

	initptr(&funcs, &dodefdsk, &dodefusr, &dodefsub, &doconpol, &dowboote,
		 &dopstrip, &donouser, &dowerrs, &dooptim, &docdbrst, NULL);

	made_changes = column = 0;
}
