#ifndef PXBLOT_HC
#define PXBLOT_HC

#define BLOT_CENTER 0
#define BLOT_BL 1
#define BLOT_CL 2

#include "GrFast"

class PxData {
  I32 width;
  I32 height;
  U8 body[];
};

class PxAnimSheet {
  I64 frames;
  F64 time;
  F64 speed;
  PxData **px;
};

public U0 PxBlot(U8 *body, PxData *data, I64 x, I64 y) {
  y += 8; // adjust for toolbar
  // Cull
  if (x >= 640 || y >= 480 ||
      x+data->width < 0 || y+data->height < 0) {
    return;
  }

  // Clip X
  I64 maxX = data->width;
  if (maxX+x >= 640)
    maxX -= maxX+x - 640;

  I64 minX = 0;
  if (x < 0) {
    minX = -x;
    x = 0;
  }

  // Clip Y
  I64 maxY = data->height;
  if (maxY+y >= 480)
    maxY -= maxY+y - 480;

  I64 minY = 0;
  if (y < 8) {
    minY = -y + 8;
    y = 8;
  }

  // Draw
  I64 d = body + y*640 + x;
  y = 0;
  I64 dy, dx;
  for (dy=minY; dy<maxY; y++, dy++) {
    U8 *dst = d + y*640;
    for (dx=minX; dx<maxX; dx++, dst++) {
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        *dst = color;
      }
    }
  }
}

public U0 PxBlotMask(U8 *body, PxData *data, I64 x, I64 y, CColorROPU32 mask) {
  y += 8; // adjust for toolbar
  // Cull
  if (x >= 640 || y >= 480 ||
      x+data->width < 0 || y+data->height < 0) {
    return;
  }

  // Clip X
  I32 maxX = data->width;
  if (maxX+x >= 640)
    maxX -= maxX+x - 640;

  I32 minX = 0;
  if (x < 0) {
    minX = -x;
    x = 0;
  }

  // Clip Y
  I32 maxY = data->height;
  if (maxY+y >= 480)
    maxY -= maxY+y - 480;

  I32 minY = 0;
  if (y < 8) {
    minY = -y + 8;
    y = 8;
  }

  // Draw
  I64 d = body + y*640 + x;
  y = 0;
  I64 dy, dx;
  for (dy=minY; dy<maxY; y++, dy++) {
    U8 *dst = d + y*640;
    for (dx=minX; dx<maxX; dx++, dst++) {
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        if (color == mask.c0.rop)
          *dst = mask.c0.color;
        else
          *dst = color;
      }
    }
  }
}

public U0 PxBlotDither(U8 *body, PxData *data, I64 x, I64 y, U64 mask, U64 probability) {
  y += 8; // adjust for toolbar
  // Cull
  if (x >= 640 || y >= 480 ||
      x+data->width < 0 || y+data->height < 0) {
    return;
  }

  // Clip X
  I64 maxX = data->width;
  if (maxX+x >= 640)
    maxX -= maxX+x - 640;

  I64 minX = 0;
  if (x < 0) {
    minX = -x;
    x = 0;
  }

  // Clip Y
  I64 maxY = data->height;
  if (maxY+y >= 480)
    maxY -= maxY+y - 480;

  I64 minY = 0;
  if (y < 8) {
    minY = -y + 8;
    y = 8;
  }

  // Draw
  I64 d = body + y*640 + x;
  y = 0;
  I64 dy, dx;
  I64 seed = Fs->rand_seed;
  for (dy=minY; dy<maxY; y++, dy++) {
    U8 *dst = d + y*640;
    for (dx=minX; dx<maxX; dx++, dst++) {
      seed = RandF(seed);
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        if (color == mask.u8[0]) {
          if (seed.u16[0] > probability.u16[0]) {
            *dst = mask.u8[1];
          } else {
            *dst = color;
          }
        } else if (color == mask.u8[2]) {
          if (seed.u16[0] > probability.u16[1]) {
            *dst = mask.u8[3];
          } else {
            *dst = color;
          }
        }
      }
    }
  }
  Fs->rand_seed = seed;
}

public U0 PxBlotFlipX(CDC *dc, PxData *data, I64 x, I64 y) {
  y += 8; // adjust for toolbar
  // Cull
  if (x >= dc->width_internal || y >= dc->height ||
      x+data->width < 0 || y+data->height < 0) {
    return;
  }

  // Clip X
  I64 xStart = data->width;
  if (x < 0) {
    xStart += x;
    x = 0;
  }

  I64 xEnd = 0;
  if (x+xStart > dc->width_internal) {
    xEnd = x+xStart - dc->width_internal;
  }

  // Clip Y

  I64 minY = 0;
  if (y < 0) {
    minY = -y;
    y = 0;
  }

  I64 maxY = data->height;
  if (maxY+y >= dc->height) {
    maxY -= maxY+y - dc->height;
  }

  // Draw
  I64 d = dc->body + y*dc->width_internal + x;
  y = 0;
  I64 dy, dx;
  for (dy=minY; dy<maxY; y++, dy++) {
    U8 *dst = d + y*dc->width_internal;
    for (dx=xStart-1; dx>=xEnd; dx--, dst++) {
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        *dst = color;
      }
    }
  }
}

public U0 TransformPxBlot(I64 *m, I64 *_x, I64 *_y) {
  I64 x1,y1,xx=*_x,yy=*_y;
  I64 w1;
  x1=m[0*4+0]*xx+m[0*4+1]*yy+m[0*4+2]+m[0*4+3];
  y1=m[1*4+0]*xx+m[1*4+1]*yy+m[1*4+2]+m[1*4+3];
  w1=m[3*4+0]*xx+m[3*4+1]*yy+m[3*4+2]+m[3*4+3];
  x1 /= w1;
  x1 >> 32;
  y1 /= w1;
  y1 >> 32;
  *_x=x1;
  *_y=y1;
}

public U0 PxBlotNoise(CDC* dc, PxData *data, I32 x, I32 y, I8 *noise) {
  I64 dy, dx, _x, _y;
  I64 ts = tS*30;
  for (dy=0; dy<data->height; dy++) {
    for (dx=0; dx<data->width; dx++) {
      _x = dx + x;
      _y = dy + y;
      I64 _xx = noise[(y+dy)*640+(x+dx+ts)%640];
      //I64 _xx = dx + noise[((_x+ts)%640)+_y*640%480];
  //    _x += noise[(_y%480*640) + (_x+ts%640)];
//      I64 _xx = _x + noise[(_y*640) + ((_x)%640)];
//      I64 _xx = _x + noise[(_y*640) + ((_x))];
//      _x += noise[_y*640%480 + (_x+ts%640)];
//      _x += noise[((dx+ts)%640)+dy*640%480];
      /* Clip */
      if (_x < 0 || _y < 0 || _x >= dc->width_internal || _y >= dc->height) {
        goto nextPxBlotM;
      }
      I64 xxx = dx + _xx;
      if (xxx >= 0 && xxx < data->width) {
        U8 color = data->body[dy*data->width+(dx+_xx)%data->width];
//      U8 color = noise[((y+dy)*640)+((x+dx+ts)%640)];
//      U8 color = noise[(_y%480*640) + ((_xx+ts)%640)];
//        U8 color = 4;
      if (color != TRANSPARENT) {
//        dc->body[_y*640+_xx] = color;
        dc->body[_y*640+_x] = color;
      }
      }

      nextPxBlotM:
    }
  }
}

public U0 PxBlotM(CDC* dc, PxData *data, I64 x, I64 y, I64 *m) {
  I64 dy, dx, _x, _y;
  for (dy=0; dy<data->height; dy++) {
    for (dx=0; dx<data->width; dx++) {
      _x = dx;
      _y = dy;
      TransformPxBlot(m, &_x, &_y);
      _x += x;
      _y += y+8;
      /* Clip */
      if (_x < 0 || _y < 0 || _x >= dc->width_internal || _y >= dc->height) {
        goto nextPxBlotM;
      }
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        dc->body[_y*dc->width_internal+_x] = color;
      }
      nextPxBlotM:
    }
  }
}

public U0 PxBlotMCenter(CDC* dc, PxData *data, I64 x, I64 y, I64 *m) {
  I64 dy, dx, _x, _y;
  I64 xOff = data->width/2;
  I64 yOff = data->height/2;
  for (dy=0; dy<data->height; dy++) {
    for (dx=0; dx<data->width; dx++) {
      _x = dx-xOff;
      _y = dy-yOff;
      TransformPxBlot(m, &_x, &_y);
      _x += x;
      _y += y+8;
      /* Clip */
      if (_x < 0 || _y < 0 || _x >= dc->width_internal || _y >= dc->height) {
        goto nextPxBlotM;
      }
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        dc->body[_y*dc->width_internal+_x] = color;
      }
      nextPxBlotM:
    }
  }
}

public U0 PxBlotMBL(CDC* dc, PxData *data, I64 x, I64 y, I64 *m) {
  I64 dy, dx, _x, _y;
  I64 yOff = data->height;
  for (dy=0; dy<data->height; dy++) {
    for (dx=0; dx<data->width; dx++) {
      _x = dx;
      _y = dy-yOff;
      TransformPxBlot(m, &_x, &_y);
      _x += x;
      _y += y+8;
      /* Clip */
      if (_x < 0 || _y < 0 || _x >= dc->width_internal || _y >= dc->height) {
        goto nextPxBlotM;
      }
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        dc->body[_y*dc->width_internal+_x] = color;
      }
      nextPxBlotM:
    }
  }
}

public U0 PxBlotMCL(CDC* dc, PxData *data, I64 x, I64 y, I64 *m) {
  I64 dy, dx, _x, _y;
  I64 yOff = data->height/2;
  for (dy=0; dy<data->height; dy++) {
    for (dx=0; dx<data->width; dx++) {
      _x = dx;
      _y = dy-yOff;
      TransformPxBlot(m, &_x, &_y);
      _x += x;
      _y += y+8;
      /* Clip */
      if (_x < 0 || _y < 0 || _x >= dc->width_internal || _y >= dc->height) {
        goto nextPxBlotM;
      }
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        dc->body[_y*dc->width_internal+_x] = color;
      }
      nextPxBlotM:
    }
  }
}

public U0 PxBlotRotZ(CDC *dc, PxData *px, I64 x, I64 y, F64 rot, F64 rotMod, Bool flip, U8 rotType) {
  I64 m[16];
  Mat4x4IdentEqu(m);
  if (flip) {
    Mat4x4RotY(m, pi);
    rot -= pi;
    rot -= rotMod;
  } else {
    rot += rotMod;
  }
  Mat4x4RotZ(m, rot);
  switch (rotType) {
    case BLOT_CL:
      PxBlotMCL(dc, px, x, y, m);
      break;
    case BLOT_BL:
      PxBlotMBL(dc, px, x, y, m);
      break;
    default:
      PxBlotMCenter(dc, px, x, y, m);
  }
}

U0 InitAnimSheet(PxAnimSheet *sheet, PxData **px, I64 frames, F64 speed) {
  sheet->frames = frames;
  sheet->time = 0;
  sheet->speed = speed;
  sheet->px = px;
}

U0 DrawAnimSheet(U8 *fb, PxAnimSheet *sheet, I32 x, I32 y) {
  I64 frame = ToI64(sheet->time * sheet->speed) % sheet->frames;
  PxBlot(fb, sheet->px[frame], x, y);
}

#endif
