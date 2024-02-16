#ifndef UPDATE_HC
#define UPDATE_HC

#include "Bullet"
#include "Debris"
#include "God"
#include "Mob"
#include "Particle"
#include "PauseMenu"
#include "Pickup"
#include "Ship"
#include "Sound"
#include "World"
#include "Popup"
#include "Patterns"
#include "Debug"

#define EXP_EXPIRE 1
#define LEVEL_TRANSITION_TTL 10
#define SHIP_VEL_SPEED 2048
#define SHIP_VEL_FRICTION 8
#define BOMB_DMG 200
#define BOMB_TTL 0.6666

F64 WEAPON_TTL[WEAPON_TOTAL] = {
0.16,
0.16,
0.16,

0.16,
0.16,
0.16,

0.01,
0.01,
0.01,
};

U0 InitNextLevel() {
  gW.lvlMobsBonus = MOB_BONUS*(ToF64(gW.lvlMobsKilled)/gW.lvlMobsSpawned);
  gW.lvlBombBonus = BOMB_BONUS*gW.bombs;
  gW.levelTransition = TRUE;
  gW.levelTransitionTTL = 0.0;
  gW.levelNum++;
  if (gW.levelNum < LEVEL_TOTAL)
    gW.level = &gAssets.levels[gW.levelNum];
}

U0 InitLevel() {
  blur_ttl = 0;
  bomb_ttl = 0;
  firing_ttl = 0.1;

  gCtrl.cVel.x = 0.0;
  gCtrl.cVel.y = 0.0;
  gCtrl.firing = FALSE;

  gW.scrollY = 0.0;
  gW.scrollSpeed = 64.0;
  gW.lastSpawnIdx = 0;

  gW.score += gW.appliedMobBonus + gW.appliedBombBonus;
  gW.appliedMobBonus = 0;
  gW.appliedBombBonus = 0;

  gW.lvlMobsSpawned = 0;
  gW.lvlMobsKilled = 0;
  gW.lvlScore = 0;
  gW.lvlMobsBonus = 0;
  gW.lvlBombBonus = 0;

  gW.bossIntroTTL = 0;
  gW.bossDeadTTL = 0;
  gW.bossTriggered = FALSE;
  gW.bossDead = FALSE;
  gW.levelTransition = FALSE;
  gW.dead = FALSE;

  gW.player.pos.x = SCX;
  gW.player.pos.y = FB_H;
  gW.player.scale = 1.0;
  gW.player.speed = 256.0;
  gW.player.vel.x = 0.0;
  gW.player.vel.y = 0.0;
  gW.player.accel.x = 0.0;
  gW.player.accel.y = 0.0;
  gW.player.q.x = 0.0;
  gW.player.q.y = 0.0;
  gW.player.q.z = 0.0;
  gW.player.q.w = 1.0;
  gW.player.health = 100.0;
  gW.player.accel.x = 0.0;
  gW.player.accel.y = 0.0;

  // Reset Arrays
  gW.bullets.len = 0;
  gW.mobs.len = 0;
  gW.bulletsM.len = 0;
  gW.lasers.len = 0;
  gW.pickups.len = 0;
  gW.godWords.len = 0;

  // Reset Collision Buffers
  gW.collide.len = 0;
  gW.collideMeta.len = 0;
  gW.cPolys.len = 0;
  gW.cPolyIdx.len = 0;

  // Reset Graphics Buffers
  gW.grDebris.len = 0;
  gW.grMobs.len = 0;
  gW.grGuns.len = 0;

  // Reset Particle Buffers
  gW.debris.len = 0;
  gW.debrisMesh.len = 0;
  gW.explosion.len = 0;
  gW.spawnFX.len = 0;
}

U0 ResetGame() {
  gW.score = 0;
  gW.appliedMobBonus = 0;
  gW.appliedBombBonus = 0;
  gW.bombs = 3;

  t_delta = 0;

  // "Empty" arrays
  gW.godWords.len = 0;

  InitGText(&gW.gtext);

  gW.levelNum = 0;
  gW.level = &gAssets.levels[gW.levelNum];
  gW.levelTransition = FALSE;

  InitLevel;
  gW.activeWeapon = WEAPON_SHOT0;

  gW.pauseMenu = FALSE;

  game_palette[1].r = Sin(t_now) * 32767 + 32768;
  game_palette[1].g = Sin(t_now+2) * 32767 + 32768;
  game_palette[1].b = Sin(t_now+4) * 32767 + 32768;
  game_palette[13].r = Sin(t_now) * 32767 + 32768;
  game_palette[13].g = Sin(t_now+2) * 32767 + 32768;
  game_palette[13].b = Sin(t_now+4) * 32767 + 32768;
  GrPaletteSet(game_palette);
}

U0 AddLaser(F64 delta, F64 dmg, I32 width) {
  SetSnd(SND_LASER);
  Laser laser;
  laser.curve[0].x = gW.player.pos.x;
  laser.curve[0].y = gW.player.pos.y;
  laser.curve[1].x = gW.player.pos.x + (Rand*32-16);
  laser.curve[1].y = gW.player.pos.y / 2;
  if (gW.player.laserLock.x == inf) {
    laser.curve[2].x = gW.player.pos.x + gW.player.vel.x + (Rand*8-4);
    laser.curve[2].y = 0;
  } else {
    laser.curve[2].x = gW.player.laserLock.x;
    laser.curve[2].y = gW.player.laserLock.y;
  }
  laser.width = width;
  laser.ttl = 0.16;
  Mob *mob = gW.mobs.d;
  gW.player.laserLock.x = inf;
  I32 i, ii;
  for (i=0; i<gW.mobs.len; i++, mob++) {
    for (ii=0; ii<mob->centroidCnt; ii++) {
      CD2I32 res;
      if (CollideCircleBezier(laser.curve, mob->centroid[ii].x, mob->centroid[ii].y, 32, &res)) {
        F64 dist = inf;
        laser.curve[2].x = mob->centroid[ii].x;
        laser.curve[2].y = mob->centroid[ii].y;
        //SetSnd(SND_HIT);
        DmgMob(mob, dmg*delta);
        AddParticle(&gW.explosion, mob->centroid[ii].x, mob->centroid[ii].y);
        F64 dist1=Sqrt(Abs(gW.player.pos.x-mob->centroid[ii].x) + Abs(gW.player.pos.y-mob->centroid[ii].y));
        if (dist1 < gW.player.laserLock.x) {
          dist = dist1;
          gW.player.laserLock.x = mob->centroid[ii].x;
          gW.player.laserLock.y = mob->centroid[ii].y;
        }
      }
    }
  }
  VectorAdd(&gW.lasers, &laser);
}

U0 DmgPlayer(F64 dmg) {
  if (!gW.levelTransition) {
    blur_ttl = 0.07;
    playSnd = SND_PLAYER_DMG;
    gW.player.health -= dmg;
    if (gW.player.health < 0.0)
      gW.player.health = 0.0;
  }
}

U0 ProcessBullets(F64 delta, Vector *bullets) {
  I64 i, len = bullets->len;
  Bullet *b = bullets->d;
  CD2I32 *poly = gW.cPolys.d;
  for (i=0; i<len && len>0;) {
    if (b[i].pos.x < 0 || b[i].pos.x >= SCR_W || b[i].pos.y < 0 || b[i].pos.y >= FB_H) {
      VectorDel(bullets, i);
      len--;
      goto found_collision;
    } else {
      b[i].pos.x += b[i].vel.x * delta;
      b[i].pos.y += b[i].vel.y * delta;
      // Check Mobs
      I64 ii;
      cPolyMeta *meta = gW.cPolyIdx.d;
      for (ii=0; ii<gW.cPolyIdx.len; ii++, meta++) {
        if (CheckCollidePolyCircle(poly+meta->idx, meta->cnt, b[i].pos.x, b[i].pos.y, b[i].radius)) {
          SetSnd(SND_HIT);
          DmgMob(&gW.mobs.d(Mob*)[meta->mIdx], b[i].dmg);
          AddParticle(&gW.explosion, b[i].pos.x, b[i].pos.y);
          //AddParticle(&gW.explosion, gW.mobs.d(Mob*)[ii].pos.x, gW.mobs.d(Mob*)[ii].pos.y);
          VectorDel(bullets, i);
          len--;
          goto found_collision;
        }
      }
    i++;
found_collision:
    }
  }
}

U0 UpdateGame(F64 delta) {
  I64 i, len;
  CD2 vel;

  if (gW.pauseMenu)
    return;

  // Update Scroll
  gW.scrollY += gW.scrollSpeed * delta;

  // Check For Boss
  if (gW.levelTransition || gW.scrollY >= gW.level->lastY) {
    if (!gW.bossTriggered) {
      gW.bossTriggered = 1;
      gW.bossIntroTTL = BOSS_INTRO_TTL;
      AddBossFuncs[gW.levelNum]();
    } else {
      gW.bossIntroTTL -= delta;
    }
  } else {
    // Spawn Mobs
    for (i=gW.lastSpawnIdx; i<gW.level->cnt; i++) {
       if (gW.level->spawnY[i] > gW.scrollY) {
         gW.lastSpawnIdx = i;
         break;
       }
       gW.lastSpawnIdx++;
       AddMob(&gW.mobs, &gW.level->mobs[i], 0, 0, 0, 0);
    }
  }

  // Bomb
  Mob *mob;
  if (gCtrl.bombPressed && !gW.dead) {
    if (gW.bombs > 0) {
      SetSnd(SND_BOMB);
      gW.bombs--;
      bombPos.x = gW.player.pos.x;
      bombPos.y = gW.player.pos.y;
      bomb_ttl = BOMB_TTL;
      gW.bulletsM.len = 0;
      mob = gW.mobs.d;
      for (i=0; i<gW.mobs.len; i++, mob++)
        DmgMob(mob, BOMB_DMG);
    }
  }

  // Expiration
  ExpireDebris(&gW, delta);
  ExpireMobs();
  ProcessDebrisMesh(delta);

  // InitNextLevel should be after ExpireMobs for proper bonus calc
  if (gW.bossDead) {
    gW.bossDeadTTL -= delta;
    if (!gW.levelTransition)
      InitNextLevel;
  }

  // Process Player
  if (!gW.dead) {
    if (gW.player.health <= 0) {
      gW.dead = TRUE;
      death_ttl = 0.0;
      // Add Debris
      vel.x = 0;
      vel.y = 0;
      AddDebris(&gW, &gW.player.pos, &vel, gAssets.mobModels[MOB_BASIC].debris->tris, gAssets.mobModels[MOB_BASIC].debris->cnt);
    } else {
      // Process Player Movement
      F64 friction = 1.0 - 1.0 * SHIP_VEL_FRICTION * delta;
      if (gCtrl.cVel.x != 0.0) {
        gW.player.pos.x += gCtrl.cVel.x * gW.player.speed * delta;
        gW.player.accel.x += gCtrl.cVel.x * 20 * delta;
        gW.player.accel.x = Clamp(gW.player.accel.x, -1, 1);
        gW.player.vel.x += gCtrl.cVel.x * SHIP_VEL_SPEED * delta;
        gW.player.vel.x = Clamp(gW.player.vel.x, SHIP_VEL_MIN, SHIP_VEL_MAX);
      } else { // X Friction
        gW.player.accel.x *= friction;
        gW.player.vel.x *= friction;
      }
      if (gW.player.pos.x < 0) gW.player.pos.x = 0;
      else if (gW.player.pos.x >= SCR_W) gW.player.pos.x = SCR_W-1;

      if (gCtrl.cVel.y != 0.0) {
        gW.player.pos.y += gCtrl.cVel.y * gW.player.speed * delta;
        gW.player.accel.y += gCtrl.cVel.y * 20 * delta;
        gW.player.accel.y = Clamp(gW.player.accel.y, -1, 1);
        gW.player.vel.y += gCtrl.cVel.y * SHIP_VEL_SPEED * delta;
        gW.player.vel.y = Clamp(gW.player.vel.y, SHIP_VEL_MIN, SHIP_VEL_MAX);
      } else { // Y Friction
        gW.player.accel.y *= friction;
        gW.player.vel.y *= friction;
      }
      if (gW.player.pos.y < 0) gW.player.pos.y = 0;
      else if (gW.player.pos.y >= FB_H)
        gW.player.pos.y = FB_H-1;
    }
  } else {
    death_ttl += delta;
  }

  // Process Pickups
  UpdatePickups(delta);

  // Process Mob Movement
  mob = gW.mobs.d;
  for (i=0; i<gW.mobs.len; i++, mob++) {
    mob->move(&gW, mob, delta);
    mob->hit_ttl -= delta;
  }

  // Process Sub-Boss Movement
  if (gW.bossTriggered)
    UpdateSubBoss();

  // Process God Words
  ProcessGodWords(&gW.godWords, delta);

  // Process Debris
  DebrisMat(gW.debris.len, gW.debris.d, gW.grDebris.d, delta);
  GenMatShip(&gW.player, gW.pMat);

  // Update Timers
  blur_ttl -= delta;
  firing_ttl -= delta;
  bomb_ttl -= delta;

  // Generate Mob Matrix
  GenMatMobs(gW.mobs.d, gW.mobs.len, &gW.grMobs);
  GenCMobs(gW.mobs.d, gW.mobs.len, &gW.cPolys, &gW.cPolyIdx, gW.grMobs.d);

  // Fire
  if (gCtrl.firing && firing_ttl <= 0.0 && !gW.dead) {
    firing_ttl = WEAPON_TTL[gW.activeWeapon];
    switch (gW.activeWeapon) {
      case WEAPON_SHOT0:
        SetSnd(SND_BULLET);
        AddBullet(gW.player.pos.x-8,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SHOT0);
        AddBullet(gW.player.pos.x,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SHOT0);
        AddBullet(gW.player.pos.x+8,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SHOT0);
        break;
      case WEAPON_SHOT1:
        SetSnd(SND_BULLET);
        AddBullet(gW.player.pos.x-8,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SHOT1);
        AddBullet(gW.player.pos.x,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SHOT1);
        AddBullet(gW.player.pos.x+8,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SHOT1);
        break;
      case WEAPON_SHOT2:
        SetSnd(SND_BULLET);
        AddBullet(gW.player.pos.x-8,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SHOT2);
        AddBullet(gW.player.pos.x,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SHOT2);
        AddBullet(gW.player.pos.x+8,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SHOT2);
        break;
      case WEAPON_SPREAD0:
        SetSnd(SND_BULLET);
        AddBullet(gW.player.pos.x,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SPREAD0);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2+pi/32,&gW.bullets,BULLET_TYPE_SPREAD0);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2-pi/32,&gW.bullets,BULLET_TYPE_SPREAD0);
        break;
     case WEAPON_SPREAD1:
        SetSnd(SND_BULLET);
        AddBullet(gW.player.pos.x,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SPREAD1);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2+pi/32,&gW.bullets,BULLET_TYPE_SPREAD1);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2-pi/32,&gW.bullets,BULLET_TYPE_SPREAD1);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2+pi/16,&gW.bullets,BULLET_TYPE_SPREAD1);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2-pi/16,&gW.bullets,BULLET_TYPE_SPREAD1);
        break;
      case WEAPON_SPREAD2:
        SetSnd(SND_BULLET);
        AddBullet(gW.player.pos.x,gW.player.pos.y,0,-1,&gW.bullets,BULLET_TYPE_SPREAD2);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2+pi/32,&gW.bullets,BULLET_TYPE_SPREAD2);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2-pi/32,&gW.bullets,BULLET_TYPE_SPREAD2);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2+pi/16,&gW.bullets,BULLET_TYPE_SPREAD2);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2-pi/16,&gW.bullets,BULLET_TYPE_SPREAD2);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2+pi/8,&gW.bullets,BULLET_TYPE_SPREAD2);
        AddBulletRad(gW.player.pos.x,gW.player.pos.y,-pi/2-pi/8,&gW.bullets,BULLET_TYPE_SPREAD2);
        break;
      case WEAPON_LASER0:
        AddLaser(delta, LASER_DMG0, 8);
        break;
      case WEAPON_LASER1:
        AddLaser(delta, LASER_DMG1, 16);
        break;
      case WEAPON_LASER2:
        AddLaser(delta, LASER_DMG2, 32);
        break;
    }
  } else {
    gW.player.laserLock.x = inf;
  }

  // Mob Fire
  mob = gW.mobs.d;
  for (i=0; i<gW.mobs.len; i++, mob++)
    mob->shoot(&gW, mob, delta);

  // Process Bullets
  ProcessBullets(delta, &gW.bullets);

  // Process Mob Bullets
  Bullet *pb = gW.bulletsM.d;
  len = gW.bulletsM.len;
  for (i=0; i<len && len>0; i++) {
    if (pb[i].pos.x < 0 || pb[i].pos.x >= SCR_W || pb[i].pos.y < 0 || pb[i].pos.y >= FB_H) {
      VectorDel(&gW.bulletsM, i);
      i--;
      len--;
    } else {
      pb[i].pos.x += pb[i].vel.x * delta;
      pb[i].pos.y += pb[i].vel.y * delta;
      // Check Player Collision
      if (CheckCollideCircle(pb[i].pos.x, pb[i].pos.y, 4, gW.player.pos.x, gW.player.pos.y, PLAYER_HIT_RADIUS)) {
        AddParticle(&gW.explosion, pb[i].pos.x, pb[i].pos.y);
        DmgPlayer(10);
        VectorDel(&gW.bulletsM, i);
        i--;
        len--;
      }
    }
  }

  // Process Level Transition
  if (gW.levelTransition) {
    gW.levelTransitionTTL += delta;
    if (gW.levelTransitionTTL >= LEVEL_TRANSITION_TTL) {
      if (gW.levelNum >= LEVEL_TOTAL)
        switchScene = SCENE_END;
      else
        InitLevel;
    }
  }

  // Animate Lasers
  for (i=0; i<gW.lasers.len && gW.lasers.len>0; i++) {
    gW.lasers.d(Laser*)[i].curve[0].x = gW.player.pos.x;
    gW.lasers.d(Laser*)[i].curve[0].y = gW.player.pos.y;
    gW.lasers.d(Laser*)[i].ttl -= delta;
    if (gW.lasers.d(Laser*)[i].ttl <= 0.0) {
      VectorDel(&gW.lasers, i);
      i--;
    }
  }

  // Expire Explosions
  Particle *exp = gW.explosion.d;
  for (i=0; i<gW.explosion.len && gW.explosion.len>0; i++) {
    exp[i].ttl += delta;
    if (exp[i].ttl >= EXP_EXPIRE)
      VectorDel(&gW.explosion, i--);
  }

  // Expire SpawnFX
  exp = gW.spawnFX.d;
  for (i=0; i<gW.spawnFX.len && gW.spawnFX.len>0; i++) {
    exp[i].ttl += delta;
    if (exp[i].ttl >= EXP_EXPIRE)
      VectorDel(&gW.spawnFX, i--);
  }
}

#endif
