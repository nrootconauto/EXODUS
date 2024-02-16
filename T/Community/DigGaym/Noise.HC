#ifndef NOISE_HC
#define NOISE_HC

#include "Simplex"

F64 TAU = pi*2;


U0 GenNoiseMap(U8 *map, I64 size, F64 div, F64 radius, F64 mul) {
  I64 i;
  radius /= TAU;
  for (i=0; i<size*size; i++) {
    I64 x = i%size;
    I64 y = i/size;
    F64 ii = ToF64(y)/div*TAU;
    F64 jj = ToF64(x)/div*TAU;

    F64 xx = radius * Sin(jj);
    F64 yy = radius * Cos(jj);
    F64 zz = radius * Sin(ii);
    F64 ww = radius * Cos(ii);
    F64 vv = noise4_XYBeforeZW(xx, yy, zz, ww);

    vv = vv * 0.5 + 0.5;
    map[i] = vv*mul;
  }
}

U0 GenNoiseMapSigned(I8 *map, I64 size, F64 div, F64 radius, F64 mul) {
  I64 i;
  radius /= TAU;
  for (i=0; i<size*size; i++) {
    I64 x = i%size;
    I64 y = i/size;
    F64 ii = ToF64(y)/div*TAU;
    F64 jj = ToF64(x)/div*TAU;

    F64 xx = radius * Sin(jj);
    F64 yy = radius * Cos(jj);
    F64 zz = radius * Sin(ii);
    F64 ww = radius * Cos(ii);
    F64 vv = noise4_XYBeforeZW(xx, yy, zz, ww);

    map[i] = Round(vv*mul);
  }
}

#endif