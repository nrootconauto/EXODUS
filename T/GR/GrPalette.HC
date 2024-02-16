#help_index "Graphics/Color"
public U8 gr_rainbow_10[10]={
  BLACK,BROWN,RED,LTRED,YELLOW,GREEN,BLUE,PURPLE,LTGRAY,WHITE};

DefineLstLoad("ST_RAINBOW_10",
  "BLACK\0BROWN\0RED\0LTRED\0YELLOW\0GREEN\0BLUE\0PURPLE\0LTGRAY\0WHITE\0");

U0 GrPaletteIndicesSet()
{//There is a level of indirection that we identity map.
// Set 16-colors to use first 16 DAC BGR entries, so we
// never need to worry about indexes, just DAC palette settings.
  I64 i;
}

public CBGR48 gr_palette_std[COLORS_NUM]={
0x000000000000,0x00000000AAAA,0x0000AAAA0000,0x0000AAAAAAAA,
0xAAAA00000000,0xAAAA0000AAAA,0xAAAA55550000,0xAAAAAAAAAAAA,
0x555555555555,0x55555555FFFF,0x5555FFFF5555,0x5555FFFFFFFF,
0xFFFF55555555,0xFFFF5555FFFF,0xFFFFFFFF5555,0xFFFFFFFFFFFF};

public CBGR48 gr_palette_gray[COLORS_NUM]={
0x000000000000,0x111111111111,0x222222222222,0x333333333333,
0x444444444444,0x555555555555,0x666666666666,0x777777777777,
0x888888888888,0x999999999999,0xAAAAAAAAAAAA,0xBBBBBBBBBBBB,
0xCCCCCCCCCCCC,0xDDDDDDDDDDDD,0xEEEEEEEEEEEE,0xFFFFFFFFFFFF};

CBGR48 pal[16];

CBGR48 GrPaletteColorGet(I64 i)  {
	return pal[i];
}

public U0 GrPaletteGet(CBGR48 *bgr48)
{//16 colors
  I64 i;
  for (i=0;i<COLORS_NUM;i++)
    bgr48[i]=GrPaletteColorGet(i);
}

public U0 GrPaletteSet(CBGR48 *bgr48)
{//16 colors
  I64 i;
  for (i=0;i<COLORS_NUM;i++) {
    pal[i]=bgr48[i];
    _GrPaletteColorSet(i,bgr48[i]);
  }
}

public U0 GrPaletteColorSet(I64 color,CBGR48 bgr48)
{//16 colors
  pal[color]=bgr48;
  _GrPaletteColorSet(color,bgr48);
}


public U0 PaletteSetStd()
{//Activate std palette.
  GrPaletteSet(gr_palette_std);
}
