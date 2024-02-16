Bool BootDVDProbe(CBlkDev *bd)
{
}

Bool BootDVDProbeAll(CBlkDev *bd)
{
}

U0 ATARepEntry(I64 base0,I64 base1,I64 unit,U8 *msg,
	CATARep **_head,I64 *num_hints)
{
}

Bool ATARepExitAllApplications()
{
}

public I64 ATARep(Bool pmt=TRUE,Bool just_ide=FALSE,CATARep **_head=NULL)
{//Report possible ATA devices by probing.  Hard disks and CD/DVDs.
}

CATARep *ATARepFind(CATARep *haystack_head,I64 needle_num)
{
}

CATARep *ATAIDDrvs(CATARep *head,CATARep **_ata_drv,CATARep **_atapi_drv)
{
}

CBlkDev *ATAMount(U8 first_drv_let,I64 type,I64 base0,I64 base1,I64 unit)
{
}

I64 MountIDEAuto()
{
}
