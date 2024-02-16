#ifndef ASSETS_HC
#define ASSETS_HC

#include "Debug"
#include "PxBlot"

#define PICKUP_NONE           -1
#define PICKUP_CREDIT         0
#define PICKUP_BOMB           1
#define PICKUP_UPGRADE_SHOT   2
#define PICKUP_UPGRADE_SPREAD 3
#define PICKUP_UPGRADE_LASER  4
#define PICKUP_TOTAL          5

#define MOB_BASIC     0
#define MOB_LONG      1
#define MOB_TRI       2
#define MOB_BOSS0     3
#define MOB_BOSS0_GUN 4
#define MOB_BOSS1     5
#define MOB_BOSS2     6
#define MOB_BOSS3     7
#define MOB_BOSS4     8
#define MOB_BOSS5     9
#define MOB_BOSS6     10
#define MOB_BOSS7     11
#define MOB_TOTAL     12

#define LEVEL_TOTAL 8
#define BLACKHOLE_LEN 60

class ObjTris {
  U32 cnt;
  CD3I32 tris[];
};

class ObjLines {
  U32 cnt;
  CD3I32 lines[];
};

class ObjLinesColor {
  U32 cnt;
  CD3I32 *lines;
  U8 *colors
};

class ModelTemplate {
  I64    triCnt;
  I64    normCnt;
  CD3I32 *tris;
  U8     *colors;
  CD3    *normals;
  U16    *normIdx;
};

class MobObj {
  ObjLinesColor model;
  ObjLinesColor gun;
  I32 cCnt;
  ObjLines* collider[2];
  ModelTemplate mesh; // TODO don't need a full ModelTemplate
  ObjTris *debris;
};

class Font {
  I32 x;
  I32 y;
  PxData *char[94];
  I8 fontY[94];
  U8 pad[2]; // alignment
};

class LevelMob {
  I16 x;
  I16 y;
  U8 model;
  U8 move;
  U8 shoot;
  U8 drop;
};

class LevelTemplate {
  U64 cnt;
  U64 lastY;
  U16 *spawnY;
  LevelMob *mobs;
};

class Assets {
  PxData *pxBulletShot0;
  PxData *pxBulletShot1;
  PxData *pxBulletShot2;
  PxData *pxBulletSpread0;
  PxData *pxBulletSpread1;
  PxData *pxBulletSpread2;
  PxData *pxBulletMobCircle8;
  PxData *pxBulletMobCircle16;
  PxData *pxBulletMobStar16;
  PxData *pxBomb;
  PxData* pxBlackHole[BLACKHOLE_LEN];
  PxData *pxUpgradeShot;
  PxData *pxUpgradeSpread;
  PxData *pxUpgradeLaser;
  PxData *pxUpgradeBomb;
  PxData *pxCredit;
  PxData *pxScum;
  PxData *pxBIF;
  PxData *pxBIF2;
  PxData *pxBIF2A;
  PxData *pxCrunkLord;
  PxData *BossBorderTop;
  PxData *BossBorderBottom;
  PxData *BossBorderSlider;
  PxData *BreachDetected;
  PxData *ScoreScreen;
  PxData *PauseScreen;
  Font fontKapel;
  Font fontKapel2x;
  ObjLines *ship;
  ObjLinesColor boss0DLeft;
  ObjLinesColor boss0DRight;
  ObjLinesColor boss1DLeft;
  ObjLinesColor boss1DRight;
  ObjLinesColor boss1DFront;
  ObjLinesColor boss1DRear;
  ObjLinesColor boss2DLeft;
  ObjLinesColor boss2DRight;
  ObjLinesColor boss3DLF;
  ObjLinesColor boss3DRF;
  ObjLinesColor boss4DLeft;
  ObjLinesColor boss4DRight;
  ObjLinesColor boss5DLeft;
  ObjLinesColor boss5DRight;
  ObjLinesColor boss5DFront;
  ObjLinesColor boss5DRear;
  ObjLinesColor boss6DLeft;
  ObjLinesColor boss6DRight;
  ObjLinesColor boss7DLF;
  ObjLinesColor boss7DRF;
  ObjTris *shipThruster;
  MobObj mobModels[MOB_TOTAL];
  ModelTemplate shipCore;
  ModelTemplate boss0DMeshLeft;
  ModelTemplate boss0DMeshRight;
  ModelTemplate boss1DMeshLeft;
  ModelTemplate boss1DMeshRight;
  ModelTemplate boss1DMeshFront;
  ModelTemplate boss1DMeshRear;
  ModelTemplate boss2DMeshLeft;
  ModelTemplate boss2DMeshRight;
  ModelTemplate boss3DMeshLF;
  ModelTemplate boss3DMeshRF;
  PxData *pickupPx[PICKUP_TOTAL];
  LevelTemplate levels[LEVEL_TOTAL];
};

U8 LoadAssetLevels(LevelTemplate *levels) {
  I64 i, bufSize;
  U8 filename[256];
  for (i=0; i<LEVEL_TOTAL; i++) {
    StrPrint(filename, "Levels/Level%02d.BIN", i);
    U8 *buf = FileRead(filename, &bufSize);
    if (buf == NULL) {
      return 1;
    }
    levels[i].cnt = buf(U16*)[0];
    levels[i].lastY = buf(U16*)[1];
    I64 spawnSize = levels[i].cnt*sizeof(U16);
    I64 mobSize = levels[i].cnt*sizeof(LevelMob);
    levels[i].spawnY = MAlloc(spawnSize);
    levels[i].mobs = MAlloc(mobSize);
    MemCpy(levels[i].spawnY, buf+4, spawnSize);
    MemCpy(levels[i].mobs, buf+4+spawnSize, mobSize);
    Free(buf);
  }
  return 0;
}

U8 LoadAssetPx(PxData **dst, U8 *filename) {
  U8 *buf = FileRead(filename);
  I64 size = buf(I32*)[0]*buf(I32*)[1] + 8;
  *dst = MAlloc(size);
  MemCpy(*dst, buf, size);
  Free(buf);
  return 0;
}

U8 LoadAssetFont(Font *font, U8 *path, I32 x, I32 y) {
  I64 i;
  U8 filename[256];
  font->x = x;
  font->y = y;
  for (i=0; i<94; i++) {
    StrPrint(filename, "%s/%03d.BIN", path, i+33);
    if (LoadAssetPx(&font->char[i], filename))
      return 1;
  }
  StrPrint(filename, "%s/FontData.BIN", path);
  I64 bufSize;
  U8 *buf = FileRead(filename, &bufSize);
  font->y = buf[0];
  MemCpy(font->fontY, buf+1, bufSize-1);
  Free(buf);
  return 0;
}

U8 LoadAssetAnim(PxData **px, U8 *path, I32 frames) {
  I64 i;
  U8 filename[256];
  for (i=0; i<frames; i++) {
    StrPrint(filename, "Px/%s/%02d.BIN", path, i);
    if (LoadAssetPx(&px[i], filename))
      return 1;
  }
  return 0;
}

U8 LoadAssetLines(ObjLines **dst, U8 *filename) {
  U8 *buf=FileRead(filename);
  I64 size = buf(U32*)[0]*sizeof(CD3I32) + 4;
  *dst = MAlloc(size);
  MemCpy(*dst, buf, size);
  Free(buf);
  return 0;
}

U8 LoadAssetLinesColor(ObjLinesColor *dst, U8 *filename) {
  U8 *buf = FileRead(filename);;
  dst->cnt = buf(U32*)[0];
  I64 lineSize = dst->cnt*sizeof(CD3I32);
  I64 colorSize = dst->cnt/2;
  dst->lines = MAlloc(lineSize);
  dst->colors = MAlloc(colorSize);
  MemCpy(dst->lines, buf+4, lineSize);
  MemCpy(dst->colors, buf+4+lineSize, colorSize);
  Free(buf);
  return 0;
}

U8 LoadAssetTris(ObjTris **dst, U8 *filename) {
  U8 *buf=FileRead(filename);
  I64 size = buf(U32*)[0]*sizeof(CD3I32)*3 + 4;
  *dst = MAlloc(size);
  MemCpy(*dst, buf, size);
  Free(buf);
  return 0;
}

U8 LoadAssetMeshN(ModelTemplate *dst, U8 *filename) {
  U8 *buf = FileRead(filename);
  dst->triCnt = buf(U16*)[0];
  dst->normCnt = buf(U16*)[1];

  I64 triSize = dst->triCnt*sizeof(CD3I32)*3;
  I64 normSize = dst->normCnt*sizeof(CD3);
  I64 normIdxSize = dst->triCnt*sizeof(U16);

  dst->tris = MAlloc(triSize);
  dst->colors = MAlloc(dst->triCnt);
  dst->normals = MAlloc(normSize);
  dst->normIdx = MAlloc(normIdxSize);

  U8 *read = buf + 4;
  MemCpy(dst->tris, read, triSize);
  read += triSize;
  MemCpy(dst->normIdx, read, normIdxSize);
  read += normIdxSize;
  MemCpy(dst->normals, read, normSize);
  read += normSize;
  MemCpy(dst->colors, read, dst->triCnt);
  Free(buf);

  return 0;
}

U8 AssetsInit(Assets *assets) {
  if (LoadAssetLevels(assets->levels))
    return 1;
  if (LoadAssetPx(&assets->pxBulletShot0, "Px/BulletShot0.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBulletShot1, "Px/BulletShot1.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBulletShot2, "Px/BulletShot2.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBulletSpread0, "Px/BulletSpread0.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBulletSpread1, "Px/BulletSpread1.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBulletSpread2, "Px/BulletSpread2.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBulletMobCircle8, "Px/BulletMobCircle8.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBulletMobCircle16, "Px/BulletMobCircle16.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBulletMobStar16, "Px/BulletMobStar16.BIN"))
    return 1;
  if (LoadAssetAnim(assets->pxBlackHole, "BlackHole", BLACKHOLE_LEN))
    return 1;
  if (LoadAssetPx(&assets->pxBomb, "Px/Bomb.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxUpgradeShot, "Px/UpgradeShot.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxUpgradeSpread, "Px/UpgradeSpread.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxUpgradeLaser, "Px/UpgradeLaser.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxUpgradeBomb, "Px/UpgradeBomb.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxCredit, "Px/Credit.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxScum, "Px/Scum.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBIF, "Px/BIF.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBIF2, "Px/BIF2.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxBIF2A, "Px/BIF2A.BIN"))
    return 1;
  if (LoadAssetPx(&assets->pxCrunkLord, "Px/CrunkLord.BIN"))
    return 1;
  if (LoadAssetPx(&assets->BossBorderTop, "Px/BossBorderTop.BIN"))
    return 1;
  if (LoadAssetPx(&assets->BossBorderBottom, "Px/BossBorderBottom.BIN"))
    return 1;
  if (LoadAssetPx(&assets->BossBorderSlider, "Px/BossBorderSlider.BIN"))
    return 1;
  if (LoadAssetPx(&assets->BreachDetected, "Px/BreachDetected.BIN"))
    return 1;
  if (LoadAssetPx(&assets->ScoreScreen, "Px/ScoreScreen.BIN"))
    return 1;
  if (LoadAssetPx(&assets->PauseScreen, "Px/PauseScreen.BIN"))
    return 1;
  if (LoadAssetLines(&assets->ship, "Obj/Lines/Ship.BIN"))
    return 1;

  // MobObj
  if (LoadAssetLinesColor(&assets->mobModels[MOB_BASIC].model, "Obj/LinesColor/MobBasic.BIN"))
    return 1;
  assets->mobModels[MOB_BASIC].cCnt = 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BASIC].collider[0], "Obj/Collision/MobBasic.BIN"))
    return 1;

  if (LoadAssetLinesColor(&assets->mobModels[MOB_LONG].model, "Obj/LinesColor/MobLong.BIN"))
    return 1;
  assets->mobModels[MOB_LONG].cCnt = 1;
  if (LoadAssetLines(&assets->mobModels[MOB_LONG].collider[0], "Obj/Collision/MobLong.BIN"))
    return 1;

  if (LoadAssetLinesColor(&assets->mobModels[MOB_TRI].model, "Obj/LinesColor/MobTri.BIN"))
    return 1;
  assets->mobModels[MOB_TRI].cCnt = 1;
  if (LoadAssetLines(&assets->mobModels[MOB_TRI].collider[0], "Obj/Collision/MobTri.BIN"))
    return 1;

  // Boss0
  if (LoadAssetLinesColor(&assets->mobModels[MOB_BOSS0].model, "Obj/LinesColor/Boss0.BIN"))
    return 1;
  assets->mobModels[MOB_BOSS0].cCnt = 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS0].collider[0], "Obj/Collision/Boss0.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->mobModels[MOB_BOSS0].mesh, "Obj/Mesh/Boss0.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_BOSS0].debris, "Obj/Tris/Boss0D.BIN"))
    return 1;

  // Boss1
  if (LoadAssetLinesColor(&assets->mobModels[MOB_BOSS1].model, "Obj/LinesColor/Boss1.BIN"))
    return 1;
  assets->mobModels[MOB_BOSS1].cCnt = 2;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS1].collider[0], "Obj/Collision/Boss1c0.BIN"))
    return 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS1].collider[1], "Obj/Collision/Boss1c1.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->mobModels[MOB_BOSS1].mesh, "Obj/Mesh/Boss1.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_BOSS1].debris, "Obj/Tris/Boss1D.BIN"))
    return 1;

  // Boss2
  if (LoadAssetLinesColor(&assets->mobModels[MOB_BOSS2].model, "Obj/LinesColor/Boss2.BIN"))
    return 1;
  assets->mobModels[MOB_BOSS2].cCnt = 2;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS2].collider[0], "Obj/Collision/Boss2c0.BIN"))
    return 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS2].collider[1], "Obj/Collision/Boss2c1.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->mobModels[MOB_BOSS2].mesh, "Obj/Mesh/Boss2.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_BOSS2].debris, "Obj/Tris/Boss2D.BIN"))
    return 1;

  // Boss3
  if (LoadAssetLinesColor(&assets->mobModels[MOB_BOSS3].model, "Obj/LinesColor/Boss3.BIN"))
    return 1;
  assets->mobModels[MOB_BOSS3].cCnt = 2;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS3].collider[0], "Obj/Collision/Boss3c0.BIN"))
    return 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS3].collider[1], "Obj/Collision/Boss3c1.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->mobModels[MOB_BOSS3].mesh, "Obj/Mesh/Boss3.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_BOSS3].debris, "Obj/Tris/Boss3D.BIN"))
    return 1;

  // Boss4
  if (LoadAssetLinesColor(&assets->mobModels[MOB_BOSS4].model, "Obj/LinesColor/Boss4.BIN"))
    return 1;
  assets->mobModels[MOB_BOSS4].cCnt = 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS4].collider[0], "Obj/Collision/Boss0.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->mobModels[MOB_BOSS4].mesh, "Obj/Mesh/Boss0.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_BOSS4].debris, "Obj/Tris/Boss0D.BIN"))
    return 1;

  // Boss5
  if (LoadAssetLinesColor(&assets->mobModels[MOB_BOSS5].model, "Obj/LinesColor/Boss5.BIN"))
    return 1;
  assets->mobModels[MOB_BOSS5].cCnt = 2;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS5].collider[0], "Obj/Collision/Boss1c0.BIN"))
    return 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS5].collider[1], "Obj/Collision/Boss1c1.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->mobModels[MOB_BOSS5].mesh, "Obj/Mesh/Boss1.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_BOSS5].debris, "Obj/Tris/Boss1D.BIN"))
    return 1;

  // Boss6
  if (LoadAssetLinesColor(&assets->mobModels[MOB_BOSS6].model, "Obj/LinesColor/Boss6.BIN"))
    return 1;
  assets->mobModels[MOB_BOSS6].cCnt = 2;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS6].collider[0], "Obj/Collision/Boss2c0.BIN"))
    return 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS6].collider[1], "Obj/Collision/Boss2c1.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->mobModels[MOB_BOSS6].mesh, "Obj/Mesh/Boss2.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_BOSS6].debris, "Obj/Tris/Boss2D.BIN"))
    return 1;

  // Boss7
  if (LoadAssetLinesColor(&assets->mobModels[MOB_BOSS7].model, "Obj/LinesColor/Boss7.BIN"))
    return 1;
  assets->mobModels[MOB_BOSS7].cCnt = 2;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS7].collider[0], "Obj/Collision/Boss3c0.BIN"))
    return 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS7].collider[1], "Obj/Collision/Boss3c1.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->mobModels[MOB_BOSS7].mesh, "Obj/Mesh/Boss3.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_BOSS7].debris, "Obj/Tris/Boss3D.BIN"))
    return 1;

  if (LoadAssetLinesColor(&assets->mobModels[MOB_BOSS0_GUN].gun, "Obj/LinesColor/Boss0Gun.BIN"))
    return 1;

  assets->mobModels[MOB_BOSS0_GUN].cCnt = 1;
  if (LoadAssetLines(&assets->mobModels[MOB_BOSS0_GUN].collider[0], "Obj/Collision/Boss0Gun.BIN"))
    return 1;

  // Random Mesh
  if (LoadAssetMeshN(&assets->shipCore, "Obj/Mesh/ShipCore.BIN"))
    return 1;

  // Boss 0 Debris Mesh
  if (LoadAssetMeshN(&assets->boss0DMeshLeft, "Obj/Mesh/Boss0DLeft.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->boss0DMeshRight, "Obj/Mesh/Boss0DRight.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss0DLeft, "Obj/LinesColor/Boss0DLeft.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss0DRight, "Obj/LinesColor/Boss0DRight.BIN"))
    return 1;

  // Boss 1 Debris Mesh
  if (LoadAssetMeshN(&assets->boss1DMeshLeft, "Obj/Mesh/Boss1DLeft.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->boss1DMeshRight, "Obj/Mesh/Boss1DRight.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->boss1DMeshFront, "Obj/Mesh/Boss1DFront.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->boss1DMeshRear, "Obj/Mesh/Boss1DRear.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss1DLeft, "Obj/LinesColor/Boss1DLeft.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss1DRight, "Obj/LinesColor/Boss1DRight.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss1DFront, "Obj/LinesColor/Boss1DFront.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss1DRear, "Obj/LinesColor/Boss1DRear.BIN"))
    return 1;

  // Boss 2 Debris Mesh
  if (LoadAssetMeshN(&assets->boss2DMeshLeft, "Obj/Mesh/Boss2DLeft.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->boss2DMeshRight, "Obj/Mesh/Boss2DRight.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss2DLeft, "Obj/LinesColor/Boss2DLeft.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss2DRight, "Obj/LinesColor/Boss2DRight.BIN"))
    return 1;

  // Boss 3 Debris Mesh
  if (LoadAssetMeshN(&assets->boss3DMeshLF, "Obj/Mesh/Boss3DLF.BIN"))
    return 1;
  if (LoadAssetMeshN(&assets->boss3DMeshRF, "Obj/Mesh/Boss3DRF.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss3DLF, "Obj/LinesColor/Boss3DLF.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss3DRF, "Obj/LinesColor/Boss3DRF.BIN"))
    return 1;

  // Boss 4 Debris
  if (LoadAssetLinesColor(&assets->boss4DLeft, "Obj/LinesColor/Boss4DLeft.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss4DRight, "Obj/LinesColor/Boss4DRight.BIN"))
    return 1;

  if (LoadAssetTris(&assets->shipThruster, "Obj/Tris/Thruster.BIN"))
    return 1;

  // Boss 5 Debris
  if (LoadAssetLinesColor(&assets->boss5DLeft, "Obj/LinesColor/Boss5DLeft.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss5DRight, "Obj/LinesColor/Boss5DRight.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss5DFront, "Obj/LinesColor/Boss5DFront.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss5DRear, "Obj/LinesColor/Boss5DRear.BIN"))
    return 1;

  // Boss 6 Debris
  if (LoadAssetLinesColor(&assets->boss6DLeft, "Obj/LinesColor/Boss6DLeft.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss6DRight, "Obj/LinesColor/Boss6DRight.BIN"))
    return 1;

  // Boss 7 Debris
  if (LoadAssetLinesColor(&assets->boss7DLF, "Obj/LinesColor/Boss7DLF.BIN"))
    return 1;
  if (LoadAssetLinesColor(&assets->boss7DRF, "Obj/LinesColor/Boss7DRF.BIN"))
    return 1;

  // Load Mob Debris
  if (LoadAssetTris(&assets->mobModels[MOB_BASIC].debris, "Obj/Tris/MobBasicD.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_LONG].debris, "Obj/Tris/MobLongD.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_TRI].debris, "Obj/Tris/MobTriD.BIN"))
    return 1;
  if (LoadAssetTris(&assets->mobModels[MOB_BOSS0_GUN].debris, "Obj/Tris/Boss0GunD.BIN"))
    return 1;

  if (LoadAssetFont(&assets->fontKapel, "Px/FontKapel", 10, 14))
    return 1;
  if (LoadAssetFont(&assets->fontKapel2x, "Px/FontKapel2x", 10, 24))
    return 1;

  // Setup Arrays
  assets->pickupPx[0] = assets->pxCredit;
  assets->pickupPx[1] = assets->pxUpgradeBomb;
  assets->pickupPx[2] = assets->pxUpgradeShot;
  assets->pickupPx[3] = assets->pxUpgradeSpread;
  assets->pickupPx[4] = assets->pxUpgradeLaser;

  return 0;
}

U0 AssetsFree(Assets *assets) {
  Free(assets->ship);
}

#endif
