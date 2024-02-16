#ifndef WORLD_HC
#define WORLD_HC

#include "Draw";
#include "God";
#include "Vector";
#include "Obj/Thruster";

#define PING_EXPIRE 3

#define TYPE_NONE 0
#define TYPE_PLAYER 1
#define TYPE_MOB 2
#define TYPE_WALL 3
#define TYPE_BASE 4
#define TYPE_TUR 5
#define TYPE_SPAWNER 6

#define WEAPON_NONE 0
#define WEAPON_SHOT 1
#define WEAPON_LASER 2

#define WEAPON_LASER_TTL 0.01

#define BULLET_DMG 5
#define LASER_DMG 32.0

class Particle {
  CD2 pos;
  F64 ttl;
};

class Laser {
  I32 x1;
  I32 y1;
  I32 x2;
  I32 y2;
  I32 cx;
  I32 cy;
  F64 ttl;
};

class Ship {
  CD3 pos;
  CD2I32 size;
  CD2 accel;
  CD2 vel;
  F64 ry;
  Quaternion q;
  F64 health;
  I64 laserRange;
  F64 bulletCooldown;
  I64 bulletDmg;
  F64 bulletSpeed;
};

class MapPing {
  CD2 pos;
  F64 ttl;
  CColorROPU32 color;
}

class World {
  // Basic Data
  I64 level;
  Bool levelTransition;
  F64 levelTransitionTTL;
  Bool dead;
  Bool escapePhase;
  Cam cam;
  GText gtext;
  I64 spawnWave;
  I64 spawnedMobsLeft;
  I64 activeWeapon;
  F64 activeWeaponTTL;
  Ship player;
  I64 waypointMat[4][4];
  CTask *task;

  // Entity Arrays
  Vector base;
  Vector spawner;
  Vector mobs;
  Vector bullets;
  Vector bulletM;
  Vector lasers;
  Vector pickup;
  Vector turrets;
  Vector wallPosts;
  Vector walls;
  Vector godWords;
  Vector mapPings;

  // Particle Buffers
  Vector debris;
  Vector explosion;
  Vector spawnFX;

  // Matrix Buffers
  F64 pTf;
  I64 pMat[4][4];
  I64 escapeMat[4][4];
  F64 escapeNorm;
  CD3I32 pTris[Thruster_tris][3];
  Vector grBullets;
  Vector grBulletsM;
  Vector grDebris;
  Vector grMobs;
  Vector grSpawner;
  Vector grTur;

  // Collision Buffers
  Vector collide;
  Vector collideMeta;
  Vector cBase;
  Vector cMobs;
  Vector cSpawner;
  Vector cTur;
};

class JobData {
  World *w;
  F64 delta;
  I64 mx, my;
};

#endif