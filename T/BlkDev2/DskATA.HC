U0 ATABlkSel(CBlkDev *bd,I64 blk,I64 cnt)
{
}

Bool ATAWaitNotBUSY(CBlkDev *bd,F64 timeout)
{
}

Bool ATAWaitDRQ(CBlkDev *bd,F64 timeout)
{
}

Bool ATANop(CBlkDev *bd,F64 timeout)
{
}

U0 ATACmd(CBlkDev *bd,U8 cmd)
{
}

Bool ATAGetRes(CBlkDev *bd,F64 timeout,U8 *buf,I64 cnt,
		I64 _avail,Bool one_read)
{
}

Bool ATAPIWritePktWord(CBlkDev *bd,F64 timeout,...)
{
}

Bool ATAPISetMaxSpeed(CBlkDev *bd)
{
}

Bool ATAPISeek(CBlkDev *bd,I64 native_blk)
{
}

Bool ATAPIStartStop(CBlkDev *bd,F64 timeout,Bool start)
{
}

I64 ATAGetDevId(CBlkDev *bd,F64 timeout,Bool keep_id_record)
{
}

I64 ATAReadNativeMax(CBlkDev *bd,F64 timeout)
{//Returns zero on err
}

I64 ATAPIReadCapacity(CBlkDev *bd,I64 *_blk_size=NULL)
{//Supposedly this can return a res +/- 75 sects.
//Error might just be for music.
}

CATAPITrack *ATAPIReadTrackInfo(CBlkDev *bd,I64 blk)
{
}

Bool ATAInit(CBlkDev *bd)
{
}

Bool ATAPIWaitReady(CBlkDev *bd,F64 timeout)
{
}

U0 ATAReadBlks(CBlkDev *bd,U8 *buf, I64 blk, I64 cnt)
{
}

I64 ATAProbe(I64 base0,I64 base1,I64 unit)
{
}

Bool ATAPIReadBlks2(CBlkDev *bd,F64 timeout,U8 *buf,
		I64 native_blk, I64 cnt,Bool lock)
{
}

U0 ATAPIReadBlks(CBlkDev *bd,U8 *buf, I64 blk, I64 cnt)
{
}

Bool ATARBlks(CDrv *dv,U8 *buf, I64 blk, I64 cnt)
{
}

U0 ATAWriteBlks(CBlkDev *bd,U8 *buf, I64 blk, I64 cnt)
{
}

Bool ATAPISync(CBlkDev *bd)
{
}

U0 ATAPIClose(CBlkDev *bd,I64 close_field=0x200,I64 track=0)
{
}

U0 ATAPIWriteBlks(CBlkDev *bd,U8 *buf, I64 native_blk, I64 cnt)
{
}

Bool ATAWBlks(CDrv *dv,U8 *buf, I64 blk, I64 cnt)
{
}
