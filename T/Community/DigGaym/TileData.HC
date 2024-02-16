#ifndef TILEDATA_HC
#define TILEDATA_HC

#include "Tile"
#include "Item"
#include "ExtraTiles"

Tile TILES[TILE_TOTAL] = {
  {NULL, {NULL,NULL,NULL,NULL}, ITEM_NONE, 0, 0, 0},
  {&tHardEarth, {NULL,NULL,NULL,NULL}, ITEM_NONE, 1, 32, 0},
  {&tNoHook, {NULL,NULL,NULL,NULL}, ITEM_NONE, 33, 32, 0},
  {&tEarth1, {&tEarth1,&tEarth2,&tEarth3,&tEarth4}, ITEM_NONE, 9, 32, 0},
  {&tGrass, {&tGrass,&tEarth2,&tEarth3,&tEarth4}, ITEM_NONE, 9, 32, 0},
  {&tRock1, {&tRock1,&tRock2,&tRock3,&tRock4}, ITEM_ORE_ROCK, 9, 32, 100},
  {&tSilver1, {&tSilver1,&tSilver2,&tSilver3,&tSilver4}, ITEM_ORE_SILVER, 9, 32, 100},
  {&tGold1, {&tGold1,&tGold2,&tGold3,&tGold4}, ITEM_ORE_GOLD, 9, 32, 100},
  {&tUranium1, {&tUranium1,&tUranium2,&tUranium3,&tUranium4}, ITEM_ORE_URANIUM, 9, 32, 100},
  {&tLadder, {&tLadder,&tLadder,&tLadder,&tLadder}, ITEM_LADDER, 24, 32, 100},
  {&tSpikesU, {NULL,NULL,NULL,NULL}, ITEM_NONE, 4, 0, 0},
  {&tSpikesD, {NULL,NULL,NULL,NULL}, ITEM_NONE, 4, 0, 0},
  {&tSpikesL, {NULL,NULL,NULL,NULL}, ITEM_NONE, 4, 0, 0},
  {&tSpikesR, {NULL,NULL,NULL,NULL}, ITEM_NONE, 4, 0, 0},
  {&tDoorTL, {NULL,NULL,NULL,NULL}, ITEM_NONE, 2, 0, 0},
  {&tDoorTR, {NULL,NULL,NULL,NULL}, ITEM_NONE, 2, 0, 0},
  {&tDoorML, {NULL,NULL,NULL,NULL}, ITEM_NONE, 2, 0, 0},
  {&tDoorMR, {NULL,NULL,NULL,NULL}, ITEM_NONE, 2, 0, 0},
  {&tDoorBL, {NULL,NULL,NULL,NULL}, ITEM_NONE, 2, 0, 0},
  {&tDoorBR, {NULL,NULL,NULL,NULL}, ITEM_NONE, 2, 0, 0},
  {&tShop1, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop2, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop3, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop4, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop5, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop6, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop7, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop8, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop9, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop10, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop11, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop12, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop13, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop14, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop15, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop16, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop17, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop18, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop19, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop20, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop21, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop22, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tShop23, {NULL,NULL,NULL,NULL}, ITEM_NONE, 128, 0, 0},
  {&tCooler1, {NULL,NULL,NULL,NULL}, ITEM_COOLER, 8, 32, 100},
  {&tRockBlock1, {&tRockBlock1,&tRockBlock2,&tRockBlock3,&tRockBlock4}, ITEM_ORE_ROCK, 9, 32, 100},
  {&tSilverBlock1, {&tSilverBlock1,&tSilverBlock2,&tSilverBlock3,&tSilverBlock4}, ITEM_ORE_SILVER, 9, 32, 100},
  {&tGoldBlock1, {&tGoldBlock1,&tGoldBlock2,&tGoldBlock3,&tGoldBlock4}, ITEM_ORE_GOLD, 9, 32, 100},
  {&tUraniumBlock1, {&tUraniumBlock1,&tUraniumBlock2,&tUraniumBlock3,&tUraniumBlock4}, ITEM_ORE_URANIUM, 9, 32, 100},
};

#endif