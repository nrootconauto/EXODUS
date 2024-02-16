#ifndef ANIMATION_HC
#define ANIMATION_HC
/*
#include "Px/NManStand1"
#include "Px/NManStand2"
#include "Px/NManWalk1"
#include "Px/NManWalk2"
#include "Px/NManWalk3"
#include "Px/NManWalk4"
#include "Px/NManJump1"
#include "Px/NManJump2"
#include "Px/NManJump3"
#include "Px/NManJump4"
#include "Px/NManFall"
#include "Px/BlobIdle1"
#include "Px/BlobIdle2"
#include "Px/BlobFlap1"
#include "Px/BlobFlap2"
#include "Px/BlobFlap3"

#include "Px/PxExplosion1"
#include "Px/PxExplosion2"
#include "Px/PxExplosion3"
#include "Px/PxExplosion4"
#include "Px/PxExplosion5"
#include "Px/PxExplosion6"

#include "Px/Car1"
#include "Px/Car2"
#include "Px/Car3"
*/
class AnimTemplate {
  I32 cap;
  F64 delay;
  PxData **frames;
};

class Anim {
  I32 frame;
  I32 cap;
  F64 delay;
  F64 ttl;
  PxData **frames;
  AnimTemplate *next;
};

PxData *ExplosionFrames[6] = {&PxExplosion6,&PxExplosion5,&PxExplosion4,&PxExplosion3,&PxExplosion2,&PxExplosion1};
PxData *NManWalkFrames[4] = {&NManWalk1,&NManWalk2,&NManWalk3,&NManWalk4};
PxData *NManStandFrames[4] = {&NManStand1,&NManStand2,&NManStand1,&NManStand1};
PxData *NManJumpFrames[4] = {&NManJump1,&NManJump2,&NManJump3,&NManJump4};
PxData *NManFallFrames[1] = {&NManFall};

PxData *BlobIdleFrames[2] = {&BlobIdle1,&BlobIdle2};
AnimTemplate BlobIdleAnim = {2, 0.4, BlobIdleFrames};

PxData *BlobFlapFrames[4] = {&BlobFlap1,&BlobFlap1,&BlobFlap2,&BlobFlap3};
AnimTemplate BlobFlapAnim = {4, 0.2, BlobFlapFrames};

PxData *CarFrames[6] = {&Car1,&Car2,&Car3,&Car3,&Car2,&Car1};
AnimTemplate CarAnim = {6, 0.2, CarFrames};

public U0 SetAnimNManStand(Anim *anim) {
  anim->frame = 0;
  anim->cap = 4;
  anim->delay = 0.2;
  anim->ttl = 0.2;
  anim->frames = NManStandFrames;
  anim->next = NULL;
}

public U0 SetAnimNManWalkR(Anim *anim) {
  anim->frame = 0;
  anim->cap = 4;
  anim->delay = 0.1;
  anim->ttl = 0.1;
  anim->frames = NManWalkFrames;
  anim->next = NULL;
}

public U0 SetAnimNManJump(Anim *anim) {
  anim->frame = 0;
  anim->cap = 4;
  anim->delay = 0.1;
  anim->ttl = 0.1;
  anim->frames = NManJumpFrames;
  anim->next = NULL;
}

public U0 SetAnimNManFall(Anim *anim) {
  anim->frame = 0;
  anim->cap = 1;
  anim->delay = 1.0;
  anim->ttl = 1.0;
  anim->frames = NManFallFrames;
  anim->next = NULL;
}

public U0 SetAnim(Anim *anim, AnimTemplate *srcAnim, AnimTemplate *next) {
  anim->frame = 0;
  anim->cap = srcAnim->cap;
  anim->delay = srcAnim->delay;
  anim->ttl = srcAnim->delay;
  anim->frames = srcAnim->frames;
  anim->next = next;
}

public U0 UpdateAnim(Anim *anim, F64 delta) {
  anim->ttl -= 1.0 * delta;
  if (anim->ttl <= 0.0) {
    anim->ttl = anim->delay;
    anim->frame++;
    if (anim->frame >= anim->cap) {
      if (anim->next)
        SetAnim(anim, anim->next, NULL);
      else
        anim->frame = 0;
    }
  }
}

public U0 DrawAnim(CDC *dc, Anim *anim, I32 x, I32 y, Bool flip) {
  if (flip) {
    PxBlotFlipX(dc, anim->frames[anim->frame], x, y);
  } else {
    PxBlot(dc->body, anim->frames[anim->frame], x, y);
  }
}

#endif