#ifndef PATTERNS_HC
#define PATTERNS_HC

#include "World"
#include "Mob"
#include "Bullet"
#include "Collision"

#define ROT_N  -1.5707963267948928
#define ROT_S  1.5707963267948928
#define ROT_SE 0.7853981633974464
#define ROT_SW 2.3561944901923392

class AddMobTemplate {
  U16 health;
};

AddMobTemplate MobDefaults[MOB_TOTAL] = {
  {10},
  {20},
  {30},
  {500},
  {100},
  {1000},
  {1000},
  {1000},
  {1500},
  {1500},
  {1500},
  {2000},
};

U0 MoveStatic(World*, Mob *mob, F64 delta) {
  mob->time += delta;
  mob->pos.y += 20 * delta;
  mob->rot = ROT_S;
}

U0 MoveRD(World*, Mob *mob, F64 delta) {
  mob->time += delta;
  F64 m = delta * 64;
  mob->pos.x += m;
  mob->pos.y += m;
  mob->rot = ROT_SE;
}

U0 MoveLD(World*, Mob *mob, F64 delta) {
  mob->time += delta;
  F64 m = delta * 64;
  mob->pos.x -= m;
  mob->pos.y += m;
  mob->rot = ROT_SW;
}

U0 MoveStraight(World*, Mob *mob, F64 delta) {
  mob->time += delta;
  F64 addY = 64.0 * delta;
  mob->pos.y += addY;
  mob->rot = ROT_S;
}

U0 MoveBigU(World*, Mob *mob, F64 delta) {
  mob->time += delta;
  F64 speed = mob->time * 256;
  F64 downLen = 300;
  F64 dir, r = 128;
  F64 circumLen = pi*r;
  if (speed < downLen) {
    mob->pos.y = speed;
    mob->rot = ROT_S;
  } else if (speed < downLen+circumLen) {
    speed -= downLen;
    F64 lx = mob->pos.x;
    dir = speed/circumLen*pi-ROT_S;
    mob->pos.x = mob->origin_x+r + Sin(dir)*r;
    mob->pos.y = downLen + Cos(dir)*r;
    mob->rot = -dir;
    mob->vel.x = lx - mob->pos.x;
  } else {
    speed -= downLen + circumLen;
    dir = circumLen/circumLen*pi-ROT_S;
    mob->pos.x = mob->origin_x+r + Sin(dir)*r;
    mob->pos.y = downLen + Cos(dir)*r - speed;
    mob->rot = ROT_N;
    mob->vel.x = 0;
  }
}

U0 MoveLoop(World*, Mob *mob, F64 delta) {
  mob->time += delta;
  F64 speed = mob->time * 256;
  F64 downLen = 180;
  F64 lx, ly, dir, r = 160;
  F64 circumLen = pi*r;
  F64 rots = 2.50;
  if (speed < downLen) {
    mob->pos.y = speed;
    mob->rot = ROT_S;
  } else if (speed < downLen+circumLen*rots) {
    speed -= downLen;
    lx = mob->pos.x;
    ly = mob->pos.y;
    mob->pos.x = mob->origin_x + r + Cos(speed/circumLen*pi-pi)*r;
    mob->pos.y = downLen - Sin(speed/circumLen*pi-pi)*r;
    dir = speed/circumLen*pi-ROT_S;
    mob->rot = -dir;
    //mob->vel.x = lx - mob->pos.x;
    //mob->vel.x = Cos(speed/circumLen*pi-pi);
    mob->vel.x = -1; //-Abs(lx - mob->pos.x);
  } else {
    speed -= downLen + circumLen*rots;
    mob->pos.x = mob->origin_x + r + Cos(circumLen*rots/circumLen*pi-pi)*r + speed;
    mob->pos.y = downLen - Sin(circumLen*rots/circumLen*pi-pi)*r;
    mob->rot = 0;
    mob->vel.x = 0;
  }
}

U0 MoveSine(World*, Mob *mob, F64 delta) {
  mob->time += delta;
  F64 addX = Sin(mob->time*2)*2;
  mob->rot = Arg(addX, 1.536); // Y=96*0.016, using delta causes rot to jitter
  mob->pos.x += addX;
  mob->pos.y = mob->time*96;
}

U0 MoveBoss0(World*, Mob *mob, F64 delta) {
  mob->time += delta;
  F64 speed = mob->time * 32 - 128;
  F64 downLen = 100;
  mob->rot = ROT_S;
  //F64 friction = 1.0 - 1.0 * 1 * delta;
  if (speed < downLen) {
    mob->pos.y = speed;
  } else {
    mob->pos.x += Sin(mob->time*2)*2;
    //mob->vel.x *= friction;
    mob->flags = 0;
  }
}

U0 MoveBoss1(World*, Mob *mob, F64 delta) {
  mob->time += delta;
  F64 downLen = 5.0;
  mob->rot = ROT_S;
  if (mob->time < downLen) {
    mob->pos.y = mob->time*(64+128)/downLen - 128;
    mob->rot = ROT_S;
  } else {
    F64 tt = (mob->time-downLen)*1.4;
    mob->pos.x = Sin(tt)*(SCX-64) + SCX;
    mob->pos.y = Cos(tt+pi)*32 + 64;
    mob->rot = mob->time;
    mob->vel.x = Cos(tt) * 0.3;
    mob->vel.y = Sin(tt) * 0.3;
    mob->flags = 0;
  }
}

U0 MoveNone(World*, Mob*, F64) {}

U0 ShootPlayer(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    mob->shoot_ttl = 1.33;
    F64 rad = Arg(w->player.pos.x-mob->gunX, w->player.pos.y-mob->gunY);
    AddBulletRad(mob->gunX,mob->gunY,rad,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE8);
  }
}

U0 ShootCircle(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    I64 i;
    switch (mob->mode) {
      case 0:
        mob->mode++;
        mob->shoot_ttl = 0.2;
        for (i=0; i<16; i++)
           AddBulletRad(mob->gunX,mob->gunY,i*pi*2/16,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE8);
        break;
      case 1:
        mob->mode++;
        mob->shoot_ttl = 0.2;
        for (i=0; i<16; i++)
           AddBulletRad(mob->gunX,mob->gunY,i*pi*2/16,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE8);
        break;
      case 2:
        mob->mode = 0;
        mob->shoot_ttl = 1.66;
        for (i=0; i<16; i++)
           AddBulletRad(mob->gunX,mob->gunY,i*pi*2/16,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE8);
        break;
    }
  }
}

U0 ShootPlayerBurst(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    if (mob->mode < 3) {
      mob->mode++;
      mob->shoot_ttl = 0.1;
    } else {
      mob->mode = 0;
      mob->shoot_ttl = 1.66;
    }
    F64 rad = Arg(w->player.pos.x-mob->gunX, w->player.pos.y-mob->gunY);
    AddBulletRad(mob->gunX,mob->gunY,rad,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE8);
  }
}

U0 ShootStraight(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    mob->shoot_ttl = 1.0;
    AddBulletRad(mob->pos.x,mob->pos.y, ROT_S, &w->bulletsM,BULLET_TYPE_MOB_CIRCLE8);
  }
}

// ShootBoss0 is pincer fire
U0 ShootBoss0(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    F64 rad = Arg(w->player.pos.x-mob->gunX, w->player.pos.y-mob->gunY);
    switch (mob->mode) {
      case 0:
        mob->mode = 4;
        mob->shoot_ttl = 1.0;
        AddBulletRad(mob->gunX,mob->gunY,rad,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
        break;
      case 1:
        mob->mode--;
        mob->shoot_ttl = 0.2;
        AddBulletRad(mob->gunX,mob->gunY,rad+pi/64,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
        AddBulletRad(mob->gunX,mob->gunY,rad-pi/64,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
        break;
      case 2:
        mob->mode--;
        mob->shoot_ttl = 0.2;
        AddBulletRad(mob->gunX,mob->gunY,rad+pi/32,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
        AddBulletRad(mob->gunX,mob->gunY,rad-pi/32,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
        break;
      case 3:
        mob->mode--;
        mob->shoot_ttl = 0.2;
        AddBulletRad(mob->gunX,mob->gunY,rad+pi/16,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
        AddBulletRad(mob->gunX,mob->gunY,rad-pi/16,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
        break;
      case 4:
        mob->mode--;
        mob->shoot_ttl = 0.2;
        AddBulletRad(mob->gunX,mob->gunY,rad+pi/10,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
        AddBulletRad(mob->gunX,mob->gunY,rad-pi/10,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
        break;
    }
  }
}

// ShootBoss1 is beefed up ShootCircle
U0 ShootBoss1(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    if (mob->mode < 3) {
      mob->mode++;
      mob->shoot_ttl = 0.2;
    } else {
      mob->mode = 0;
      mob->shoot_ttl = 1.66;
    }

    I64 i;
    for (i=0; i<16; i++)
      AddBulletRad(mob->gunX,mob->gunY,i*pi*2/16,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
  }
}

// ShootBoss2 is rapid fire
U0 ShootBoss2(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    if (mob->mode < 13) {
      mob->mode++;
      mob->shoot_ttl = 0.08;
    } else {
      mob->mode = 0;
      mob->shoot_ttl = 1.66;
    }
    F64 rad = Arg(w->player.pos.x-mob->gunX, w->player.pos.y-mob->gunY);
    AddBulletRad(mob->gunX,mob->gunY,rad,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
  }
}

// ShootBoss3 is sweep shot
U0 ShootBoss3(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    if (mob->mode < 48) {
      mob->mode++;
      mob->shoot_ttl = 0.1;
      AddBullet(mob->gunX,mob->gunY,-pi+mob->mode*pi*2/48,1,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
    } else {
      mob->mode = 0;
      mob->shoot_ttl = 1.66;
    }
  }
}

// ShootBoss4 is pincer fire (fast)
U0 ShootBoss4(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    F64 rad = Arg(w->player.pos.x-mob->gunX, w->player.pos.y-mob->gunY);
    switch (mob->mode) {
      case 0:
        mob->mode++;
        mob->shoot_ttl = 0.1;
        AddBulletRad(mob->gunX,mob->gunY,rad+pi/10,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        AddBulletRad(mob->gunX,mob->gunY,rad-pi/10,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        break;
      case 1:
        mob->mode++;
        mob->shoot_ttl = 0.1;
        AddBulletRad(mob->gunX,mob->gunY,rad+pi/16,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        AddBulletRad(mob->gunX,mob->gunY,rad-pi/16,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        break;
      case 2:
        mob->mode++;
        mob->shoot_ttl = 0.1;
        AddBulletRad(mob->gunX,mob->gunY,rad+pi/22,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        AddBulletRad(mob->gunX,mob->gunY,rad-pi/22,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        break;
      case 3:
        mob->mode++;
        mob->shoot_ttl = 0.1;
        AddBulletRad(mob->gunX,mob->gunY,rad+pi/32,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        AddBulletRad(mob->gunX,mob->gunY,rad-pi/32,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        break;
      case 4:
        mob->mode++;
        mob->shoot_ttl = 0.1;
        AddBulletRad(mob->gunX,mob->gunY,rad+pi/64,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        AddBulletRad(mob->gunX,mob->gunY,rad-pi/64,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        break;
      case 5:
        mob->mode = 0;
        mob->shoot_ttl = 1.0;
        AddBulletRad(mob->gunX,mob->gunY,rad,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
        break;
    }
  }
}

// ShootBoss5 is beefer ShootCircle
U0 ShootBoss5(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    if (mob->mode < 3) {
      mob->mode++;
      mob->shoot_ttl = 0.2;
    } else {
      mob->mode = 0;
      mob->shoot_ttl = 1.66;
    }

    I64 i;
    for (i=0; i<24; i++)
      AddBulletRad(mob->gunX,mob->gunY,i*pi*2/24,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
  }
}

// ShootBoss6 is beefer rapid fire
U0 ShootBoss6(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    if (mob->mode < 20) {
      mob->mode++;
      mob->shoot_ttl = 0.08;
    } else {
      mob->mode = 0;
      mob->shoot_ttl = 0.66;
    }
    F64 rad = Arg(w->player.pos.x-mob->gunX, w->player.pos.y-mob->gunY);
    AddBulletRad(mob->gunX,mob->gunY,rad,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
    AddBulletRad(mob->gunX,mob->gunY,rad+pi/32,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
    AddBulletRad(mob->gunX,mob->gunY,rad-pi/32,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
  }
}

// ShootBoss7 is beefer sweep shot
U0 ShootBoss7(World *w, Mob *mob, F64 delta) {
  mob->shoot_ttl -= delta;
  if (mob->flags == 0 && mob->shoot_ttl <= 0) {
    SetSnd(SND_MOB_BULLET);
    if (mob->mode < 48) {
      mob->mode++;
      mob->shoot_ttl = 0.1;
      AddBullet(mob->gunX,mob->gunY,-pi+mob->mode*pi*2/48,1,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
      AddBullet(mob->gunX,mob->gunY,pi-mob->mode*pi*2/48,1,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16_F);
    } else {
      mob->mode = 0;
      mob->shoot_ttl = 0.5;
      I64 i;
      for (i=0; i<24; i++)
        AddBulletRad(mob->gunX,mob->gunY,i*pi*2/24,&w->bulletsM,BULLET_TYPE_MOB_CIRCLE16);
    }
  }
}

U0 ShootNone(World*, Mob*, F64) {}

#define SHOOT_PLAYER       0
#define SHOOT_CIRCLE       1
#define SHOOT_PLAYER_BURST 2
#define SHOOT_NONE         3
#define SHOOT_BOSS0        4
#define SHOOT_BOSS1        5
#define SHOOT_BOSS2        6
#define SHOOT_BOSS3        7
#define SHOOT_BOSS4        8
#define SHOOT_BOSS5        9
#define SHOOT_BOSS6        10
#define SHOOT_BOSS7        11
U0 (*ShootPatterns)(World*, Mob*, F64)[12] = {
  &ShootPlayer,
  &ShootCircle,
  &ShootPlayerBurst,
  &ShootNone,
  &ShootBoss0,
  &ShootBoss1,
  &ShootBoss2,
  &ShootBoss3,
  &ShootBoss4,
  &ShootBoss5,
  &ShootBoss6,
  &ShootBoss7,
};

#define MOVE_STRAIGHT 0
#define MOVE_LD       1
#define MOVE_RD       2
#define MOVE_STATIC   3
#define MOVE_SINE     4
#define MOVE_BIGU     5
#define MOVE_LOOP     6
#define MOVE_BOSS0    7
#define MOVE_BOSS1    8
#define MOVE_NONE     9
U0 (*MovePatterns)(Mob*, F64)[MOVE_NONE+1] = {
  &MoveStraight,
  &MoveLD,
  &MoveRD,
  &MoveStatic,
  &MoveSine,
  &MoveBigU,
  &MoveLoop,
  &MoveBoss0,
  &MoveBoss1,
  &MoveNone
};

public U0 AddMob(Vector *mobs, LevelMob *data, U8 id, U8 flags, I16 offX, I16 offY) {
  gW.lvlMobsSpawned++;
  Mob mob;
  mob.pos.x = data->x;
  mob.pos.y = data->y;
  mob.vel.x = 0.0;
  mob.vel.y = 0.0;
  mob.origin_x = data->x;
  mob.time = 0.0;
  mob.centroidCnt = gAssets.mobModels[data->model].cCnt;
  mob.offX = offX;
  mob.offY = offY;
  mob.obj = &gAssets.mobModels[data->model];
  mob.move = MovePatterns[data->move];
  mob.shoot = ShootPatterns[data->shoot];
  mob.health = MobDefaults[data->model].health;
  mob.shoot_ttl = 0.0;
  mob.hit_ttl = 0.0;
  mob.drop = data->drop;
  mob.scoreValue = 100;
  mob.id = id;
  mob.mode = 0;
  mob.flags = flags;
  VectorAdd(mobs, &mob);
}

U0 AddBoss0() {
  LevelMob mob;
  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS0;
  mob.move = MOVE_BOSS0;
  mob.shoot = SHOOT_BOSS0;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 1, MOBFLAG_INVULN, 0, 0);

  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS0_GUN;
  mob.move = MOVE_NONE;
  mob.shoot = SHOOT_PLAYER_BURST;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, 100);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, 50);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, -50);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, -100);
}

U0 AddBoss1() {
  LevelMob mob;
  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS1;
  mob.move = MOVE_BOSS1;
  mob.shoot = SHOOT_BOSS1;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 1, MOBFLAG_INVULN, 0, 0);
}

U0 AddBoss2() {
  LevelMob mob;
  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS2;
  mob.move = MOVE_BOSS0;
  mob.shoot = SHOOT_BOSS2;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 1, MOBFLAG_INVULN, 0, 0);

  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS0_GUN;
  mob.move = MOVE_NONE;
  mob.shoot = SHOOT_PLAYER_BURST;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, -20, 70);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 20, 60);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 20, -60);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, -20, -70);
}

U0 AddBoss3() {
  LevelMob mob;
  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS3;
  mob.move = MOVE_BOSS0;
  mob.shoot = SHOOT_BOSS3;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 1, MOBFLAG_INVULN, 0, 0);

  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS0_GUN;
  mob.move = MOVE_NONE;
  mob.shoot = SHOOT_PLAYER_BURST;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, 125);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, 90);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, -90);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, -125);
}

U0 AddBoss4() {
  LevelMob mob;
  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS4;
  mob.move = MOVE_BOSS0;
  mob.shoot = SHOOT_BOSS4;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 1, MOBFLAG_INVULN, 0, 0);

  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS0_GUN;
  mob.move = MOVE_NONE;
  mob.shoot = SHOOT_PLAYER_BURST;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, 100);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, 50);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, -50);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, -100);
}

U0 AddBoss5() {
  LevelMob mob;
  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS5;
  mob.move = MOVE_BOSS1;
  mob.shoot = SHOOT_BOSS5;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 1, MOBFLAG_INVULN, 0, 0);
}

U0 AddBoss6() {
  LevelMob mob;
  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS6;
  mob.move = MOVE_BOSS0;
  mob.shoot = SHOOT_BOSS6;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 1, MOBFLAG_INVULN, 0, 0);

  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS0_GUN;
  mob.move = MOVE_NONE;
  mob.shoot = SHOOT_PLAYER_BURST;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, -20, 70);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 20, 60);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 20, -60);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, -20, -70);
}

U0 AddBoss7() {
  LevelMob mob;
  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS7;
  mob.move = MOVE_BOSS0;
  mob.shoot = SHOOT_BOSS7;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 1, MOBFLAG_INVULN, 0, 0);

  mob.x = 320;
  mob.y = 0;
  mob.model = MOB_BOSS0_GUN;
  mob.move = MOVE_NONE;
  mob.shoot = SHOOT_PLAYER_BURST;
  mob.drop = 0;
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, 125);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, 90);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, -90);
  AddMob(&gW.mobs, &mob, 2, MOBFLAG_INVULN, 0, -125);
}

U0 (*AddBossFuncs)()[LEVEL_TOTAL] = {
  &AddBoss0,
  &AddBoss1,
  &AddBoss2,
  &AddBoss3,
  &AddBoss4,
  &AddBoss5,
  &AddBoss6,
  &AddBoss7,
};

U0 UpdateSubBoss() {
  I64 i, bi;
  Mob *mobs = gW.mobs.d;
  for (bi=0; bi<gW.mobs.len; bi++) {
    if (mobs[bi].id == 1)
      goto found_boss;
  }
  goto skip_boss;
found_boss:

  for (i=0; i<gW.mobs.len; i++) {
    if (mobs[i].id == 2) {
      mobs[i].pos.x = mobs[bi].pos.x;
      mobs[i].pos.y = mobs[bi].pos.y;
      mobs[i].vel.x = mobs[bi].vel.x;
      mobs[i].vel.y = mobs[bi].vel.y;
      mobs[i].rot = mobs[bi].rot;
      mobs[i].hit_ttl = mobs[bi].hit_ttl;
      mobs[i].flags = mobs[bi].flags;
    }
  }
skip_boss:
}

#endif
