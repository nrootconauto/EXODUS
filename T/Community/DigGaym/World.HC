#ifndef WORLD_HC
#define WORLD_HC

#ifdef DEBUG
  #include "CrunkComm"
#endif

/*
#include "Px/BlobGibLeft"
#include "Px/BlobGibRight"
#include "Px/BlobGibBottom"
#include "Px/BlobGibLeftWing"
#include "Px/BlobGibRightWing"
#include "Px/CarGibLeft"
#include "Px/CarGibRight"
#include "Px/CarGibBottom"
#include "Levels/Sandbox.HC"
#include "Levels/Level00.HC"
#include "Levels/Level01.HC"
#include "Levels/Level02.HC"
#include "Levels/Level03.HC"
#include "Levels/Level04.HC"
#include "Levels/Level05.HC"
#include "Levels/Level06.HC"
#include "Levels/Level07.HC"
#include "Levels/Level08.HC"
#include "Levels/Level09.HC"
#include "Levels/Level10.HC"
*/
#include "Mob"
#include "Vector"
#include "Sound"

#define SPAWNER_TTL 3
#define SPAWNER_W 64
#define SPAWNER_H 30
#define SPAWNER_HEALTH 50

#define LEVELS_TOTAL 11
MapTemplate *Levels[LEVELS_TOTAL] = {&Level00,&Level01,&Level02,&Level03,&Level04,&Level05,&Level06,&Level07,&Level08,&Level09,&Level10};

class Debris {
  CD2 pos;
  CD2 vel;
};

class Cooler {
  CD2I32 pos;
};

class Laser {
  CD2 pos;
  CD2 vel;
};

class Grapple {
  CD2 pos;
  CD2 vel;
  F64 length;
  Bool hooked;
  Bool active;
};

class Grenade {
  CD2 pos;
  CD2 vel;
  F64 rot;
  F64 ttl;
};

class Gib {
  PxData *px;
  CD2 pos;
  CD2 vel;
  F64 rot;
  F64 ttl;
};

class Spawner {
  CD2I32 pos;
//  CD2I32 size;
  F64 ttl;
  F64 health;
};

class Explosion {
  CD2I32 pos;
  F64 ttl;
};

class World {
  I64 currentLevel;
  Vector mobs;
  Vector items;
  Vector cMobs;
  Vector debris;
  Vector debrisEarth;
  Vector coolers;
  Vector lasers;
  Vector grenades;
  Vector explosions;
  Vector gibs;
  Vector spawners;
  Vector laserPixels;
  MapTemplate *activeLvl;
  Map level;
  Player player;
  I64 coins;
  Grapple grapple;
  CD2 cam;
  U0 (*ActiveInput)();
  U0 (*ActiveUpdate)(F64 delta);
  Bool quitGame;
  U8 levelStr[10];
};

U0 DebrisAddRand(Vector *vec, F64 x, F64 y, F64 vel, I64 cnt) {
  Debris newDebris;
  newDebris.pos.x = x;
  newDebris.pos.y = y;
  I64 i;
  F64 dir;
  for (i=0; i<cnt; i++) {
    dir = RandI64%pi;
    newDebris.vel.x = Cos(dir)*vel;
    newDebris.vel.y = Sin(dir)*vel;
    VectorAdd(vec, &newDebris);
  }
}

public U0 MobAI(World *w, F64 delta) {
  I64 i;
  Mob *mob = w->mobs.d;
  CD2 playerPos;
  playerPos.x = w->player.pos.x+8;
  playerPos.y = w->player.pos.y+16;
  for (i=0; i<w->mobs.len; i++, mob++) {
  mob->cooldown -= delta;
//    switch (mob->state) {
//    }
    CD2 mobPos;
    mobPos.x = mob->pos.x+mob->size.x>>1;
    mobPos.y = mob->pos.y+mob->size.y>>1;
    if (mobPos.x < playerPos.x) {
      mob->flags |= MFLAG_WALK_R;
      mob->flags &= MFLAG_WALK_L_REM;
    } else if (mobPos.x > playerPos.x) {
      mob->flags |= MFLAG_WALK_L;
      mob->flags &= MFLAG_WALK_R_REM;
    }

    if (mob->cooldown <= 0 && mobPos.y > playerPos.y) {
      mob->cooldown = 1;
      mob->vel.y = -256;
      SetAnim(&mob->anim, &BlobFlapAnim, &BlobIdleAnim);
    }

    if (mob->flags&MFLAG_WALK_R) {
      if (mob->vel.x < 128) {
        mob->vel.x += 200 * delta;
        if (mob->vel.x > 128) mob->vel.x = 128;
      }
    } else if (mob->flags&MFLAG_WALK_L) {
      if (mob->vel.x > -128) {
        mob->vel.x -= 180 * delta;
#ifdef DEBUG
        CommPrint("Left %f %.4f\n", mob->vel.x, delta);
#endif
        if (mob->vel.x < -128) mob->vel.x = -128;
      }
    }
  }
}

public U0 MobKill(World *w, I64 i) {
  Mob *mob = &w->mobs.d(Mob*)[i];
  CD2 gibPos;
  gibPos.x = mob->pos.x+mob->size.x>>1;
  gibPos.y = mob->pos.y+mob->size.y>>1;
  Gib gib;
  gib.px = &BlobGibLeft;
  gib.pos.x = gibPos.x;
  gib.pos.y = gibPos.y;
  gib.vel.x = -256;
  gib.vel.y = -128;
  gib.rot = 0;
  gib.ttl = 6;
  VectorAdd(&w->gibs, &gib);
  gib.px = &BlobGibRight;
  gib.pos.x = gibPos.x;
  gib.pos.y = gibPos.y;
  gib.vel.x = 256;
  gib.vel.y = -128;
  VectorAdd(&w->gibs, &gib);
  gib.px = &BlobGibBottom;
  gib.pos.x = gibPos.x;
  gib.pos.y = gibPos.y;
  gib.vel.x = 0;
  gib.vel.y = 0;
  VectorAdd(&w->gibs, &gib);
  gib.px = &BlobGibLeftWing;
  gib.pos.x = gibPos.x;
  gib.pos.y = gibPos.y;
  gib.vel.x = -128;
  gib.vel.y = -256;
  gib.rot = 3.141593;
  VectorAdd(&w->gibs, &gib);
  gib.px = &BlobGibRightWing;
  gib.pos.x = gibPos.x;
  gib.pos.y = gibPos.y;
  gib.vel.x = 128;
  gib.vel.y = -256;
  VectorAdd(&w->gibs, &gib);
  VectorDel(&w->mobs, i);
  VectorDel(&w->cMobs, i);
}

public U0 MobDmg(World *w, I64 i, F64 dmg) {
  Mob *mob = &w->mobs.d(Mob*)[i];
  mob->health -= dmg;
  DebrisAddRand(&w->debris, mob->pos.x+mob->size.x>>1,
                mob->pos.y+mob->size.y>>1, 128, 8);
  if (mob->health <= 0) {
    MobKill(w, i);
  }
}


public U0 SpawnerKill(World *w, I64 i) {
  SetSnd(SND_EXPLOSION);
  Spawner *spawner = &w->spawners.d(Spawner*)[i];
  CD2 gibPos;
  gibPos.x = spawner->pos.x+SPAWNER_W>>1;
  gibPos.y = spawner->pos.y+SPAWNER_H>>1;
  Gib gib;
  gib.px = &CarGibLeft;
  gib.pos.x = gibPos.x;
  gib.pos.y = gibPos.y;
  gib.vel.x = -256;
  gib.vel.y = -128;
  gib.rot = 0;
  gib.ttl = 6;
  VectorAdd(&w->gibs, &gib);
  gib.px = &CarGibRight;
  gib.pos.x = gibPos.x;
  gib.pos.y = gibPos.y;
  gib.vel.x = 256;
  gib.vel.y = -128;
  VectorAdd(&w->gibs, &gib);
  gib.px = &CarGibBottom;
  gib.pos.x = gibPos.x;
  gib.pos.y = gibPos.y;
  gib.vel.x = 0;
  gib.vel.y = 0;
  VectorAdd(&w->gibs, &gib);
  Explosion newExp;
  newExp.pos.x = gibPos.x;
  newExp.pos.y = gibPos.y;
  newExp.ttl = 1;
  VectorAdd(&w->explosions, &newExp);
  VectorDel(&w->spawners, i);
}

public U0 SpawnerDmg(World *w, I64 i, F64 dmg) {
  Spawner *spawner = &w->spawners.d(Spawner*)[i];
  spawner->health -= dmg;
  DebrisAddRand(&w->debris, spawner->pos.x+SPAWNER_W>>1,
                spawner->pos.y+SPAWNER_H>>1, 128, 8);
  if (spawner->health <= 0) {
    SpawnerKill(w, i);
  }
}

public U0 InitLevel(World *w, MapTemplate *src, U8 *noise) {
  // Setup Camera
  w->cam.x = 320;
  w->cam.y = 240;

  // Reset Vectors
  w->mobs.len = 0;
  w->cMobs.len = 0;
  w->items.len = 0;
  w->debris.len = 0;
  w->debrisEarth.len = 0;
  w->coolers.len = 0;
  w->lasers.len = 0;
  w->laserPixels.len = 0;
  w->grenades.len = 0;
  w->explosions.len = 0;
  w->gibs.len = 0;
  w->spawners.len = 0;

  I64 i;
  Spawner spawner;
  LoadMap(&w->level, src, noise);
  for (i=0; i<src->spawnerCount; i++) {
    spawner.pos.x = src->spawners[i].x;
    spawner.pos.y = src->spawners[i].y-30;
    spawner.ttl = SPAWNER_TTL;
    spawner.health = SPAWNER_HEALTH;
    VectorAdd(&w->spawners, &spawner);
  }
}

#endif
