#help_index "Install;File/Cmd Line (Typically);Cmd Line (Typically);"
U8 Mount2(U8 boot_drv_let,CDoc *_doc,Bool _caller_is_prtdsk)
{//If _doc, called by $LK,"::/Kernel/KCfg.HC"$ else called by $LK,"Mount",A="MN:Mount"$().
  I64 cnt,total=0,num_hints,drv_let,type,unit,prt_num;
  U8 blks_buf[STR_LEN],addr_buf[STR_LEN],base0_buf[STR_LEN],base1_buf[STR_LEN],
	*filename=NULL,*filename2=NULL,res=0;
  Bool whole_drv,make_free;
  CDoc *doc;
  if (boot_drv_let)
    boot_drv_let=Let2Let(boot_drv_let);
  do {
    cnt=0;
    if (!_doc)
      DrvRep;
    "\n****** Mount Drives ******\n"
	  "$$GREEN$$A$$FG$$-$$GREEN$$B$$FG$$ are RAM drives.\n"
	  "$$GREEN$$C$$FG$$-$$GREEN$$L$$FG$$ are ATA hard drives.\n"
	  "$$GREEN$$M$$FG$$-$$GREEN$$P$$FG$$ are ISO file read drives.\n"
	  "$$GREEN$$Q$$FG$$-$$GREEN$$S$$FG$$ are ISO file write drives.\n"
	  "$$GREEN$$T$$FG$$-$$GREEN$$Z$$FG$$ are ATAPI CD/DVD drives.\n"
	  "\nDrive Letter ($$PURPLE$$<ENTER>$$FG$$ to exit):";
    drv_let=Let2Let(GetChar);
    '\n';
    if (type=Let2BlkDevType(drv_let)) {
      whole_drv=FALSE;
      if (_doc) { //Called by $LK,"::/Kernel/KCfg.HC"$
	doc=_doc;
	make_free=FALSE;
      } else { //Called by $LK,"Mount",A="MN:Mount"$()
	doc=DocNew;
	DocPrint(doc,"CBlkDev *bd;\n");
	make_free=TRUE;
      }
      unit=0;
      prt_num=I64_MIN;
      switch (type) {
	case BDT_RAM:
	  "Addr of RAM disk ($$PURPLE$$<ENTER>$$FG$$ to MAlloc):";
	  GetS(addr_buf,STR_LEN);
	case BDT_ISO_FILE_WRITE:
	  "Blks of 512 bytes:";
	  GetS(blks_buf,STR_LEN);
	  break;
	case BDT_ISO_FILE_READ:
	  filename=GetStr("File Name:");
	  break;
      }
      DocPrint(doc,"bd=BlkDevNextFreeSlot(\'%C\',%d);bd->unit=%d;\n",
	    drv_let,type,unit);
      switch (type) {
	case BDT_RAM:
	  if (!*addr_buf) StrCpy(addr_buf,"0");
	  DocPrint(doc,"bd->RAM_dsk=%s;\n",addr_buf);
	case BDT_ISO_FILE_WRITE:
	  if (!*blks_buf) StrCpy(blks_buf,"0");
	  DocPrint(doc,"bd->max_blk=(%s)-1;\n",blks_buf);
	  DocPrint(doc,"bd->drv_offset=19<<2+"
		"(DVD_BLK_SIZE*2+DVD_BOOT_LOADER_SIZE)/BLK_SIZE;\n");
	  break;
	case BDT_ISO_FILE_READ:
	  filename2=FileNameAbs(filename);
	  DocPrint(doc,"bd->file_dsk_name=AStrNew(\"%s\");\n",filename2);
	  DocPrint(doc,"bd->drv_offset=19<<2+"
		"(DVD_BLK_SIZE*2+DVD_BOOT_LOADER_SIZE)/BLK_SIZE;\n");
	  break;
      }
      DocPrint(doc,"BlkDevAdd(bd,%d,%d,%d);\n",prt_num,whole_drv,make_free);
      if (_doc) //Called by $LK,"::/Kernel/KCfg.HC"$
	cnt++;
      else { //Called by $LK,"Mount",A="MN:Mount"$()
	/*if ((cnt=ExeDoc(doc)) && whole_drv) {
	  if (_caller_is_prtdsk) {
	    res=drv_let;
	    DskPrt(drv_let,1.0); //First mount whole drive.
	  } else
	    DskPrt(drv_let);
	}
	DocDel(doc);*/
      }
    }
    total+=cnt;
  } while (cnt && !_caller_is_prtdsk ||
	!total && _doc); //At least 1 if Called by $LK,"::/Kernel/KCfg.HC"$
  Free(filename);
  Free(filename2);
  return res;
}


public U0 Unmount(U8 drv_let=0)
{//Unmount drive(s).
  BlkDevDel(Let2BlkDev(drv_let));
}

public U8 MountFile(U8 *filename,U8 drv_let='M')
{//Mount ISO.C file.
  U8 *filename2=ExtDft(filename,"ISO.C"),*filename3=FileNameAbs(filename2);
  CDrv *dv=DrvMakeFreeSlot(DrvNextFreeLet(drv_let)); //First $LK,"BDT_ISO_FILE_READ",A="MN:BDT_ISO_FILE_READ"$
  CBlkDev *bd=BlkDevNextFreeSlot(dv->drv_let,BDT_ISO_FILE_READ);
  bd->drv_offset=19<<2+(DVD_BLK_SIZE*2+DVD_BOOT_LOADER_SIZE)/BLK_SIZE;
  bd->file_dsk_name=AStrNew(filename3);
  BlkDevAdd(bd,,TRUE,TRUE);
  Free(filename3);
  Free(filename2);
  return dv->drv_let;
}
