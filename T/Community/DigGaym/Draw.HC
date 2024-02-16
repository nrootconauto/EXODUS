#ifndef DRAW_HC
#define DRAW_HC

#include "World"
#include "Text"
#include "Sweetie16"
#include "Map"
/*
#include "Px/BG0"
#include "Px/BGGrass0"
#include "Px/BGGrass1"
#include "Px/BGLowerTrim"
#include "Px/TerryLaugh"
#include "Px/tEarthDebris"
*/

#define WIDTH_INTERNAL 640

U0 DrawTiles(U8 *fb, CD2 *cam, Map *map) {
  I64 txStart = ToI64(cam->x/16)-20;
  I64 xMod = ToI64(cam->x)%16;
  I64 yMod = ToI64(cam->y)%16;

  I64 ty = ToI64(cam->y/16)-15;
  I64 x, y;
  for (y=0; y<31; y++, ty++) {
    I64 tx = txStart;
    for (x=0; x<41; x++, tx++) {
      if (ty >= 0 && ty < map->height &&
          tx >= 0 && tx < map->width &&
          map->px[ty*map->width+tx]) {
        PxBlot(fb, map->px[ty*map->width+tx], 16*x-xMod, y*16-yMod);
      }
    }
  }
}

public U0 DrawGibs(CDC *dc, Gib *gibs, I64 len, CD2I32 cam) {
  I64 i;
  for (i=0; i<len; i++) {
    PxBlotRotZ(dc, gibs[i].px, ToI64(gibs[i].pos.x-cam.x)+320,
               ToI64(gibs[i].pos.y-cam.y)+240, gibs[i].rot, 0, 0, 0);
  }
}

public U0 LineH(U8 *fb, I32 x1, I32 x2, I32 y, U8 color) {
  I32 d = WIDTH_INTERNAL*y+x1;
  fb += d;
  while (x1<=x2) {
    *fb = color;
    fb++;
    x1++;
  }
}

public U0 LineV(U8 *fb, I32 x, I32 y1, I32 y2, U8 color) {
  I32 d = WIDTH_INTERNAL*y1+x;
  fb += d;
  while (y1<=y2) {
    *fb = color;
    fb += WIDTH_INTERNAL;
    y1++;
  }
}

U0 DrawRect(U8 *fb, CD2I32 pos, CD2I32 size, U8 color) {
  I32 x, y, xi, yi;
  for (yi=0, y=pos.y; yi<size.y; yi++, y++) {
    for (xi=0, x=pos.x; xi<size.x; xi++, x++) {
      fb[y*640+x] = color;
    }
  }
}

U0 DrawParallaxBG(U8 *body, PxData *px, CD2I32 cam, F64 parallax, I32 yOffset) {
  #define GROUND_LEVEL 952
//  #define GROUND_LEVEL 440
  I32 x, y, sx, sy, topY, bottomY, diffY=0;
  U8 color;

  I32 paraY = (GROUND_LEVEL - 40 - cam.y) * parallax * 0.2;
  I32 paraX = cam.x*(parallax+1.0);
  bottomY = GROUND_LEVEL - cam.y + yOffset + paraY;
  if (bottomY > 0) {
    topY = bottomY - px->height;
    if (topY < 472) {
      if (topY < 0) {
        diffY = -topY;
        topY = 0;
      }
      if (bottomY > 472)
        bottomY = 472;
      topY += 8;
      bottomY += 8;
      for (y=topY, sy=diffY; y<bottomY; y++, sy++) {
        for (x=0, sx=0; x<640; x++, sx++) {
          color = px->body[sy*px->width+(sx+paraX)%px->width];
          if (color != TRANSPARENT)
            body[y*640+x] = color;
        }
      }
    }
  }
}

U0 DrawPanel(U8 *fb, CD2I32 pos, CD2I32 size, U8 color, U8 colorBorder, U8 colorTrim) {
  pos.y += 8;

  LineH(fb, pos.x+1, pos.x+size.x-2, pos.y, colorBorder);
  LineH(fb, pos.x+1, pos.x+size.x-2, pos.y+size.y-1, colorBorder);
  LineV(fb, pos.x, pos.y+1, pos.y+size.y-1, colorBorder);
  LineV(fb, pos.x+size.x-1, pos.y+1, pos.y+size.y-2, colorBorder);

  LineH(fb, pos.x+1, pos.x+size.x-2, pos.y+1, colorTrim);
  LineH(fb, pos.x+1, pos.x+size.x-2, pos.y+size.y-2, colorTrim);
  LineV(fb, pos.x+1, pos.y+2, pos.y+size.y-3, colorTrim);
  LineV(fb, pos.x+size.x-2, pos.y+2, pos.y+size.y-3, colorTrim);

  pos.x += 2;
  pos.y += 2;
  size.x -= 4;
  size.y -= 4;
  DrawRect(fb, pos, size, color);
}

U0 DrawInstructions(U8 *fb, TextData *txt) {
  CD2I32 pos, size;
  pos.x = 64;
  pos.y = 64;
  size.x = 512;
  size.y = 352;
  DrawPanel(fb, pos, size, SWEET_GREY, SWEET_BLACK, SWEET_GREY_LT);
  PxBlot(fb, &TerryLaugh, pos.x+size.x-TerryLaugh.width-8, pos.y+8);
  DrawTextBounce(fb, &fontBig, txt, pos.x+4, pos.y+4);
}

U0 DrawBackground(U8 *fb, CD2I32 cam) {
  I64 i, y = 952 + 240 - cam.y;
  if (y < 8)
    y = 8;
  else if (y > 480)
    y = 480;
  for (i=y*640; i<480*640; i++) {
    fb[i] = SWEET_GREY_DK;
  }
  DrawParallaxBG(fb, &BG0, cam, -0.6, 200);
  DrawParallaxBG(fb, &BGLowerTrim, cam, -0.1, 245);
  DrawParallaxBG(fb, &BGGrass1, cam, -0.2, 200);
  DrawParallaxBG(fb, &BGGrass0, cam, 0.0, 240);
}

#endif