#ifndef ITEM_HC
#define ITEM_HC

#include "Tile"
#include "Vector"
#include "PxBlot"
/*
#include "Px/Rock"
#include "Px/Gold"
#include "Px/Silver"
#include "Px/Uranium"
#include "Px/UsePickaxe"
#include "Px/Gun"
#include "Px/GunInv"
#include "Px/GrappleGun"
#include "Px/GrappleGunInv"
#include "Px/GrappleGunHook"
#include "Px/GrappleGunHookInv"
#include "Px/ItemGrenade"
*/
#define ITEM_NONE -1
#define ITEM_PICKAXE 0
#define ITEM_LADDER 1
#define ITEM_ORE_ROCK 2
#define ITEM_ORE_SILVER 3
#define ITEM_ORE_GOLD 4
#define ITEM_ORE_URANIUM 5
#define ITEM_COOLER 6
#define ITEM_GUN 7
#define ITEM_GRENADE 8
#define ITEM_GRAPPLE_GUN 9
#define ITEM_TOTAL 10

#define INV_SIZE 16

class ItemData {
  U8 *name;
  PxData *px;
  PxData *pxInv;
  U16 price;
  U16 weight;
  U16 stackSize;
  U16 placeTile;
  CD2I32 equipOffset;
  U8 equipBlotStyle;
};

class ItemDrop {
  PxData *px;
  CD2 pos;
  CD2 vel;
  F64 ttl;
  I32 qty;
  U8 type;
};

class ItemInv {
  I32 id;
  I32 qty;
};

class Inventory {
  ItemInv items[INV_SIZE];
};

ItemData gItems[ITEM_TOTAL] = {
  {"PICKAXE", &UsePickaxe, &UsePickaxe, 100, 100, 1, TILE_NULL, {4,17}, BLOT_BL},
  {"LADDER", &tLadder, &tLadder, 100, 10, 64, TILE_LADDER, {4,17}, BLOT_CL},
  {"ROCK", &Rock, &Rock, 100, 10, 64, TILE_ROCKBLOCK1, {4,17}, BLOT_CL},
  {"SILVER ORE", &Silver, &Silver, 100, 10, 64, TILE_SILVERBLOCK1, {4,17}, BLOT_CL},
  {"GOLD ORE", &Gold, &Gold, 100, 10, 64, TILE_GOLDBLOCK1, {4,17}, BLOT_CL},
  {"URANIUM ORE", &Uranium, &Uranium, 100, 10, 64, TILE_URANIUMBLOCK1, {4,17}, BLOT_CL},
  {"COOLER", &tCooler1, &tCooler1, 100, 10, 64, TILE_COOLER1, {4,17}, BLOT_CL},
  {"GUN", &Gun, &GunInv, 100, 10, 1, TILE_NULL, {0,17}, BLOT_CL},
  {"GRENADE", &ItemGrenade, &ItemGrenade, 100, 10, 64, TILE_NULL, {0,17}, BLOT_CL},
  {"GRAPPLE GUN", &GrappleGun, &GrappleGunInv, 100, 10, 1, TILE_NULL, {0,17}, BLOT_CL},
};

U0 ItemAdd(Vector* vec, U8 type, I32 qty, F64 x, F64 y, F64 velX, F64 velY) {
  ItemDrop item;
  item.px = gItems[type].px;
  item.pos.x = x;
  item.pos.y = y;
  item.vel.x = velX;
  item.vel.y = velY;
  item.ttl = 60;
  item.qty = qty;
  item.type = type;
  VectorAdd(vec, &item);
}

U0 InvInit(Inventory *inv) {
  I64 i;
  for (i=0; i<INV_SIZE; i++) {
    inv->items[i].id = ITEM_NONE;
    inv->items[i].qty = 0;
  }
}

I32 InvGetFreeSlot(Inventory *inv) {
  I64 i;
  I32 res = -1;
  for (i=0; i<INV_SIZE; i++) {
    if (inv->items[i].id == ITEM_NONE)
      return i;
  }
  return res;
}

I32 InvGetItem(Inventory *inv, I32 id) {
  I32 i;
  for (i=0; i<INV_SIZE; i++) {
    if (inv->items[i].id == id)
      return i;
  }
  return -1;
}

I32 InvAddCheck(Inventory *inv, I32 id, I32 qty) {
  I64 i;
  // Merge
  for (i=0; i<INV_SIZE && qty > 0; i++) {
    if (inv->items[i].id == id && inv->items[i].qty < gItems[id].stackSize) {
      I32 newSize = inv->items[i].qty + qty;
      qty = newSize - gItems[id].stackSize;
      if (newSize > gItems[id].stackSize)
        newSize -= qty;
    }
  }

  if (qty <= 0)
    return 0;

  for (i=0; i<INV_SIZE; i++) {
    if (inv->items[i].id == ITEM_NONE)
      return 0;
  }

  return qty;
}

I32 InvAdd(Inventory *inv, I32 id, I32 qty) {
  I64 i;
  // Merge
  for (i=0; i<INV_SIZE && qty > 0; i++) {
    if (inv->items[i].id == id && inv->items[i].qty < gItems[id].stackSize) {
      I32 newSize = inv->items[i].qty + qty;
      qty = newSize - gItems[id].stackSize;
      if (newSize > gItems[id].stackSize)
        newSize -= qty;
      inv->items[i].qty = newSize;
    }
  }

  if (qty <= 0)
    return 0;

  for (i=0; i<INV_SIZE; i++) {
    if (inv->items[i].id == ITEM_NONE) {
      inv->items[i].id = id;
      inv->items[i].qty = qty;
      return 0;
    }
  }

  return qty;
}

U0 InvRemFromSlot(Inventory *inv, I32 slot, I32 qty) {
  inv->items[slot].qty -= qty;
  if (inv->items[slot].qty <= 0)
    inv->items[slot].id = -1;
}

#endif