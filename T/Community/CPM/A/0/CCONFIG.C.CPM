/*
	CCONFIG.C
	BDS C v1.6 Automated Configuration Program
	Written 4/86 by  Leor Zolman
			 BD Software, Inc.
	
	compile & link:
		cc cconfig.c -e5000
		cc cconfig2.c -e5000
		clink cconfig cconfig2

	Note: This program may be used as a template for creating a
	configuration tool for any general purpose utility that contains
	a block of bytes of customization data. I therefore donate this
	program to the public domain.
						-leor

*/

#include <stdio.h>
#include "cconfig.h"

main()
{
	int i;

	init();

	p("\nBDS C v1.6 Automatic Configuration System\n\n")
	p("This program makes physical changes to the files CC.COM and")
	p("CLINK.COM so as to customize their operation for your specific")
	p("file system and operating system environment. Do NOT run this")
	p("program until you have backed up your master BDS C distribution")
	p("disks and physically removed them from your disk drives.\n\n")

	p("Have you backed up your master disks and placed copies of CC.COM")
	p("and CLINK.COM in the currently logged directory?")
	if (!ask(0))
	{
		p("Then do so now, and run this program again when ready\n")
		exit();
	}

	p("\n\nThen we are ready to begin.\n")
	p("\n	Note:	Typing ^Z-<CR> (control-Z and a return) in\n")
	p("		response to any question in the option dialogue\n")
	p("		causes the option value to remain unchanged and\n")
	p("		control to return to the main menu.\n\n")

	read_block();

	setjmp(jbuf);

	while(1)
	{
		display();	/* display current options status */
		p("Type the code number of the option you wish")
		p("to change, 'all' to go through the entire list, or")
		p("'q' to quit: ")
		switch(c = tolower(igsp(gets(strbuf))))
		{
		     case 'q':	if (made_changes)
				  if (ask("\nWrite changes to disk?"))
				  {
				       write_block();
				       p("New CC.COM and CLINK.COM written.\n")
				  }
				  else
				       p("Old configuration left intact.\n")
				else
				  p("No changes specified.\n")

				exit();

		     case 'a':	p("\n\tNote: ^Z <CR> returns to the main")
				p("menu at any time.\n\n")
				for (i = 0; i < NBYTES; i++)
				{
					p("\n\n");
					old_val = cblock[i];
					(*funcs[i])();
					if (old_val != cblock[i])
						made_changes = TRUE;
				}
				continue;

		     default:	if (!isdigit(c) ||
				   (i = atoi(strbuf)) < 0 || i >= NBYTES)
				{
					p("Invalid selection. Try again...")
					continue;
				}
				p("\n")
				old_val = cblock[i];
				(*funcs[i])();
				if (old_val != cblock[i])
					made_changes = TRUE;
		}
	}
}


excurlog()
{
 	p("\nNote: The term \"currently logged\", as used in the following")
	p("dialogue, refers to the disk drive and user area that will be")
	p("currently logged at the time CC.COM or CLINK.COM is invoked, not")
	p("necessarily the drive and user area currently logged right now")
	p("while you run CCONFIG.\n\n")
}


dodefdsk()
{
	p("DEFAULT LIBRARY DISK DRIVE:\n")
	excurlog();
	p("The default library disk drive is the drive that CC and CLINK")
	p("automatically search for system header files and default library")
	p("object modules. If you do not choose a specific drive, then")
	p("the currently logged disk at the time of command invokation will")
	p("be searched by default.")
	p("Enter either an explicit default library disk drive, or type")
	p("RETURN to always search the currently logged drive: ")

	if (isalpha(c = toupper(igsp(gets0(strbuf)))))
		defdsk = c - 'A';
	else
		defdsk = 0xFF;
}	

dodefusr()
{
	p("DEFAULT LIBRARY USER AREA:\n")
	excurlog();
	p("The default library user area is the user area that CC and CLINK")
	p("automatically search for system header files and default library")
	p("object modules. If you don't choose a specific user area, then")
	p("the currently logged user area at the time of command invokation")
	p("will be searched by default.\n")

	p("Enter either an explicit default library user area, or type RETURN")
	p("to always search the currently logged user area: ")

	if (isdigit(igsp(gets0(strbuf))))
		defusr = atoi(strbuf);
	else
		defusr = 0xFF;
}

dodefsub()
{
	p("\"SUBMIT FILE\" DRIVE SELECTION:\n")
	excurlog();
	p("In order to terminate a batch (\"submit\") file sequence upon")
	p("fatal compiler or linker error, CC and CLINK must know which")
	p("disk drive contains the temporary scratch file used by SUBMIT.COM")
	p("and similar utilities. This will usually be either drive A: or")
	p("the currently logged drive. Enter the drive name now, or type")
	p("RETURN to use the \"currently logged drive\": ")

	if (isalpha(c = toupper(igsp(gets0(strbuf)))))
		defsub = c - 'A';
	else
		defsub = 0xFF;
}

doconpol()
{
	p("CONSOLE POLLING FOR CONTROL-C:\n")
	p("When console polling is enabled, CC and CLINK will constantly")
	p("check the console keyboard during their operation to see if")
	p("control-C has been typed. If control-C is detected, the command")
	p("is immedieatly aborted and control returns to CP/M command level.")
	p("Any characters OTHER than control-C are ignored and discarded.")
	p("Therefore, if your system supports keyboard \"type-ahead\" and you")
	p("want to take advantage of that feature during CC or CLINK")
	p("operation, you may not want console-polling activated.\n")
	p("Do you wish to have console-polling take place? ")
	
	conpol = yesp();
}

dowboote()
{
	p("WARM-BOOT SUPPRESSION CONTROL:\n")
	p("CC and CLINK have the ability to return to CP/M command level")
	p("following completion of their tasks without having to perform")
	p("a \"warm-boot\" (the re-loading of the CP/M Console Command")
	p("Processor (CCP) from disk). They take advantage of this ability")
	p("any time a compilation or linkage does not require the use of the")
	p("memory occupied by the CCP. This \"warm-boot suppression\" results")
	p("in a speedier return to command level.\nOn some CP/M-like systems,")
	p("though, this feature doesn't work because a valid stack pointer is")
	p("never provided to transient commands by the operating system. One")
	p("symptom is that the command will appear to terminate normally, but")
	p("instead of returning to command level, the system hangs.")
	p("In the case of CC.COM, for example, a .CRL file may")
	p("be successfully generated before the crash.\nIf something like")
	p("this happens on")
	p("your system, you must a) DISABLE warm-boot suppression to insure")
	p("clean command termination, and b) don't use the -n CLINK option")
	p("when the target system cannot handle warm-boot suppression.")
	p("\nDo you want warm-boot suppression? ");

	wboote = !yesp();
}

dopstrip()
{
	p("PARITY BIT CONTROL:\n")
	p("This option deals with the handling of parity bits (the high-order")
	p("bit of ASCII-encoded text characters) by the compiler during")
	p("compilation. Normally, CC strips (forces to zero) the parity bits")
	p("from C source input files.")
	p("The only case where this might be undesireable is when a")
	p("special character set, utilizing the high-order bit as part of")
	p("the character representation, is being used. Bilingual or")
	p("extended character sets, for example, may use the parity bit in")
	p("this way. If this is the case in your situation, then do not")
	p("enable parity-bit stripping. Otherwise, you should let")
	p("the parity bits be stripped, so that the compiler will not be")
	p("confused by source files produced under certain text editors")
	p("that use the parity bit for formatting information.\n")

	p("Do you wish to let parity bits be stripped? ")
	pstrip = yesp();
}

donouser()
{
	p("USER-AREA SWITCHING CONTROL:\n")
	p("Normally CC and CLINK expect to be running on a CP/M")
	p("(or CP/M-like) system supporting \"user areas\" (the subdivision")
	p("of disk drive directories into 32 partitions numbered 0-31.)")
	p("The upshot is that specific user areas may be directly addressed")
	p("by CC and CLINK during the course of their operations, thus")
	p("possibly creating a conflict between themselves and certain")
	p("third-party command processors (MicroShell, ZCPR3, etc.) that")
	p("maintain an automatic search path mechanism for data files. If")
	p("you are running such a utility on your system and you notice")
	p("that files aren't being correctly located by CC and CLINK, try")
	p("disabling user-area switching with this option. The effect will")
	p("be that CC and CLINK will no longer perform any user-area")
	p("operations at all, allowing your own command processor to")
	p("determine the default user areas for file operations.\n")
	p("If your system does not support user areas at all, then you")
	p("definitely want to disable user-area switching here.\n")
	p("\n(Note: In order to disable user-area switching in C-generated")
	p("COM files, it is necessary to customize the run-time package")
	p("by changing the value of the NOUSER symbol in CCC.ASM.)\n")
	p("\nDo you wish to disable user-area switching? ")
	nouser = yesp();
}


dowerrs()
{
	p("RED EDITOR ERROR FILE CONTROL:\n")
	p("CC can write out an error file containing information about the")
	p("location and nature of source file errors detected during")
	p("the course of an unsuccessful compilation. The RED text editor")
	p("recognizes this file and makes the editing of those errors very")
	p("convenient. If you wish, you can have CC automatically write out")
	p("such an error file whenever source file errors are detected. If")
	p("you choose not to have CC write the file out automatically every")
	p("time, you may still choose to have the file written during")
	p("individual compilations through use of the CC command-line")
	p("option \"-w\".\n")
	p("Do you wish to have the RED error file written out automatically")
	p("every time compilation errors are detected? ")
	werrs = yesp();
}

docdbrst()
{
	p("CDB RESTART VECTOR SELECTION:\n")
	p("The CDB Debugger allows interactive debugging of C programs")
	p("through the use of an interrupt vector down in low system")
	p("memory, just as DDT or SID uses restart 7. As distributed,")
	p("CDB is compiled to use RST 6 for this purpose, and the compiler")
	p("correspondingly presumes a default of -k6 when the -k option is")
	p("given without an argument. If you wish to change the restart")
	p("vector used by CDB, then you must recompile CDB according to the")
	p("CDB documentation to change its default restart location.\nBy")
	p("choosing a new restart vector value HERE, you are only telling")
	p("CC.COM what the new default is, so that you don't have to bother")
	p("specifying it when using the -k option on the CC command line.\n")

	p("Enter the restart vector (1-7) you wish to have CC use as the")
	p("default -k argument: ")

	if (isdigit(igsp(gets0(strbuf))))
		cdbrst = atoi(strbuf);
	else
		p("Value left unchanged.\n")
}
