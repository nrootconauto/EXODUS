#ifndef PICKUP_HC
#define PICKUP_HC

#include "Collision"
#include "Globals"
#include "Sound"

#define PICKUP_SPEED 32
#define PICKUP_SIZE 32
#define PICKUP_HSIZE 16

#define CREDIT_SCORE 100

U8 PICKUP_UPGRADE_ROTATION[3] = {PICKUP_UPGRADE_SHOT,PICKUP_UPGRADE_SPREAD,PICKUP_UPGRADE_LASER};

public U0 AddPickup(I32 x, I32 y, I8 type) {
  Pickup pickup;
  pickup.time = 0;
  pickup.pos.x = x;
  pickup.pos.y = y;
  pickup.w = gAssets.pickupPx[type]->width;
  pickup.h = gAssets.pickupPx[type]->height;
  pickup.type = type;
  VectorAdd(&gW.pickups, &pickup);
}

public U0 DrawPickups(U8 *fb, Pickup *pickups, I64 cnt) {
  Pickup *last = pickups+cnt;
  for (; pickups<last; pickups++) {
    F64 hw = ToF64(pickups->w)/2;
    F64 hh = ToF64(pickups->h)/2;
    PxBlot(fb, gAssets.pickupPx[pickups->type], ToI64(pickups->pos.x-hw), ToI64(pickups->pos.y-hh));
  }
}

public U0 UpdatePickups(F64 delta) {
  I64 i=0;
  CD2I32 ppos;
  ppos.x = gW.player.pos.x;
  ppos.y = gW.player.pos.y;
  while (i<gW.pickups.len) {
    Pickup *pickup = gW.pickups.d(Pickup*) + i;
    pickup->time += delta;
    if (pickup->type == PICKUP_UPGRADE_SHOT ||
        pickup->type == PICKUP_UPGRADE_SPREAD ||
        pickup->type == PICKUP_UPGRADE_LASER) {
      pickup->type = PICKUP_UPGRADE_ROTATION[ToI64(pickup->time/2)%3];
    }
    if ((pickup->type == PICKUP_CREDIT || pickup->type == PICKUP_BOMB) && CheckCollideCirclePoint(pickup->pos.x,pickup->pos.y,128,ppos)) {
      F64 dx = gW.player.pos.x-pickup->pos.x;
      F64 dy = gW.player.pos.y-pickup->pos.y;
      F64 len = Sqrt(dx*dx + dy*dy);
      dx /= len;
      dy /= len;
      pickup->pos.x += dx * 4;
      pickup->pos.y += dy * 4;
    } else {
      pickup->pos.x += Sin(pickup->time);
      pickup->pos.y += delta * PICKUP_SPEED;
    }

    F64 hw = ToF64(pickup->w)/2;
    F64 hh = ToF64(pickup->h)/2;
    if (pickup->pos.y >= FB_H+PICKUP_SIZE) {
      VectorDel(&gW.pickups, i);
    } else if (CheckCollideCircleRec(gW.player.pos.x,gW.player.pos.y,PLAYER_HIT_RADIUS,
                pickup->pos.x-hw,pickup->pos.x+hw,
                pickup->pos.y-hh,pickup->pos.y+hh)) {
      switch (pickup->type) {
        case PICKUP_CREDIT:
          SetSnd(SND_CREDIT);
          gW.score += CREDIT_SCORE;
          gW.lvlScore += CREDIT_SCORE;
          break;
        case PICKUP_BOMB:
          SetSnd(SND_UPGRADE);
          gW.score += CREDIT_SCORE;
          gW.lvlScore += CREDIT_SCORE;
          gW.bombs++;
          break;
        case PICKUP_UPGRADE_SHOT:
          SetSnd(SND_UPGRADE);
          switch (gW.activeWeapon) {
            case WEAPON_SHOT0:
              gW.activeWeapon = WEAPON_SHOT1;
              break;
            case WEAPON_SHOT1:
              gW.activeWeapon = WEAPON_SHOT2;
              break;
            case WEAPON_SHOT2:
              break;
            default:
              gW.activeWeapon = WEAPON_SHOT0;
          }
          break;
        case PICKUP_UPGRADE_SPREAD:
          SetSnd(SND_UPGRADE);
          switch (gW.activeWeapon) {
            case WEAPON_SPREAD0:
              gW.activeWeapon = WEAPON_SPREAD1;
              break;
            case WEAPON_SPREAD1:
              gW.activeWeapon = WEAPON_SPREAD2;
              break;
            case WEAPON_SPREAD2:
              break;
            default:
              gW.activeWeapon = WEAPON_SPREAD0;
          }
          break;
        case PICKUP_UPGRADE_LASER:
          SetSnd(SND_UPGRADE);
          switch (gW.activeWeapon) {
            case WEAPON_LASER0:
              gW.activeWeapon = WEAPON_LASER1;
              break;
            case WEAPON_LASER1:
              gW.activeWeapon = WEAPON_LASER2;
              break;
            case WEAPON_LASER2:
              break;
            default:
              gW.activeWeapon = WEAPON_LASER0;
          }
          break;
      }
      VectorDel(&gW.pickups, i);
    } else {
      i++;
    }
  }
}

#endif
