#ifndef TILE_HC
#define TILE_HC

#define TILE_NULL 0
#define TILE_HARDEARTH 1
#define TILE_NOHOOK 2
#define TILE_EARTH1 3
#define TILE_GRASS 4
#define TILE_ROCK1 5
#define TILE_SILVER1 6
#define TILE_GOLD1 7
#define TILE_URANIUM1 8
#define TILE_LADDER 9
#define TILE_SPIKESU 10
#define TILE_SPIKESD 11
#define TILE_SPIKESL 12
#define TILE_SPIKESR 13
#define TILE_DOORTL 14
#define TILE_DOORTR 15
#define TILE_DOORML 16
#define TILE_DOORMR 17
#define TILE_DOORBL 18
#define TILE_DOORBR 19
#define TILE_SHOP1 20
#define TILE_SHOP2 21
#define TILE_SHOP3 22
#define TILE_SHOP4 23
#define TILE_SHOP5 24
#define TILE_SHOP6 25
#define TILE_SHOP7 26
#define TILE_SHOP8 27
#define TILE_SHOP9 28
#define TILE_SHOP10 29
#define TILE_SHOP11 30
#define TILE_SHOP12 31
#define TILE_SHOP13 32
#define TILE_SHOP14 33
#define TILE_SHOP15 34
#define TILE_SHOP16 35
#define TILE_SHOP17 36
#define TILE_SHOP18 37
#define TILE_SHOP19 38
#define TILE_SHOP20 39
#define TILE_SHOP21 40
#define TILE_SHOP22 41
#define TILE_SHOP23 42
#define TILE_COOLER1 43
#define TILE_ROCKBLOCK1 44
#define TILE_SILVERBLOCK1 45
#define TILE_GOLDBLOCK1 46
#define TILE_URANIUMBLOCK1 47
#define TILE_TOTAL 48
/*
#include "Px/tHardEarth"
#include "Px/tNoHook"
#include "Px/tEarth1"
#include "Px/tGrass"
#include "Px/tRock1"
#include "Px/tSilver1"
#include "Px/tGold1"
#include "Px/tUranium1"
#include "Px/tLadder"
#include "Px/tSpikesU"
#include "Px/tSpikesD"
#include "Px/tSpikesL"
#include "Px/tSpikesR"
#include "Px/tDoorTL"
#include "Px/tDoorTR"
#include "Px/tDoorML"
#include "Px/tDoorMR"
#include "Px/tDoorBL"
#include "Px/tDoorBR"
#include "Px/tShop1"
#include "Px/tShop2"
#include "Px/tShop3"
#include "Px/tShop4"
#include "Px/tShop5"
#include "Px/tShop6"
#include "Px/tShop7"
#include "Px/tShop8"
#include "Px/tShop9"
#include "Px/tShop10"
#include "Px/tShop11"
#include "Px/tShop12"
#include "Px/tShop13"
#include "Px/tShop14"
#include "Px/tShop15"
#include "Px/tShop16"
#include "Px/tShop17"
#include "Px/tShop18"
#include "Px/tShop19"
#include "Px/tShop20"
#include "Px/tShop21"
#include "Px/tShop22"
#include "Px/tShop23"
#include "Px/tCooler1"
#include "Px/tRockBlock1"
#include "Px/tSilverBlock1"
#include "Px/tGoldBlock1"
#include "Px/tUraniumBlock1"
*/
class Tile {
  U8 *px;
  PxData *dmgPx[4];
  I16 drop;
  U8 flags;
  U8 hp;
  U8 dropChance
};

#endif