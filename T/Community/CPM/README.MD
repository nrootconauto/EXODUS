# Welcome to the SEXIEST 8080 Emulator 

This 8080 emulator is pretty epic,It doesn't Z80 type stuff,but if you
love 8080's,you've come to the right place This Emulator targets CP/M(aka
Control Program and Monitor). It basically gives you are command prompt 
and a BIOS and BDOS for your programs to rock out with.

## Where to start

Thanks to Leor Zolman from BD Software(See README.txt in A/0),I packaged 
this emulator with an *ancient* C Compiler. Because it's old,your going 
to need to read the manual (`bdsc-guide.pdf`) that is included with this
bodacious peice of software. More on this later.

I even wrote a legendary text editor called `POOP.COM`. `.COM` files are
binary nuggets that get loaded into memory for your own nefarious purposes.
Use the arrow-keys to walk around the screen,or use Ctrl+`WASD` to move 
around too(Not all CP/M machines had arrow keys). I still have work to do
on `POOP.COM`,so dont put top priority text files into it yet. It's secret
source code is in `POOP.C`. You can compile it like this
```cpm
CC.COM POOP.C
CLINK.COM POOP
```

**POOP.COM WILL MAKE BACKUPS OF YOUR WORK NAMED `fn.DDD` where `.DDD` is
 a number**

## Computing like a Profressional

This is top notch stuff for 1974,so you better dust off your books and 
learn from the pro's. At the heart of CP/M is the CCP(**Command Control
Processor**). This is where the cool stuff happens,it lets you type in 
commands and then it runs them. If you want to rename a file,do 

```cpm
REN new=old
```

Let's say you wrote a cool story in `POOP.COM`,you can type it out via 
```cpm
TYPE STORY.TXT
```

If you dont want anyone to steal your juicy plot points,you can erase the 
file via 

```cpm
ERA STORY.TXT
```

Thats epic. But let's say you are the lazy type and DO NOT like typing,
CP/M has you covered. **Put all of your commands in a `.SUB` file and type
it out to run the commands**

```cpm
--- CONTENTS OF COMMS.SUB
	CC.COM POOP.C
    CLINK.COM POOP
    POOP.COM
---
COMMS.SUB
``` 

This distrobution also comes with a `COPY.COM` program,it does what you
think it does

```cpm
COPY A.TXT B.TXT
```

## Directory layout in CP/M

If you aren't an orginized person,You will **LOVE** CP/M. There are 16 drives
`A-F`,(you will be able to add more drives when I feel like it). This distro comes 
with an `A` drive. In each drive,you can have up to 16 user directories.
(again i will implement `USER` when I get a minute or two,it will be an
easy fix). 

## Conclusion.

CP/M is sexy and I will write more CP/M shennanigins in the future,this is 
the first glimsh of the whats to come

If you want more sexy stuff,check out ![this cool site](http://www.z80.eu/adventures.html).

## Contributing.

If you want to be a total badass,you may want to help add `ANSI` escape codes
to ANSI.HC. Or maybe even help add `Z80` support. In the meanwhile,have fun.
