#help_index "Graphics/Scrn"

U0 CtrlAltZ(I64 sc)
{
  if (sc&SCF_SHIFT)
    GrScaleZoom(0.5);
  else
    GrScaleZoom(2.0);
}
