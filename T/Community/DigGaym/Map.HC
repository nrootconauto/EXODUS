#ifndef MAP_HC
#define MAP_HC

#include "TileData.HC"

#define TFLAG_NONE    0
#define TFLAG_BLOCK   1
#define TFLAG_END     2
#define TFLAG_KILL    4
#define TFLAG_MINABLE 8
#define TFLAG_LADDER  16
#define TFLAG_NOHOOK  32
#define TFLAG_NA      64
#define TFLAG_SHOP    128


class Map {
  U32 widthPx;
  U32 heightPx;
  U32 width;
  U32 height;
  PxData **px;
  U8 *flags;
  U8 *tileType;
  U8 *hp;
  CD2I32 spawn;
};

#define LIN_CONGRUE_A 6364136223846793005
#define LIN_CONGRUE_C 1442695040888963407
I64 RandF(I64 seed) {
  return LIN_CONGRUE_A*seed^(seed&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
}

U8 MapGenTiles[21] = {
TILE_URANIUM1,
TILE_URANIUM1,
TILE_URANIUM1,
TILE_EARTH1,
TILE_GOLD1,
TILE_EARTH1,
TILE_SILVER1,
TILE_EARTH1,
TILE_ROCK1,
TILE_EARTH1,
TILE_NULL,
TILE_NULL,
TILE_EARTH1,
TILE_EARTH1,
TILE_ROCK1,
TILE_EARTH1,
TILE_SILVER1,
TILE_EARTH1,
TILE_URANIUM1,
TILE_URANIUM1,
TILE_URANIUM1,
};

U0 SetTile(Map *dest, I64 ti, U8 ttype) {
  dest->px[ti] = TILES[ttype].px;
  dest->flags[ti] = TILES[ttype].flags;
  dest->tileType[ti] = ttype;
  dest->hp[ti] = TILES[ttype].hp;
}

U0 LoadMap(Map *dest, MapTemplate *src, U8 *noise) {
  dest->width = src->width;
  dest->height = src->height + 1024;
  dest->widthPx = dest->width*16;
  dest->heightPx = dest->height*16;
  dest->spawn.x = src->spawn.x;
  dest->spawn.y = src->spawn.y;
  I64 cntSrc = src->width * src->height;
  I64 cntDest = dest->width * dest->height;
  Free(dest->px);
  Free(dest->flags);
  Free(dest->tileType);
  Free(dest->hp);
  dest->px = MAlloc(cntDest*sizeof(PxData*));
  dest->flags = MAlloc(cntDest*sizeof(U8));
  dest->tileType = MAlloc(cntDest*sizeof(U8));
  dest->hp = MAlloc(cntDest*sizeof(U8));
  MemCpy(dest->px, src->px, cntSrc*sizeof(PxData*));
  MemCpy(dest->flags, src->flags, cntSrc);
  MemCpy(dest->tileType, src->tileType, cntSrc);
  MemCpy(dest->hp, src->hp, cntSrc);

  U32 rx, ry;
  /* Generate Random Tiles */
  for (ry=src->height; ry<dest->height; ry++) {
    for (rx=0; rx<dest->width; rx++) {
      I64 ni = rx%640+ry%640*640;
      I64 nv = noise[ni];
      I64 ttype = MapGenTiles[nv];
      I64 i = ry*dest->width + rx;

      dest->px[i] = TILES[ttype].px;
      dest->flags[i] = TILES[ttype].flags;
      dest->tileType[i] = ttype;
      dest->hp[i] = TILES[ttype].hp;
    }
  }
  /* Generate Terrian Features (caves and stuff) */
}

#endif
