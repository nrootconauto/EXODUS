#ifndef WORLD_HC
#define WORLD_HC

#include "Assets"
#include "Draw"
#include "God"
#include "Vector"
#include "Text"

#define TYPE_NONE   0
#define TYPE_PLAYER 1
#define TYPE_MOB    2

#define WEAPON_SHOT0   0
#define WEAPON_SHOT1   1
#define WEAPON_SHOT2   2
#define WEAPON_SPREAD0 3
#define WEAPON_SPREAD1 4
#define WEAPON_SPREAD2 5
#define WEAPON_LASER0  6
#define WEAPON_LASER1  7
#define WEAPON_LASER2  8
#define WEAPON_TOTAL  9

#define MOB_BONUS 100000
#define BOMB_BONUS 10000

#define PLAYER_HIT_RADIUS 8

#define LASER_DMG0 32.0
#define LASER_DMG1 48.0
#define LASER_DMG2 64.0

class Particle {
  CD2 pos;
  F64 ttl;
};

class Laser {
  CD2I32 curve[3];
  I32 width;
  F64 ttl;
};

class Ship {
  CD2 pos;
  F64 scale;
  F64 speed;
  CD2 accel;
  CD2 vel;
  Quat q;
  F64 health;
  CD2 laserLock;
  ObjTris *thruster;
};

class cPolyMeta {
  U32 idx;
  U32 cnt;
  U16 mIdx;
  I16 cIdx;
};

class Pickup {
  F64 time;
  CD2 pos;
  I8 h;
  I8 w;
  I8 type;
  I8 pad; // for byte-alignment
};

class World {
  // Basic Data
  LevelTemplate *level;
  F64 scrollY;
  F64 scrollSpeed;
  U64 lastSpawnIdx;
  F64 levelTransitionTTL;
  U64 score;
  U32 appliedBombBonus;
  U32 appliedMobBonus;
  U64 lvlScore;
  I32 bombs;
  I32 activeWeapon;
  U32 lvlMobsSpawned;
  U32 lvlMobsKilled;
  U32 lvlMobsBonus;
  U32 lvlBombBonus;
  GText gtext;
  Ship player;
  CTask *task;
  U64 levelNum;
  F64 bossIntroTTL;
  F64 bossDeadTTL;

  Bool bossTriggered;
  Bool bossDead;
  Bool levelTransition;
  Bool dead;
  Bool pauseMenu;

  // Entity Arrays
  Vector mobs;
  Vector bullets;
  Vector bulletsM;
  Vector lasers;
  Vector pickups;
  Vector godWords;

  // Particle Buffers
  Vector debris;
  Vector debrisMesh;
  Vector explosion;
  Vector spawnFX;

  // Matrix Buffers
  I64 pMat[4][4];
  Vector grDebris;
  Vector grMobs;
  Vector grGuns;

  // Collision Buffers
  Vector collide;
  Vector collideMeta;
  Vector cPolys;
  Vector cPolyIdx;
};

public class Mob {
  CD2 pos;
  CD2 vel;
  I32 origin_x;
  F64 rot;
  F64 time;
  I32 centroidCnt;
  CD2I32 centroid[2];
//  I32 centroidSize[2];
  I16 gunX;
  I16 gunY;
  I16 offX;
  I16 offY;
  MobObj *obj;
  U0 (*move)(World*, Mob*, F64);
  U0 (*shoot)(World*, Mob*, F64);
  F64 shoot_ttl;
  F64 hit_ttl;
  F64 health;
  U16 scoreValue;
  U8 drop;
  U8 id;
  U8 mode;
  U8 flags;
};

#endif
