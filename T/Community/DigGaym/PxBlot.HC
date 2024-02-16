#ifndef PXBLOT_HC
#define PXBLOT_HC

#define BLOT_CENTER 0
#define BLOT_BL 1
#define BLOT_CL 2

class PxData {
  I32 width;
  I32 height;
  U8 *body;
};

public U0 PxBlot(U8 *body, PxData *data, I64 x, I64 y) {
  y += 8; // adjust for toolbar
  // Cull
  if (x >= 640 || y >= 480 ||
      x+data->width < 0 || y+data->height < 0) {
    return;
  }

  // Clip X
  I64 minX = 0;
  if (x < 0) {
    minX = -x;
    x = 0;
  }
  I64 maxX = data->width;
  if (maxX+x >= 640) {
    maxX -= maxX+x - 640;
  }

  // Clip Y
  I64 minY = 0;
  if (y < 8) {
    minY = -y + 8;
    y = 8;
  }
/*
  I64 minY = 0;
  if (y < 0) {
    minY = -y;
    y = 0;
  }
*/
  I64 maxY = data->height;
  if (maxY+y >= 480) {
    maxY -= maxY+y - 480;
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
  I64 xOff = data->width>>1;
  I64 yOff = data->height>>1;
  for (dy=0; dy<data->height; dy++) {
    for (dx=0; dx<data->width; dx++) {
      _x = dx-xOff;
      _y = dy-yOff;
      TransformPxBlot(m, &_x, &_y);
      _x += x;
      _y += y+8;
      /* Clip */
      if (_x < 0 || _y < 8 || _x >= 640 || _y >= 480) {
        goto nextPxBlotM;
      }
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        dc->body[_y*640+_x] = color;
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
      if (_x < 0 || _y < 8 || _x >= 640 || _y >= 480) {
        goto nextPxBlotM;
      }
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        dc->body[_y*640+_x] = color;
      }
      nextPxBlotM:
    }
  }
}

public U0 PxBlotMCL(CDC* dc, PxData *data, I64 x, I64 y, I64 *m) {
  I64 dy, dx, _x, _y;
  I64 yOff = data->height>>1;
  for (dy=0; dy<data->height; dy++) {
    for (dx=0; dx<data->width; dx++) {
      _x = dx;
      _y = dy-yOff;
      TransformPxBlot(m, &_x, &_y);
      _x += x;
      _y += y+8;
      /* Clip */
      if (_x < 0 || _y < 8 || _x >= 640 || _y >= 480) {
        goto nextPxBlotM;
      }
      U8 color = data->body[dy*data->width+dx];
      if (color != TRANSPARENT) {
        dc->body[_y*640+_x] = color;
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

#endif