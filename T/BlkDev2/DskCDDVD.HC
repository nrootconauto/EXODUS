Bool ISOInit(CDrv *dv,I64 blk)
{
  CBlkDev *bd=dv->bd;
  I64 spc=bd->blk_size>>BLK_SIZE_BITS,i=blk/spc,drv_offset=0;
  CISOPriDesc *iso=MAlloc(bd->blk_size);
  CISODirEntry *de;
  Bool unlock,res=FALSE;
  U8 buf[8];

  try {
    unlock=DrvLock(dv);
    dv->fs_type=FSt_ISO9660;
    dv->spc=spc;
    dv->data_area=dv->root_clus=dv->drv_offset=bd->drv_offset=dv->size=0;
    while (TRUE) {
      dv->size=MaxI64(dv->size,(i+1)*spc);
      BlkRead(dv,iso,i*spc,spc);
      buf[0](U32)=iso->id[0](U32);
      buf[4](U16)=iso->id[4](U8);
      switch (LstMatch(buf,"CD001\0CDW02\0BEA01\0BOOT2\0NSR02\0NSR03\0TEA01\0",
	    LMF_EXACT)) {
	case 0:
	  switch (iso->type) {
	    case ISOT_BOOT_RECORD:
	      drv_offset+=(2*DVD_BLK_SIZE+DVD_BLK_SIZE)/BLK_SIZE;
	      break;
	    case ISOT_SUPPLEMENTARY_DESC:
	      de=&iso->root_dir_record;
	      dv->size=iso->vol_space_size.little*bd->blk_size>>BLK_SIZE_BITS;
	      if (!StrCmp(iso->publisher_id,"TempleOS RedSea")) {
		dv->fs_type=FSt_REDSEA;
		bd->drv_offset=dv->drv_offset=19<<2+drv_offset;
		bd->max_blk=dv->size-1;
		dv->size-=bd->drv_offset;
		RedSeaInit(dv);
	      } else
		dv->root_clus=de->loc.little;
	      res=TRUE;
	      goto di_done;
	    case ISOT_TERMINATOR:
	      throw('Drv');
	  }
	  break;
	default: //Its normal for ISO3346 to read NULL blk as terminator
	  PrintErr("File System Not Supported\n");
	  throw('Drv');
      }
      i++;
    }
di_done:
    Free(iso);
    if (unlock)
      DrvUnlock(dv);
  } catch {
    dv->fs_type=FSt_ISO9660;
    dv->spc=spc;
    dv->drv_offset=bd->drv_offset=dv->data_area=dv->root_clus=0;
    Free(iso);
    if (unlock)
      DrvUnlock(dv);
  }
  return res;
}

U0 DVDImageRead(U8 dvd_drv_let,U8 *out_name)
{}

class CDualBuf
{
  U8 *buf0,*buf1;
  I64 in_buf,out_buf,cnt;
  U8 *filename;
  CBlkDev *dvd_bd;
};

U0 DVDImageWriteTask(CDualBuf *d)
{
}

U0 DVDImageWrite(U8 dvd_drv_let,U8 *in_name=NULL,I64 media_type=MT_DVD)
{}
