#ifndef MOB_HC
#define MOB_HC

#include "Animation"
#include "Collision"
#include "Vector"

#define STATE_STANDING 0
#define STATE_WALKING 1
#define STATE_JUMPING 2
#define STATE_FALLING 3
#define STATE_DEAD 4
#define STATE_DJUMP_CHARGE 5
#define STATE_DJUMP 6
#define STATE_CLIMB 7

#define MSTATE_IDLE 0
#define MSTATE_ATTACK 1

#define MFLAG_NONE 0
#define MFLAG_WALK_R 1
#define MFLAG_WALK_L 2
#define MFLAG_WALK_R_REM 254
#define MFLAG_WALK_L_REM 253


#define PFLAG_NONE        0
#define PFLAG_DJUMP_AVAIL 1
#define PFLAG_DJUMP_SPENT 2
#define PFLAG_FACE_LEFT   4
#define PFLAG_ALL         255

public class Player {
  CD2 pos;
  CD2I32 size;
  CD2 vel;
  F64 health;
  F64 shoot_ttl;
  F64 cooldown;
  F64 pxUseRot;
  F64 heat;
  F64 inv_ttl;
  PxData *pxUse;
  CD2I32 pxUseOffset;
  I32 pxUseX;
  U8 pxUseStyle;
  I32 selItemSlot;
  U32 money;
  U16 state;
  Bool dJumpAvail;
  Bool dJumpSpent;
  U8 flags;
  Anim anim;
  Inventory inv;
};

public class Mob {
  CD2 pos;
  CD2I32 size;
  CD2 vel;
  CD2I32 drawOffset;
  F64 health;
  F64 cooldown;
  Anim anim;
  U16 state;
  U8 flags;
};

public U0 NewPlayer(Player *mob, I64 x, I64 y) {
  mob->pos.x = x;
  mob->pos.y = y;
  mob->size.x = 16;
  mob->size.y = 32;
  mob->vel.x = 0.0;
  mob->vel.y = 0.0;
  mob->health = 100;
  mob->shoot_ttl = 2.0;
  mob->cooldown = 0;
  mob->pxUseRot = 0;
  mob->heat = 0;
  mob->inv_ttl = 0;
  mob->pxUse = NULL;
  mob->pxUseOffset.x = 0;
  mob->pxUseOffset.y = 0;
  mob->pxUseX = 0;
  mob->pxUseStyle = 0;
  mob->selItemSlot = 0;
  mob->money = 100000;
  mob->state = STATE_STANDING;
  SetAnimNManStand(&mob->anim);
  InvInit(&mob->inv);
  InvAdd(&mob->inv, ITEM_PICKAXE, 1);
  InvAdd(&mob->inv, ITEM_GUN, 1);
  InvAdd(&mob->inv, ITEM_GRENADE, 64);
  InvAdd(&mob->inv, ITEM_GRAPPLE_GUN, 1);
  mob->flags = PFLAG_NONE;
}

public U0 AddMob(Vector *mobs, Vector *cMobs, I64 x, I64 y) {
  Mob mob;
  mob.pos.x = x;
  mob.pos.y = y;
  mob.size.x = 32;
  mob.size.y = 22;
  mob.vel.x = 0.0;
  mob.vel.y = 0.0;
  mob.drawOffset.x = -17;
  mob.drawOffset.y = -9;
  mob.health = 10;
  SetAnim(&mob.anim, &BlobIdleAnim, NULL);
  mob.flags = PFLAG_NONE;
  VectorAdd(mobs, &mob);
  VectorSetLen(cMobs, mobs->len);
}

public U0 GenCMobs(Mob *mobs, I64 cnt, Vec4 *cMobs) {
  I64 i;
  for (i=0; i<cnt; i++) {
    cMobs[i].x1 = mobs[i].pos.x;
    cMobs[i].x2 = mobs[i].pos.x + mobs[i].size.x;
    cMobs[i].y1 = mobs[i].pos.y;
    cMobs[i].y2 = mobs[i].pos.y + mobs[i].size.y;
  }
}

public U0 UpdatePxUse(Player *mob) {
  I32 itemID = mob->inv.items[mob->selItemSlot].id;
  if (itemID >= 0) {
    mob->pxUse = gItems[itemID].px;
    mob->pxUseOffset.x = gItems[itemID].equipOffset.x;
    mob->pxUseOffset.y = gItems[itemID].equipOffset.y;
    mob->pxUseStyle = gItems[itemID].equipBlotStyle;
  } else {
    mob->pxUse = NULL;
  }
}

#endif
