Cd(__DIR__);;

//#define DEBUG

#exe {
#ifdef DEBUG
  Option(OPTf_WARN_UNUSED_VAR, ON);
  Option(OPTf_WARN_PAREN, ON);
#endif
}
#include "Controls"
Controls gCtrl;
#include "PxBlot"
class MapTemplate {
  U32 width;
  U32 height;
  PxData **px;
  U8 *flags;
  U8 *tileType;
  U8 *hp;
  U32 spawnerCount;
  CD2I32 *spawners;
  CD2I32 spawn;
};
#include "LoadBin"
#include "UI"
#include "GameInput"
#include "Title"
#include "Draw"
#include "Noise"

#ifdef DEBUG
  #include "CrunkComm"
#endif

// Globals
World gW;
UI gUI;
I8 noiseMap[640*640];
U8 noiseMapLevel[640*640];
U8 tex1[640*480];

F64 gDebugF640=0;
F64 gDebugF641=0;
I64 gDebugI640=0;
I64 gDebugI641=0;

Anim carAnim;

TextData txtInstructions;
txtInstructions.timer = 0;
txtInstructions.speed = 48.0;
txtInstructions.str = "-INSTRUCTIONS-
* GET TO THE END STAGE DOOR
* USE LASER GUN TO DESTROY
   ENEMIES AND DIRT BLOCKS
* USE GRAPPLE HOOK TO
   SWING OFF MOST BLOCKS
* HOLD JUMP MID-AIR,
   RELEASE WHILE HOLDING
   DESIRED DIRECTION

-CONTROLS-
LEFT MOUSE: USE ITEM
WASD: MOVEMENT
SPACE: (DOUBLE) JUMP
#: TOOLBAR
I: INVENTORY
M: KILL SOUND
ESC: CLOSE MENU
SHIFT+ESC: QUIT";

TextData txtDead;
txtDead.timer = 0;
txtDead.speed = 32.0;
txtDead.str = "DEAD";

TextData txtDeadPressSpace;
txtDeadPressSpace.timer = 0;
txtDeadPressSpace.speed = 32.0;
txtDeadPressSpace.str = "PRESS SPACE TO RESTART";

U0 QuitGame() {
  gW.quitGame = TRUE;
}

U0 PlayerKill() {
  if (gW.player.state != STATE_DEAD) {
    txtDead.timer = 0;
    txtDeadPressSpace.timer = 0;
  }
  gW.player.state = STATE_DEAD;
  DebrisAddRand(&gW.debris, gW.player.pos.x+gW.player.size.x>>1,
                gW.player.pos.y+gW.player.size.y>>1, 128, 8);
}

U0 ChangeLevel(I64 i) {
  gW.activeLvl = Levels[i];
  InitLevel(&gW, gW.activeLvl, noiseMapLevel);
  gW.player.health = 100;
  gW.player.pos.x = gW.level.spawn.x;
  gW.player.pos.y = gW.level.spawn.y;
  gW.player.vel.x = 0;
  gW.player.vel.y = 0;
  gW.player.dJumpAvail = FALSE;
  gW.player.dJumpSpent = FALSE;
  gW.player.state = STATE_STANDING;
  gW.grapple.active = FALSE;
  gW.grapple.hooked = FALSE;
  StrPrint(gW.levelStr, "LEVEL: %d", gW.currentLevel);

  gW.cam.x = gW.player.pos.x+gW.player.size.x>>1;
  gW.cam.y = gW.player.pos.y+gW.player.size.y>>1;
  UpdatePxUse(&gW.player);
}

U0 TriggerLevelEnd() {
  SetSnd(SND_LVL_END);
  gW.currentLevel++;
  if (gW.currentLevel == LEVELS_TOTAL) {
    InitEndScreen();
  } else {
    ChangeLevel(gW.currentLevel);
  }
}

U0 DmgPlayer(F64 dmg) {
  DebrisAddRand(&gW.debris, gW.player.pos.x+gW.player.size.x>>1,
                gW.player.pos.y+gW.player.size.y>>1, 128, 8);
  gW.player.health -= dmg;
  if (gW.player.health <= 0)
    PlayerKill();
}

U0 ApplyPlayerGravity(F64 delta) {
  CD2 playerOffset;
  playerOffset.x = gW.player.pos.x+8;
  playerOffset.y = gW.player.pos.y+16;
  CD2 length2;
  length2.x = playerOffset.x-gW.grapple.pos.x;
  length2.y = playerOffset.y-gW.grapple.pos.y;
  F64 length = CD2Magnitude(&length2);
  if (length >= gW.grapple.length && gW.grapple.hooked) {
//  if (gW.grapple.hooked) {
    CD2 gravity;
    gravity.x = 0;
    gravity.y = 350 * delta;
    CD2 perp;
    CD2Perpendicular(&gW.grapple.pos, &playerOffset, &perp);
    CD2DotDirection(&gravity, &perp);
    gW.player.vel.x += perp.x;
    gW.player.vel.y += perp.y;
#ifdef DEBUG
//CommPrint("gravx: %.2f %.2f\n", gravity.x, gravity.y);
#endif
  } else {
    gW.player.vel.y += 350 * delta;
  }
}

U0 MouseToTile(CD2I32 *tile) {
  CD2I32 camI32;
  camI32.x = gW.cam.x;
  camI32.y = gW.cam.y;
  tile->x = (ms.pos.x+camI32.x-320)/16;
  tile->y = (ms.pos.y-8+camI32.y-240)/16;
}

Bool TileCheckBounds(CD2I32 pos) {
  if (pos.x >= 0 && pos.y >= 0 &&
      pos.x < gW.level.width &&
      pos.y < gW.level.height) {
    return TRUE;
  }
  return FALSE;
}

I64 TileToIndex(CD2I32 pos) {
  return pos.y*gW.level.width+pos.x;
}

Bool DestroyBlock(I64 ti, CD2I32 tilePos) {
  if (gW.level.tileType[ti] == TILE_COOLER1) {
    I64 i;
    Cooler *coolers = gW.coolers.d;
    for (i=0; i<gW.coolers.len; i++) {
      if (coolers[i].pos.x == tilePos.x && coolers[i].pos.y == tilePos.y) {
        VectorDel(&gW.coolers, i);
        break;
      }
    }
  }
  gW.level.px[ti] = NULL;
  gW.level.flags[ti] = TFLAG_NONE;
  gW.level.tileType[ti] = TILE_NULL;
  return TRUE;
}

U0 MineBlock(I64 ti, CD2I32 tilePos) {
  SetSnd(SND_MINE);
  DebrisAddRand(&gW.debrisEarth, tilePos.x*16+8, tilePos.y*16, 64, 8);
  I64 tileType = gW.level.tileType[ti];
  U32 dmg = 8;
  if (dmg >= gW.level.hp[ti]) {
    /* Spawn Drop */
    U64 rng = RandU64%100+1;
    if (rng <= TILES[tileType].dropChance) {
      F64 dir = RandI64%pi;
      ItemAdd(&gW.items, TILES[tileType].drop, 1,
              tilePos.x*16+8, tilePos.y*16+8,
              Cos(dir)*128, Sin(dir)*128);
    }
    DestroyBlock(ti, tilePos);
  } else {
    gW.level.hp[ti] -= dmg;
    I64 px = 4 - Ceil(ToF64(gW.level.hp[ti])/(TILES[tileType].hp/4)));
    if (TILES[tileType].dmgPx[px]) {
      gW.level.px[ti] = TILES[tileType].dmgPx[px];
    }
  }
}

U0 Shop() {
  TradeOpen(&gUI);
}

Bool CheckTileFlagOverlap(CD2 *pos, CD2I32 size, U8 flag) {
  I32 x, y;
  I32 xStart = pos->x/16;
  I32 xEnd = Ceil((pos->x+size.x)/16);
  I32 yStart = pos->y/16;
  I32 yEnd = Ceil((pos->y+size.y)/16);
  for (y=yStart; y<yEnd; y++) {
    if (y >= 0 && y <gW.level.height) {
      for (x=xStart; x<xEnd; x++) {
        if (x >= 0 && x < gW.level.width &&
            gW.level.flags[y*gW.level.width+x] & flag) {
          return TRUE;
        }
      }
    }
  }
  return FALSE;
}

Bool CheckTileFlagOverlapPoint(CD2I32 pos, U8 flag) {
  pos.x /= 16;
  pos.y /= 16;
  if (pos.x >= 0 && pos.y >= 0 &&
      pos.x < gW.level.width &&
      pos.y < gW.level.height &&
      gW.level.flags[pos.y*gW.level.width+pos.x] & flag) {
    return TRUE;
  }
  return FALSE;
}

U0 SetStateClimb() {
  if (gW.player.state != STATE_CLIMB) {
    gW.player.vel.x = 0;
    gW.player.vel.y = 0;
    gW.player.state = STATE_CLIMB;
  }
}

U0 HandleLadder() {
  if (gCtrl.cVel.y != 0) {
    if (CheckTileFlagOverlap(&gW.player.pos, gW.player.size, TFLAG_LADDER))
      SetStateClimb();
  }
}

U0 HandleMouse() {
  gUI.cursor = &CursorReg;
  if (gUI.mouseConsumed)
    return;
  CD2I32 tile;
  MouseToTile(&tile);
  Bool inMap=FALSE;
  if (TileCheckBounds(tile))
    inMap=TRUE;
  // Distance Limited Actions
  Bool inRange=FALSE;
  if (Abs(gW.player.pos.x+gW.player.size.x>>1-(tile.x*16+8)) < 24 &&
      Abs(gW.player.pos.y+gW.player.size.y>>1-(tile.y*16+8)) < 32) {
    inRange=TRUE;
  }
  I64 ti = TileToIndex(tile);
  if (inMap && inRange && gW.level.flags[ti] & TFLAG_SHOP) {
    if (gCtrl.mLDown) {
      Shop();
    } else {
      gUI.cursor = &CursorBuy;
    }
  } else {
    if (gCtrl.mLUp) {
      if (gW.grapple.active) {
        gW.grapple.active = FALSE;
        gW.grapple.hooked = FALSE;
      }
    } else if (ms.lb) {
      U8 itemType = gW.player.inv.items[gW.player.selItemSlot].id;
      if (itemType == ITEM_PICKAXE && inMap && inRange && gW.level.flags[ti] & TFLAG_MINABLE) {
        if (gW.player.cooldown > 0)
          return;
        gW.player.cooldown = 0.3;
        gW.player.pxUseRot = 0.3;
        MineBlock(ti, tile);
      } else if (itemType == ITEM_GUN) {
        // Fire Gun
        SetSnd(SND_LASER);
        Laser newLaser;
        newLaser.vel.x = Cos(gUI.lookRot)*600;
        newLaser.vel.y = Sin(gUI.lookRot)*600;
        newLaser.pos.x = gW.player.pos.x+8;
        newLaser.pos.y = gW.player.pos.y+16;
        VectorAdd(&gW.lasers, &newLaser);
      } else if (itemType == ITEM_GRAPPLE_GUN) {
        // Fire Grapple Gun
        if (gW.grapple.active == FALSE) {
          SetSnd(SND_GRAPPLE_FIRE);
          gW.grapple.active = TRUE;
          gW.grapple.hooked = FALSE;
          gW.grapple.vel.x = Cos(gUI.lookRot)*512;
          gW.grapple.vel.y = Sin(gUI.lookRot)*512;
          gW.grapple.pos.x = gW.player.pos.x+8;
          gW.grapple.pos.y = gW.player.pos.y+16;
        }
      } else if (itemType == ITEM_GRENADE) {
        Grenade newGrenade;
        newGrenade.vel.x = Cos(gUI.lookRot)*256;
        newGrenade.vel.y = Sin(gUI.lookRot)*256;
        newGrenade.pos.x = gW.player.pos.x+8;
        newGrenade.pos.y = gW.player.pos.y+16;
        newGrenade.rot = 0;
        newGrenade.ttl = 3;
        VectorAdd(&gW.grenades, &newGrenade);
      } else if (inMap && inRange && gItems[itemType].placeTile != TILE_NULL && gW.level.tileType[ti] == TILE_NULL) {
        // Place Block
        gW.player.pxUseRot = 1.0;
        SetTile(&gW.level, ti, gItems[itemType].placeTile);
        if (itemType == ITEM_COOLER) {
          Cooler newCooler;
          newCooler.pos.x = tile.x;
          newCooler.pos.y = tile.y;
          VectorAdd(&gW.coolers, &newCooler);
        }
      }
    }
  }
}

U0 CloseMenu() {
  if (gUI.flags&UI_INSTRUCTIONS_ENABLED)
    gUI.flags = 0;
  else if (gUI.flags&UI_INV_ENABLED)
    InventoryClose(&gUI, &gW);
  else if (gUI.flags&UI_TRADE_ENABLED)
    TradeClose(&gUI);
  else if (gUI.flags&UI_ESCMENU_ENABLED)
    gUI.flags = 0;
  else
    gUI.flags |= UI_ESCMENU_ENABLED;
}

U0 GameUpdate(F64 delta) {
  I64 i, x, y;

  gUI.mouse.x = ms.pos.x;
  gUI.mouse.y = ms.pos.y - 8;

  /* Face Direction */
  if (ms.pos.x >= 320) {
    gW.player.flags &= PFLAG_ALL^PFLAG_FACE_LEFT;
    gW.player.pxUseX = 7 + gW.player.pxUseOffset.x;
  } else {
    gW.player.flags |= PFLAG_FACE_LEFT;
    gW.player.pxUseX = 8 - gW.player.pxUseOffset.x;
  }

  gUI.lookRot = Arg(gUI.mouse.x-320, gUI.mouse.y-240);

  if (gCtrl.cEsc) {
    CloseMenu();
    gCtrl.cEsc = FALSE;
  }

  if (gCtrl.cTest0 == TRUE) {
    gCtrl.cTest0 = FALSE;
    OpenSimplex2S(Rand);
    for (i=0; i<640*480; i++) {
      x = i%640;
      y = i/640;
      noiseMap[i] = noise2_XBeforeY(ToF64(x)/gCtrl.cTest1, ToF64(y)/gCtrl.cTest1)*gCtrl.cTest2;
    }
  }

  if (gCtrl.cInv) {
    InventoryOpen(&gUI);
    gCtrl.cInv = FALSE;
  }

  if (gUI.flags&UI_INSTRUCTIONS_ENABLED) {
    txtInstructions.timer += delta;
    return;
  } else if (gUI.flags&UI_ESCMENU_ENABLED) {
    HandleEscMenu(&gUI.escMenu, &gCtrl);
    if (gUI.escMenu.buttonMainMenu.state == BUTTON_CLICKED) {
      InitTitle();
    }
    return;
  }

  if (gW.player.state == STATE_DEAD) {
    txtDead.timer += delta;
    txtDeadPressSpace.timer += delta;
  }

  gW.player.cooldown -= delta;
  if (gW.player.cooldown < 0)
    gW.player.cooldown = 0;

  gW.player.pxUseRot -= delta;
  if (gW.player.pxUseRot < 0)
    gW.player.pxUseRot = 0;

  // Handle Item Slot
  if (gCtrl.cNum >= 0) {
    gW.player.selItemSlot = gCtrl.cNum;
    UpdatePxUse(&gW.player);
    gCtrl.cNum = -1;
  }
  gUI.mouseConsumed = FALSE;

  ToolbarHandle(&gUI, &gCtrl, &gW);
  if (gUI.flags&UI_INV_ENABLED)
    InventoryHandle(&gUI, &gW.player.inv, &gCtrl, &gW);
  else if (gUI.flags&UI_TRADE_ENABLED)
    TradeHandle(&gUI, &gCtrl, &gW);
  else if (gUI.flags&UI_INSTRUCTIONS_ENABLED)
    gUI.mouseConsumed = TRUE;

  F64 vec;
  switch (gW.player.state) {
    case STATE_STANDING:
      gW.player.dJumpAvail = FALSE;
      gW.player.dJumpSpent = FALSE;
      if (gCtrl.cJump) {
        gW.player.state = STATE_JUMPING;
        if (gW.player.vel.y > -300)
          gW.player.vel.y = -300;
        SetAnimNManJump(&gW.player.anim);
      } else if (gCtrl.cVel.x != 0) {
        gW.player.state = STATE_WALKING;
        SetAnimNManWalkR(&gW.player.anim);
      }
      HandleMouse();
      HandleLadder();
      ApplyPlayerGravity(delta);
      break;
    case STATE_WALKING:
      gW.player.dJumpAvail = FALSE;
      gW.player.dJumpSpent = FALSE;
//      gW.player.flags &= PFLAG_NONE; // add extra flags here
      if (gCtrl.cJump) {
        gW.player.state = STATE_JUMPING;
        gW.player.vel.y -= 300;
        SetAnimNManJump(&gW.player.anim);
      } else if (gCtrl.cVel.x == 0) {
        if (gW.player.vel.x == 0) {
          gW.player.state = STATE_STANDING;
          SetAnimNManStand(&gW.player.anim);
        } else {
//          gW.player.state = STATE_STANDING;
//          SetAnimNManStand(&gW.player.anim);
        }
      }
      HandleMouse();
      HandleLadder();
      ApplyPlayerGravity(delta);
      break;
    case STATE_JUMPING:
      HandleMouse();
      if (gCtrl.cJump == FALSE) {
        gW.player.dJumpAvail = TRUE;
      } else if (gCtrl.cJump && !gW.player.dJumpSpent && gW.player.dJumpAvail) {
        gW.player.dJumpAvail = FALSE;
        gW.player.dJumpSpent = TRUE;
        gW.player.state = STATE_DJUMP_CHARGE;
        gW.player.vel.x = 0;
        gW.player.vel.y = 0;
        break;
      }
      if (gW.player.vel.y >= 0) {
        gW.player.state = STATE_FALLING;
        SetAnimNManFall(&gW.player.anim);
      }
      HandleLadder();
      ApplyPlayerGravity(delta);
      break;
    case STATE_FALLING:
      HandleMouse();
      if (gCtrl.cJump == FALSE) {
        gW.player.dJumpAvail = TRUE;
      } else if (gCtrl.cJump && !gW.player.dJumpSpent && gW.player.dJumpAvail) {
        gW.player.dJumpAvail = FALSE;
        gW.player.dJumpSpent = TRUE;
        gW.player.state = STATE_DJUMP_CHARGE;
        gW.player.vel.x = 0;
        gW.player.vel.y = 0;
        break;
      }
//      gW.player.flags &= PFLAG_NONE; // add extra flags here
      if (gW.player.vel.y <= 0) {
        gW.player.state = STATE_STANDING;
        SetAnimNManStand(&gW.player.anim);
      }
      HandleLadder();
      ApplyPlayerGravity(delta);
      break;
    case STATE_DJUMP_CHARGE:
      if (gCtrl.cJump == FALSE) {
        gW.player.state = STATE_DJUMP;
        if (gCtrl.cVel.x == 0 && gCtrl.cVel.y == 0)
          vec = Arg(0, -1);
        else
          vec = Arg(gCtrl.cVel.x, gCtrl.cVel.y);
        gW.player.vel.x = Cos(vec)*400;
        gW.player.vel.y = Sin(vec)*400;
      }
      break;
    case STATE_DJUMP:
      HandleMouse();
      if (gW.player.vel.y >= 0) {
        gW.player.state = STATE_FALLING;
        SetAnimNManFall(&gW.player.anim);
      }
      HandleLadder();
      ApplyPlayerGravity(delta);
      break;
    case STATE_CLIMB:
      HandleMouse();
      HandleLadder();
      ApplyDrag(&gW.player.vel.x, 256, delta);
      ApplyDrag(&gW.player.vel.y, 256, delta);
      if (Abs(gW.player.vel.y) < 128) {
        gW.player.vel.y += gCtrl.cVel.y * 512 * delta;
      }
      if (!CheckTileFlagOverlap(&gW.player.pos, gW.player.size, TFLAG_LADDER)) {
        gW.player.state = STATE_FALLING;
      }
      break;
    case STATE_DEAD:
      ApplyPlayerGravity(delta);
      if (gCtrl.cJump) {
        if (gW.currentLevel >= 0)
          ChangeLevel(gW.currentLevel);
        else
          InitSandbox();
      }
      break;
    default:
  }

  if (gW.player.state != STATE_DEAD) {
    if (gW.grapple.hooked) {
      if (Abs(gW.player.vel.x) < 300) {
        gW.player.vel.x += gCtrl.cVel.x * 1024 * delta;
      }
    } else if (gW.player.state != STATE_DJUMP_CHARGE) {
      // Apply Player Controls
      if (Abs(gW.player.vel.x) < 128) {
        gW.player.vel.x += gCtrl.cVel.x * 512 * delta;
      }
//      if (Abs(gW.player.vel.y) < 128) {
//        gW.player.vel.y += gCtrl.cVel.y * 512 * delta;
//      }
    }
  }

  // Apply Grapple Constraint
  CD2 length2;
  I64 ti;
  F64 dist;
  if (gW.grapple.active && gW.grapple.hooked) {
    CD2 playerOffset;
    playerOffset.x = gW.player.pos.x+8;
    playerOffset.y = gW.player.pos.y+16;
    length2.x = playerOffset.x-gW.grapple.pos.x;
    length2.y = playerOffset.y-gW.grapple.pos.y;
    F64 length = CD2Magnitude(&length2);
    if (length >= gW.grapple.length) {
      /* Get Perpendicular Direction */
      CD2 perp;
      CD2Perpendicular(&gW.grapple.pos, &playerOffset, &perp);
      CD2DotDirection(&gW.player.vel, &perp);
      CD2Normalize(&perp);
      dist = CD2Magnitude(&gW.player.vel);
      gW.player.vel.x = perp.x * dist;
      gW.player.vel.y = perp.y * dist;
#ifdef DEBUG
CommPrint("perpx %.2f perpy %.2f dist: %.2f pvel: %.2f %.2f\n", perp.x, perp.y, dist, gW.player.vel.x, gW.player.vel.y);
#endif
/*
     CD2 diff;
     diff.x = gW.grapple.pos.x - gW.player.pos.x+8;
     diff.y = gW.grapple.pos.y - gW.player.pos.y+16;
     dist = CD2Magnitude(&diff);
*/

//      if (length >= gW.grapple.length) {
        F64 moveDist = length - gW.grapple.length;
        CD2Normalize(&length2);
        length2.x *= moveDist;
        length2.y *= moveDist;
#ifdef DEBUG
//CommPrint(MFA_COM, "dist %f | moveDist: %f | diffy: %f\n", dist, moveDist, diff.y);
#endif
        gW.player.pos.x -= length2.x;
        gW.player.pos.y -= length2.y;
//      }
    }
  }

  // Update Spawners
  UpdateAnim(&carAnim, delta);
  Spawner *spawners = gW.spawners.d;
  for (i=0; i<gW.spawners.len; i++) {
    spawners[i].ttl -= delta;
    if (spawners[i].ttl <= 0) {
      spawners[i].ttl = SPAWNER_TTL;
      AddMob(&gW.mobs, &gW.cMobs, spawners[i].pos.x, spawners[i].pos.y);
    }
  }

  // Apply Player Velocity/Collision
  ApplyVelCollideTile(&gW.level, delta, &gW.player.pos, &gW.player.vel, gW.player.size.x, gW.player.size.y);

  // Mob AI
  MobAI(&gW, delta);

  Mob *mobs = gW.mobs.d;
  I64 ii;
  // Apply Mob Velocity/Collision
  for (i=0; i<gW.mobs.len; i++) {
    ApplyDrag(&mobs[i].vel.x, 48, delta);
    ApplyDrag(&mobs[i].vel.y, 48, delta);
    mobs[i].vel.y += 350 * delta; // Apply Gravity
    ApplyVelCollideTile(&gW.level, delta, &mobs[i].pos, &mobs[i].vel, mobs[i].size.x, mobs[i].size.y);
  }
  GenCMobs(gW.mobs.d, gW.mobs.len, gW.cMobs.d);

  // Process Player I-Frames
  gW.player.inv_ttl -= delta;
  if (gW.player.inv_ttl < 0)
    gW.player.inv_ttl=0;

  // Player Mob Collision
  F64 rot;
  Vec4 aabb1;
  if (gW.player.inv_ttl <= 0) {
  aabb1.x1 = gW.player.pos.x;
  aabb1.x2 = gW.player.pos.x + gW.player.size.x;
  aabb1.y1 = gW.player.pos.y;
  aabb1.y2 = gW.player.pos.y + gW.player.size.y;
  mobs = gW.mobs.d;
  Vec4 *cMobs = gW.cMobs.d;
  for (i=0; i<gW.cMobs.len; i++) {
    if (CheckCollisionAABB(&aabb1, &cMobs[i])) {
      SetSnd(SND_PLAYER_DMG);
      DmgPlayer(10);
      rot = Arg(gW.player.pos.x+gW.player.size.x>>1 - (mobs[i].pos.x+mobs[i].size.x>>1),
                gW.player.pos.y+gW.player.size.y>>1 - (mobs[i].pos.y+mobs[i].size.y>>1));
      gW.player.vel.x = Cos(rot) * 256;
      gW.player.vel.y = Sin(rot) * 256;
      gW.player.inv_ttl = 3;
      break;
    }
  }
  }
  // Laser Collision
  Laser *lasers = gW.lasers.d;
  mobs = gW.mobs.d;
  cMobs = gW.cMobs.d;
  for (i=0; i<gW.lasers.len;) {
    for (ii=0; ii<gW.cMobs.len; ii++) {
      if (CheckCollisionPoint(&cMobs[ii], &lasers[i].pos)) {
        SetSnd(SND_MOB_HIT);
        F64 angle = Arg(lasers[i].vel.x, lasers[i].vel.y);
        mobs[ii].vel.x += Cos(angle)*64;
        mobs[ii].vel.y += Sin(angle)*64;
        MobDmg(&gW, ii, 1);
        VectorDel(&gW.lasers, i);
        goto nextLaserCollision;
      }
    }
    i++;
nextLaserCollision:
  }

  for (i=0; i<gW.mobs.len;) {
    if (mobs[i].health <= 0) {
      VectorDel(&gW.mobs, i);
      VectorDel(&gW.cMobs, i);
      // TODO Create Gibs
      goto nextMobDeath;
    }
    i++;
nextMobDeath:
  }

  lasers = gW.lasers.d;
  spawners = gW.spawners.d;
  for (i=0; i<gW.lasers.len;) {
    for (ii=0; ii<gW.spawners.len; ii++) {
      Vec4 vec4;
      vec4.x1 = spawners[ii].pos.x;
      vec4.y1 = spawners[ii].pos.y;
      vec4.x2 = vec4.x+SPAWNER_W;
      vec4.y2 = vec4.y+SPAWNER_H;
      if (CheckCollisionPoint(&vec4, &lasers[i].pos)) {
        SetSnd(SND_MOB_HIT);
        SpawnerDmg(&gW, ii, 1);
        VectorDel(&gW.lasers, i);
        goto nextLaserCollisionSpawners;
      }
    }
    i++;
nextLaserCollisionSpawners:
  }

  // Update Camera
  gW.cam.x = gW.player.pos.x+gW.player.size.x>>1;
  gW.cam.y = gW.player.pos.y+gW.player.size.y>>1;

  ItemDrop *items = gW.items.d;
  CD2I32 tile;
  for (i=0; i<gW.items.len; i++, items++) {
    items->ttl += delta;
    ApplyDrag(&items->vel.x, 48, delta);
    items->vel.y += 350 * delta; // Apply Gravity
    ApplyVelCollideTileBounce(&gW.level, delta, &items->pos, &items->vel, 8, 8);
  }

  // Update Gibs
  Gib *gibs = gW.gibs.d;
  for (i=0; i<gW.gibs.len;) {
    gibs->ttl -= delta;
    if (gibs->ttl <= 0) {
      VectorDel(&gW.gibs, i);
      goto nextGib;
    }
    gibs->rot += gibs->vel.x/16 * delta;
    ApplyDrag(&gibs->vel.x, 48, delta);
    gibs->vel.y += 350 * delta; // Apply Gravity
    ApplyVelCollidePointTileBounce(&gW.level, delta, &gibs->pos, &gibs->vel);
    gibs++;
    i++;
nextGib:
  }

  // Update Grenades
  items = gW.items.d;
  Grenade *grenades = gW.grenades.d;
  for (i=0; i<gW.grenades.len;) {
    grenades->ttl -= delta;
    if (grenades->ttl <= 0) {
      SetSnd(SND_EXPLOSION);
      // Apply Explosion Damage
      for (ii=0; ii<gW.items.len; ii++) {
        dist = Abs(grenades->pos.x-items[ii].pos.x)+Abs(grenades->pos.y-items[ii].pos.y);
        if (dist < 128) {
          rot = Arg(items[ii].pos.x-grenades->pos.x, items[ii].pos.y-grenades->pos.y);
          items[ii].vel.x += Cos(rot)*100;
          items[ii].vel.y += Sin(rot)*100;
        }
      }
      for (tile.y=MaxI64(ToI64(grenades->pos.y/16)-4, 0); tile.y<MinI64(ToI64(grenades->pos.y)/16+4, gW.level.height); tile.y++) {
        for (tile.x=MaxI64(ToI64(grenades->pos.x)/16-4, 0); tile.x<MinI64(ToI64(grenades->pos.x)/16+4, gW.level.width); tile.x++) {
          ti = tile.y*gW.level.width + tile.x;
          if (gW.level.flags[ti] & TFLAG_BLOCK) {
            if (gW.level.flags[ti] & TFLAG_MINABLE)
              MineBlock(ti, tile);
          }
        }
      }

      // Add Explosion Animation
      Explosion newExp;
      newExp.pos.x = grenades->pos.x;
      newExp.pos.y = grenades->pos.y;
      newExp.ttl = 1;
      VectorAdd(&gW.explosions, &newExp);
      VectorDel(&gW.grenades, i);
      goto nextGrenade;
    }
    grenades->rot += grenades->vel.x/16 * delta;
    ApplyDrag(&grenades->vel.x, 48, delta);
    grenades->vel.y += 350 * delta; // Apply Gravity
    ApplyVelCollidePointTileBounce(&gW.level, delta, &grenades->pos, &grenades->vel);
    i++;
    grenades++;
nextGrenade:
  }

  // Handle Explosions
  Explosion *exps = gW.explosions.d;
  for (i=0; i<gW.explosions.len;) {
    exps[i].ttl -= delta;
    if (exps[i].ttl <= 0) {
      VectorDel(&gW.explosions, i);
      goto nextExp;
    }
    i++;
nextExp:
  }

  // Pickup Items
  items = gW.items.d;
  aabb1.x1 = gW.player.pos.x;
  aabb1.x2 = gW.player.pos.x + gW.player.size.x;
  aabb1.y1 = gW.player.pos.y;
  aabb1.y2 = gW.player.pos.y + gW.player.size.y;
  for (i=0; i<gW.items.len;) {
    Vec4 aabb2;
    aabb2.x1 = items->pos.x;
    aabb2.x2 = items->pos.x + 8;
    aabb2.y1 = items->pos.y;
    aabb2.y2 = items->pos.y + 8;
    if (CheckCollisionAABB(&aabb1, &aabb2)) {
      InvAdd(&gW.player.inv, items->type, items->qty);
      ToolbarUpdate(&gUI.toolbar, &gW.player);
      VectorDel(&gW.items, i);
      goto nextItemPickup;
    }
    i++;
    items++;
    nextItemPickup:
  }

  // Check for status tiles
  I64 tmpX = ToI64(gW.player.pos.x)/16;
  I64 tmpY = ToI64(gW.player.pos.y)/16;
  I64 tw = Ceil((gW.player.pos.x+gW.player.size.x)/16);
  I64 th = Ceil((gW.player.pos.y+gW.player.size.y)/16);
  for (y=tmpY; y<th; y++) {
    if (y >= 0 && y < gW.level.height) {
      for (x=tmpX; x<tw; x++) {
        if (x >= 0 && x < gW.level.width) {
          U8 flag = gW.level.flags[y*gW.level.width+x];
          if (flag & TFLAG_KILL) {
            PlayerKill();
          } else if (flag & TFLAG_END) {
            TriggerLevelEnd();
            return;
          }
        } else { // out of bounds
          PlayerKill();
        }
      }
    }
  }

  // Apply Laser Velocity
  lasers = gW.lasers.d;
  for (i=0; i<gW.lasers.len; i++) {
    lasers[i].pos.x += lasers[i].vel.x * delta;
    lasers[i].pos.y += lasers[i].vel.y * delta;
  }

  // Handle Lasers
  for (i=0; i<gW.lasers.len; i++) {
    IVec4 line;
    line.x1 = gW.lasers.d(Laser*)[i].pos.x;
    line.y1 = gW.lasers.d(Laser*)[i].pos.y;
    line.x2 = line.x1 + gW.lasers.d(Laser*)[i].vel.x/32;
    line.y2 = line.y1 + gW.lasers.d(Laser*)[i].vel.y/32;

    if (line.x1 < 0 || line.y1 < 0 || line.x2 < 0 || line.y2 < 0 ||
        line.x1 >= gW.level.widthPx  || line.x2 >= gW.level.widthPx ||
        line.y1 >= gW.level.heightPx || line.y2 >= gW.level.heightPx) {
      VectorDel(&gW.lasers, i--);
      goto nextHandleLaser;
    }

    // Find Relevant Tiles
    // Bresenham's Line Algo
    I32 dx, dy;
    if (line.x2 >= line.x1) {
      dx = line.x2 - line.x1;
    } else {
      dx = line.x1 - line.x2;
    }
    if (line.y2 >= line.y1) {
      dy = line.y1 - line.y2;
    } else {
      dy = line.y2 - line.y1;
    }

    CD2I32 slope;
    if (line.x1 < line.x2) {
      slope.x = 1;
    } else {
      slope.x = -1;
    }
    if (line.y1 < line.y2) {
      slope.y = 1;
    } else {
      slope.y = -1;
    }

    I32 err=dx+dy, e2;
    while (TRUE) {
      CD2I32 laserPxPos;
      tile.x = line.x1/16;
      tile.y = line.y1/16;
      ti = tile.y*gW.level.width + tile.x;
      if (gW.level.flags[ti] & TFLAG_BLOCK) {
        if (gW.level.flags[ti] & TFLAG_MINABLE)
          MineBlock(ti, tile);
        VectorDel(&gW.lasers, i--);
        break;
      }

      laserPxPos.x = line.x1 + 320;
      laserPxPos.y = line.y1 + 240;
      VectorAdd(&gW.laserPixels, &laserPxPos);
      if (line.x1==line.x2 && line.y1==line.y2)
        break;
      e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        line.x1 += slope.x;
      }
      if (e2 <= dx) {
        err += dx;
        line.y1 += slope.y;
      }
    }
nextHandleLaser:
  }

  // Apply Grapple Velocity
  if (gW.grapple.active && !gW.grapple.hooked) {
    gW.grapple.pos.x += gW.grapple.vel.x * delta;
    gW.grapple.pos.y += gW.grapple.vel.y * delta;

    if (gW.grapple.pos.x >= 0 && gW.grapple.pos.y >= 0) {
      x = gW.grapple.pos.x/16;
      y = gW.grapple.pos.y/16;
      if (x < gW.level.width && y < gW.level.height) {
        ti = y*gW.level.width + x;
        if (gW.level.flags[ti] & TFLAG_NOHOOK) {
          gW.grapple.active = FALSE;
        } else if (gW.level.flags[ti] & TFLAG_BLOCK) {
          SetSnd(SND_GRAPPLE_HIT);
          gW.player.dJumpAvail = FALSE;
          gW.player.dJumpSpent = FALSE;
          if (gW.player.state != STATE_DEAD)
            gW.player.state = STATE_FALLING;
          gW.grapple.hooked = TRUE;
          playerOffset.x = gW.player.pos.x+8;
          playerOffset.y = gW.player.pos.y+16;
          CD2Perpendicular(&gW.grapple.pos, &playerOffset, &perp);
          CD2DotDirection(&gW.player.vel, &perp);
          gW.player.vel.x = perp.x;
          gW.player.vel.y = perp.y;
          length2.x = gW.player.pos.x+8-gW.grapple.pos.x;
          length2.y = gW.player.pos.y+16-gW.grapple.pos.y;
          gW.grapple.length = CD2Magnitude(&length2);
        }
      } else {
      gW.grapple.active = FALSE;
      }
    } else {
      gW.grapple.active = FALSE;
    }
  }

  // Update Heat
  F64 temp = tmpY-32;
  gW.player.heat += temp * delta / 4;
  Cooler *coolers = gW.coolers.d;
  for (i=0; i<gW.coolers.len; i++) {
    if (Abs(gW.player.pos.x-(coolers[i].pos.x*16+8))+Abs(gW.player.pos.y-(coolers[i].pos.y*16+8)) < 64) {
      gW.player.heat -= 10 * delta;
      break;
    }
  }
  if (gW.player.heat < 0)
    gW.player.heat = 0;

  // Velocity Drag
  if (gW.grapple.hooked)
    ApplyDrag(&gW.player.vel.x, 64, delta);
  else
    ApplyDrag(&gW.player.vel.x, 128, delta);

  // Update Animations
  UpdateAnim(&gW.player.anim, delta);

  // Update Mob Animations
  mobs = gW.mobs.d;
  for (i=0; i<gW.mobs.len; i++) {
    UpdateAnim(&mobs[i].anim, delta);
  }

  // Update Debris
  Debris *debris = gW.debris.d;
  for (i=0; i<gW.debris.len; i++) {
    debris[i].vel.y += 128.0 * delta;
    debris[i].pos.x += debris[i].vel.x * delta;
    debris[i].pos.y += debris[i].vel.y * delta;
    if (debris[i].pos.x+320 <= gW.cam.x ||
        debris[i].pos.x-320 >= gW.cam.x ||
        debris[i].pos.y+240 <= gW.cam.y ||
        debris[i].pos.y-240 >= gW.cam.y ) {
      VectorDel(&gW.debris, i--);
    }
  }

  debris = gW.debrisEarth.d;
  for (i=0; i<gW.debrisEarth.len; i++) {
    debris[i].vel.y += 128.0 * delta;
    debris[i].pos.x += debris[i].vel.x * delta;
    debris[i].pos.y += debris[i].vel.y * delta;
    if (debris[i].pos.x+320 <= gW.cam.x ||
        debris[i].pos.x-320 >= gW.cam.x ||
        debris[i].pos.y+240 <= gW.cam.y ||
        debris[i].pos.y-240 >= gW.cam.y ) {
      VectorDel(&gW.debrisEarth, i--);
    }
  }

  // Update Cursor
/*
  CD2I32 mSel;
  mSel.x = ms.pos.x+gW.cam.x-319;
  mSel.y = ms.pos.y-8+gW.cam.y-239;
  if (CheckTileFlagOverlapPoint(mSel, TFLAG_SHOP)) {
    gUI.cursor = &CursorBuy;
  } else {
    gUI.cursor = &CursorReg;
  }
*/
}

U0 DrawGame(CTask*, CDC *dc) {
  // Draw Background Fluff
  I64 i;
  CD2I32 cam;
  cam.x = ToI64(gW.cam.x);
  cam.y = ToI64(gW.cam.y);

  // Draw Background
  DrawBackground(dc->body, cam);
//  MemSet(tex1, TRANSPARENT, 640*480);
  DrawTiles(dc->body, &gW.cam, &gW.level);

  // Draw Cooling Circles
  Cooler *coolers = gW.coolers.d;
  dc->color = SWEET_BLUE_LT;
  for (i=0; i<gW.coolers.len; i++) {
    GrCircle(dc, coolers[i].pos.x*16+8-gW.cam.x+320, coolers[i].pos.y*16+8-gW.cam.y+240, 64);
  }

  // Draw Spawners
  Spawner *spawners = gW.spawners.d;
  for (i=0; i<gW.spawners.len; i++) {
    //PxBlot(dc->body, &Car1, spawners[i].pos.x-cam.x+320, spawners[i].pos.y-cam.y+240);
    DrawAnim(dc, &carAnim, spawners[i].pos.x-cam.x+320, spawners[i].pos.y-cam.y+240, 0);
  }

  // Draw Mobs
  Mob *mobs = gW.mobs.d;
  for (i=0; i<gW.mobs.len; i++)
    DrawAnim(dc, &mobs[i].anim, ToI64(mobs[i].pos.x-gW.cam.x)+mobs[i].drawOffset.x+320, ToI64(mobs[i].pos.y-gW.cam.y)+mobs[i].drawOffset.y+240, mobs[i].flags&PFLAG_FACE_LEFT);

  // Draw Player
  I64 playerX = ToI64(gW.player.pos.x-gW.cam.x)+320;
  I64 playerY = ToI64(gW.player.pos.y-gW.cam.y)+240;
  if (ToI64(gW.player.inv_ttl*8)%2 == 0)
    DrawAnim(dc, &gW.player.anim, playerX, playerY, gW.player.flags&PFLAG_FACE_LEFT);

  // Draw Player Equipment
  if (gW.player.pxUse) {
    //GrLine(dc, 320, 240, Cos(gUI.lookRot)*32+320, Sin(gUI.lookRot)*32+240);
    PxBlotRotZ(dc, gW.player.pxUse, playerX+gW.player.pxUseX,
               playerY+gW.player.pxUseOffset.y, gUI.lookRot,
               gW.player.pxUseRot*3%(pi/2), gW.player.flags&PFLAG_FACE_LEFT,
               gW.player.pxUseStyle);
  }

  // Draw Items
//  MemSet(tex1, TRANSPARENT, 640*480);
  ItemDrop *items = gW.items.d;
  for (i=0; i<gW.items.len; i++) {
    PxBlot(dc->body, items[i].px, ToI64(items[i].pos.x-gW.cam.x)+320,
           ToI64(items[i].pos.y-gW.cam.y)+240 + Sin(items[i].ttl*3)*3);
//    PxBlot(tex1, items[i].px, ToI64(items[i].pos.x-gW.cam.x)+320,
//           ToI64(items[i].pos.y-gW.cam.y)+240 + Sin(items[i].ttl*3)*3);
  }
/*
  ts = tS*60;
  for (y=0; y<480; y++) {
    for (x=0; x<640; x++) {
      I64 xx = (x + ts);//%640;
      tx = (xx + gW.cam.x + 320)%640;
      ty = (y + gW.cam.y + 240)%480;
      xx = x + noiseMap[ty*640+tx];
      if (xx >= 640)
        xx = 640;
      else if (xx < 0)
        xx = 0;
      if (tex1[y*640+xx] != TRANSPARENT)
        dc->body[y*640+x] = tex1[y*640+xx];
    }
  }
*/

  // Draw Debris
  Debris *debris = gW.debris.d;
  for (i=0; i<gW.debris.len; i++) {
    dc->color = SWEET_GREEN;
    GrRect(dc, debris[i].pos.x-gW.cam.x+320, debris[i].pos.y-gW.cam.y+240, 4, 4);
  }

  // Draw Earth Debris
  debris = gW.debrisEarth.d;
  for (i=0; i<gW.debrisEarth.len; i++) {
    PxBlot(dc->body, &tEarthDebris, debris[i].pos.x-gW.cam.x+320, debris[i].pos.y-gW.cam.y+240);
  }

  if (gW.player.state == STATE_DEAD) {
    DrawTextBounce(dc->body, &fontBig, &txtDead, 290, 240);
    DrawTextBounce(dc->body, &fontBig, &txtDeadPressSpace, 160, 260);
  }

  // Draw Gibs
  DrawGibs(dc, gW.gibs.d, gW.gibs.len, cam);

  // Draw Grenades
  Grenade *grenades = gW.grenades.d;
  for (i=0; i<gW.grenades.len; i++) {
    PxBlotRotZ(dc, &ItemGrenade, ToI64(grenades[i].pos.x-gW.cam.x)+320,
               ToI64(grenades[i].pos.y-gW.cam.y)+240+Sin(grenades[i].ttl*3)*3,
               grenades[i].rot, 0, 0, 0);
  }

  // Draw Lasers
  dc->color = SWEET_GREEN;
  CD2I32 *laserPx = gW.laserPixels.d;
  for (i=0; i<gW.laserPixels.len; i++)
    GrPlot1(dc, laserPx[i].x-gW.cam.x, laserPx[i].y-gW.cam.y);
  gW.laserPixels.len = 0;

  // Draw Explosions
  Explosion *exps = gW.explosions.d;
  for (i=0; i<gW.explosions.len; i++)
    PxBlot(dc->body, ExplosionFrames[exps[i].ttl*6], exps[i].pos.x-gW.cam.x+320-16, exps[i].pos.y-gW.cam.y+240-16);

  if (gCtrl.cTest3) {
  for (i=8*dc->width_internal; i<dc->width_internal*dc->height; i++) {
    dc->body[i] = noiseMapLevel[i]%16;
  }
  }

  // Draw Grapple
  if (gW.grapple.active) {
    GrLine(dc, gW.grapple.pos.x-gW.cam.x+320, gW.grapple.pos.y-gW.cam.y+240, playerX+8, playerY+16);
    PxBlot(dc->body, &GrappleGunHook, gW.grapple.pos.x-gW.cam.x+320-4, gW.grapple.pos.y-gW.cam.y+240-6);
  }

  // Draw Shader
/*
  U8 *backbuffer = MAlloc(640*480);
  U8 color;
  MemCpy(backbuffer, dc->body, 640*480);
//  MemSet(dc->body, 0, 640*480);

  I64 yy;
  ts = tS*20;
//  ts = 0;
  I64 tts = Abs((tS*20%64)-32);
  //tts = (Sin(tS*4)+1)*15.5;
  //tts = tS*30%32;
  for (i=8*dc->width_internal; i<dc->width_internal*dc->height; i++) {
    x = i%640;
    xx = x;
    y = i/640;
    yy = y;
    xx += ts;
    xx = xx%640;

//    x += noiseMap[xx+yy*640+(tts*640*480)];
//    x += noiseMap[xx+yy*640];
    if (x >= 640)
      x = 639;
    else if (x < 0)
      x = 0;
//    y += noiseMap[i+(tts*640*480)];
//    y += noiseMap[i];
    if (y >= 480)
      y = 479;
    else if (y < 0)
      y = 0;
    dc->body[i] = backbuffer[x+y*640];
  }

  //ts %= 32;
  //ts = (Sin(tS)+1)*15.5;
  //ts = Abs(Sin(tS))*32;
*/

/*
  for (y=8; y<480; y++) {
    for (x=0; x<640; x++) {
      OpenSimplex2S(tS);
      dc->body[x+y*640] = noise2(ToF64(x)/32, ToF64(y)/32)*16;
    }
  }
*/

/*
  for (i=8*dc->width_internal; i<dc->width_internal*dc->height; i++) {
    dc->body[i] -= ii;
  }
*/
//  Free(backbuffer);

  // Draw Status
  ToolbarDraw(dc, &gUI, gW.player.health, gW.player.selItemSlot);

  // Draw Tile Highlight
  if (!gUI.mouseConsumed) {
    CD2I32 mSel, tSel, tmpCam;
    tmpCam.x = gW.cam.x;
    tmpCam.y = gW.cam.y;
    mSel.x = (ms.pos.x+tmpCam.x-320)/16;
    mSel.y = (ms.pos.y-8+tmpCam.y-240)/16;
    tSel.x = mSel.x*16-tmpCam.x+320;
    tSel.y = mSel.y*16-tmpCam.y+240;
    RecBorderClip(dc,  tSel.x, tSel.y, 16, 16, SWEET_BLUE_LT);
  }

  // Draw UI Windows
  if (gUI.flags&UI_INV_ENABLED)
    InventoryDraw(dc, &gUI, &gW.player.inv);
  else if (gUI.flags&UI_TRADE_ENABLED)
    TradeDraw(dc, &gUI, &gW.player.inv);
  else if (gUI.flags&UI_ESCMENU_ENABLED)
    DrawEscMenu(dc->body, &gUI.escMenu);
  else if (gUI.flags&UI_INSTRUCTIONS_ENABLED)
    DrawInstructions(dc->body, &txtInstructions);

  // Draw Level Number
  if (gW.currentLevel >= 0)
    DrawText(dc->body, &fontSmall, gW.levelStr, 4, 4);

#ifdef DEBUG
  // Draw Debug
  dc->color = SWEET_BLACK;
  GrPrint(dc, 8, 8, "Cam: %f %f
cVel: %f %f
Player: %.1f %.1f
Heat: %.1f
State: %d
Debris: %d
Mouse: %d %d
tSel: %d %d
Items: %d
Lasers: %d
Coolers: %d
DebugF64: %f %f
DebugI64: %d %d
cTest1: %d
cTest2: %d",
gW.cam.x, gW.cam.y,
gCtrl.cVel.x, gCtrl.cVel.y,
gW.player.pos.x, gW.player.pos.y,
gW.player.heat,
gW.player.state,
gW.debris.len,
ms.pos.x, ms.pos.y,
tSel.x, tSel.y,
gW.items.len,
gW.lasers.len,
gW.coolers.len,
gDebugF640, gDebugF641, gDebugI640, gDebugI641,
gCtrl.cTest1, gCtrl.cTest2);
#endif

  // Draw Cursor
  if (gUI.inv.mouseItem.id >= 0)
    PxBlot(dc->body, gItems[gUI.inv.mouseItem.id].px, gUI.mouse.x, gUI.mouse.y);
  else
    PxBlot(dc->body, gUI.cursor, gUI.mouse.x, gUI.mouse.y);
}
U0 Init() {
#ifdef DEBUG
  InitComm();
#endif
  gr.fp_draw_ms = NULL; // disable TempleOS cursor
  InitSnd;
  gW.quitGame = FALSE;
  gW.level.px = NULL;
  gW.level.flags = NULL;
  gW.level.tileType = NULL;
  gW.level.hp = NULL;
  VectorInit(&gW.mobs, sizeof(Mob));
  VectorInit(&gW.cMobs, sizeof(Vec4));
  VectorInit(&gW.items, sizeof(ItemDrop));
  VectorInit(&gW.debris, sizeof(Debris));
  VectorInit(&gW.debrisEarth, sizeof(Debris));
  VectorInit(&gW.coolers, sizeof(Cooler));
  VectorInit(&gW.lasers, sizeof(Laser));
  VectorInit(&gW.laserPixels, sizeof(CD2I32));
  VectorInit(&gW.grenades, sizeof(Grenade));
  VectorInit(&gW.explosions, sizeof(Explosion));
  VectorInit(&gW.gibs, sizeof(Gib));
  VectorInit(&gW.spawners, sizeof(Spawner));

  InitEscMenu(&gUI.escMenu);
  InitTitleButtons();

  MemSet(&gCtrl, 0, sizeof(Controls));

  Seed(tS+1./0.3333);
  OpenSimplex2SInit();
  OpenSimplex2S(Rand);

  GenNoiseMapSigned(noiseMap, 640, 200, 10, 8);
  GenNoiseMap(noiseMapLevel, 640, 640, 30, 20);

  SetAnim(&carAnim, &CarAnim, NULL);
}

U0 InitGame() {
  gCtrl.cVel.x = 0;
  gCtrl.cVel.y = 0;
  gCtrl.cNum = 0;
  gCtrl.cJump = FALSE;
  gCtrl.cEsc = FALSE;

  // Setup Level
  gW.coins = 0;
  NewPlayer(&gW.player, 320, 240);
  gW.currentLevel = 0;
  ChangeLevel(gW.currentLevel);

  // Setup UI
  UIInit(&gUI, &gW.player);
  gUI.flags = UI_INSTRUCTIONS_ENABLED;

  gCtrl.cTest3 = 0;

  // Init Engine
  gW.ActiveUpdate = &GameUpdate;
  gW.ActiveInput = &GameInput;
  Fs->draw_it = &DrawGame;
}

U0 InitSandbox() {
  // Setup Camera
  gCtrl.cVel.x = 0;
  gCtrl.cVel.y = 0;
  gCtrl.cNum = 0;
  gCtrl.cJump = FALSE;
  gCtrl.cEsc = FALSE;

  // Setup Level
  gW.currentLevel = -1;
  gW.activeLvl = &Sandbox;
  InitLevel(&gW, gW.activeLvl, noiseMapLevel);

  // Setup Player
  NewPlayer(&gW.player, gW.level.spawn.x, gW.level.spawn.y);
  gW.player.dJumpAvail = FALSE;
  gW.player.dJumpSpent = FALSE;
  gW.coins = 0;
  gW.grapple.active = FALSE;
  gW.grapple.hooked = FALSE;
  UpdatePxUse(&gW.player);

  gW.cam.x = gW.player.pos.x+gW.player.size.x>>1;
  gW.cam.y = gW.player.pos.y+gW.player.size.y>>1;

  // Setup UI
  UIInit(&gUI, &gW.player);
  gUI.flags = UI_INSTRUCTIONS_ENABLED;

  gCtrl.cTest3 = 0;

  // Init Engine
  gW.ActiveUpdate = &GameUpdate;
  gW.ActiveInput = &GameInput;
  Fs->draw_it = &DrawGame;
}

#ifndef DEBUG
  DocClear;
#endif
  SettingsPush;
  MenuPush(
        "File {"
        "  Abort(,CH_SHIFT_ESC);"
        "  Exit(,CH_ESC);"
        "}"
        "Play {"
        "  Up(,'w');"
        "  Down(,'s');"
        "  Left(,'a');"
        "  Right(,'d');"
        "  Weapon1(,'1');"
        "  Weapon2(,'2');"
        "  KillSnd(,'m');"
        "}"
        );
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  Fs->text_attr=SWEET_BLUE<<4+WHITE;
  GrPaletteSet(gr_palette_sweetie16);
  Fs->win_inhibit=WIG_TASK_DFT-WIF_SELF_FOCUS-WIF_SELF_BORDER-WIF_FOCUS_TASK_MENU;

  F64 t_last, t_now, t_delta, t_sleep;
  Init();
  InitTitle();
  t_last = tS;
#ifdef DEBUG
  Prof;
#endif
  CJob *sndJob = *Spawn(&SndTask,NULL,"Sound",mp_cnt-1,Fs);
  while (!gW.quitGame) {
    t_now = tS;
    t_delta = t_now - t_last;
    t_last = t_now;
    (gW.ActiveInput)();
    (gW.ActiveUpdate)(t_delta);
    Refresh(1, FALSE);
  }
  SetSnd(SND_QUIT);
#ifdef DEBUG
  ProfRep;
#endif
  Snd;
  MenuPop;
  SettingsPop;
  gr.fp_draw_ms=&DrawStdMs;
  DCFill;
#ifndef DEBUG
  GrPaletteSet(gr_palette_std);
  Exit;
#endif
