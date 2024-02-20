==========================================================
BDS C Compiler/Linker Retail Distributions and Source Code
==========================================================

           Released 9/19/2002
           Updated 9/27/2002

           Leor Zolman (leor@bdsoft.com)
           BD Software (www.bdsoft.com)

This archive contains the last generation retail distributions of BDS C
for both "vanilla" CP/M-80 and ZCPR3, and the full corresponding source
code (in LASM 8080 assembler format) of the major executable commands in
the package: cc, cc2, and clink. I hope to add clib source when I can
locate it.

CFX.ZIP is a DOS version of a utility to uncompress LBR files, so you can
check out the contents of the several LBR's in the package without having
to do so under an 8-bit OS.

The cc, cc2 and clink source code is the heart of BDS C. These are the
only pieces of the package I ever treated as "proprietary"; everything
else was free to be copied so that users could legally modify and
exchange any run-time aspects of their software. Now these source files,
too, join the rest of the package.

Here's the official word:

        "I, Leor Zolman, hereby release all rights to BDS C
    (all binary and source code modules, including compiler,
    linker, library sources, utilities, and all documentation)
    into the Public Domain.  Anyone is free to download, use,
    copy, modify, sell, fold, spindle or mutilate any part of
    this package forever more. If, however, anyone ever
    translates it to BASIC, FORTRAN or C#, *please* do not tell
    me."  
            Leor Zolman
            9/20/2002


==========
Change Log
==========

10/06/2002
    Expanded version of the User's Guide posted for separate download
    on the web site. This version includes full-color scans of the 
    original "C Tree" binder cover and blue graphical title page. 

9/28/2002
    User's Guide PDF updated (courtesy of Fritz Chwolka) with the Table
    of Contents now in front, and some hyperlinks added.

9/27/2002
    Removed the "manual" directory and its contents (User's Guide
    source code), and added a fresh PDF of the (mostly) properly
    formatted User's Guide into the top-level directory.

9/26/2002
    Converted a few documents in the "manual" directory from WordPerfect 5
    to Word 97 format, updated the README.txt there to mention availability
    of the PDF versions of the User's Guide on the BD Software web site.

9/22/2002
    Added some historical notes to this README file pertaining to the
    library and run-time performance.

9/21/2002 (am)
    Finally REALLY added the CLINK sources to the sources directory and
    the separate source archive

9/20/2002 (pm)
    Added original "retail" distributions to the downloadable archive.

9/20/2002 (am)
    Added missing CLINK source (oops)
    Fixed some corrupted text at top of ccb.asm (thanks to
        Russell Marks for bringing this to my attention.)


9/19/2002
    Initial Release


===========
Directories
===========

bdsc160:    Files specific to the CP/M-80 distribution

bdsz20:     Files specific to the ZCPR3 distribution

extra:      Files common to both of the above distributions

source:     The compiler/linker source code along with another Readme
            file with info about those sources and my original
            development environment.


================
Historical Notes
================

The first version of BDS C was CP/M-80 only, written on my 2 MHz
IMSAI 8080 system between January, 1979 and August, 1979 (see the README.txt
file in the "sources" directory for more info on the development system).

Following the initial release of v1.0 in late August through Lifeboat
Associates in New York, BDS C quickly evolved based on user feedback until
reaching relative stability with v1.46 circa 1981. Lifeboat was none too
pleased with my rate of updates (every couple of months), because they
had to make multi-disk distribution masters in a zillion different incompatible
CP/M formats each time. In fact, I'd hear about how they hadn't had a chance
to create all the masters before I came out with yet another update...

The Library
-----------

One of my biggest blunders was basing my file I/O library on a completely
non-standard library implementation that was in use on the PDP-11/70 version 7
Unix system at the MIT Lab for Computer Science where I was on staff (Real-Time
Systems Group, just renamed from DSSR--"Domain Specific Systems Research",
directed by Professor Steve Ward). The problem was, I didn't *know* it was
non-standard; I thought that was the "new" C library, and faithfully replicated
it for BDS C. As it turns out, it was actually some obsolete, low-level library
that should never have been in use. By the time I realized this mistake, there
had been many copies of BDS C sold and I didn't want to release a new library
that would break all the existing code. That was another blunder; I should
have moved to the standard File I/O style as soon as possible. Eventually,
for BDS C v1.6, I did provide a standard library, but by then BDS C was pretty
much near the end of its useful lifetime.


Run-Time Performance
--------------------

Much has been written about how I achieved fast compilation speed, and it is
mostly accurate. Here are some tidbits relating to BDS C's code generation
that aren't as well known (if at all):

To simplify the linking process, I eliminated the need for link-time
"fixup" processing. For data, I treated all external data as one big
FORTRAN-like "common" block (eliminating data fixups), so that each
compilation unit would "see" global data addresses the same way. For
function addresses, I put a bunch of "jump vectors" at the front of each
function, one for each other function called, and had each function call
the other functions indirectly through its own jump vector table. Of
course, this had both spacial and temporal cost. Scott Layson (now Scott
Burson) of Mark of the Unicorn wrote the L2 linker which analyzed the jump
vector tables and totally eliminated them by identifying the indirect
calls and turning them into direct calls. Also, L2 was able to link
executables larger than the available data space at link time. If I'd have
thought of those optimizations myself, I would have just had CLINK do them
in the first place!

In v1.4x, I shortened code size significantly by identifying several
commonly recurring sequences of instructions (such as fetching data off
the local stack, performing 16-bit indirect fetches, etc.) and assigned
them "restart vectors" so they could be invoked via single-byte RST
instructions. This, the default scheme, optimized for size. Using the -o
option optimized for speed by simply not using the restart vectors and
generating the code inline instead. Compiling functions separately allowed
tuning the type of optimization desired for each function, speed or space.

Now, there's one trick I didn't think of that probably cost me the performance
crown vs. Whitesmith's C: I used the 8080's "BC" register pair as a "frame
pointer"; all local data was accessed relative to BC. That meant that

    a) I had to set up BC upon entry to each function
    b) I had to save and restore it as part of function call protocol
    c) I did NOT have BC for use as a "register" variable, thus I had no
        "register" registers at all (HL and DE were needed for other things).

Bad decision. Here's where a little compiler design education would've come
in handy. As I understand it, what Bill Plauger did in Whitesmith's was to
just use SP (the normal stack pointer) as the base pointer, by keeping
track during compilation of how many things were pushed on it, and
offsetting local addresses accordingly. ARGHHH! How sweet and simple, and
I never thought of it.  I'm certain that, with all my other kewl
optimizations, if I had just done that, and thus had been able to free up
BC for use with "register" variables), I could have come ahead of
Whitesmith's in run-time performance (though by nowhere the kind of margin
enjoyed by BDS C's compilation speed advantage.)

