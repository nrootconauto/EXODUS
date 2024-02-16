#ifndef TITLEDRAW_HC
#define TITLEDRAW_HC

#include "Draw";
#include "Obj/Scum";
#include "Obj/BlazeIt";
#include "Obj/LL";

extern F64 title_t;

CD3I32 scumBuf[Scum_tris*3];

U0 DrawLogo(CDC *dc) {
  I64 i, mat[4][4];
  CD3 pos;
  pos.x = 0;
  pos.y = -220;
  pos.z = 0;
  DCDepthBufAlloc(dc);

  I64 mat2[4][4];
  Mat4x4IdentEqu(mat2);
  if (CamMVP(&gCam, &pos, mat2, mat)) {
    DCMat4x4SetFast(dc, mat);
    DrawLines(dc, BlazeIt_cnt, &BlazeIt);
  }

  CD3I32 avg;
  for (i=0; i<LL_cnt; i+=2) {
    avg.x = LL[i].x + LL[i+1].x;
    avg.y = LL[i].y + LL[i+1].y;
    avg.z = LL[i].z + LL[i+1].z;
    F64 mod = ToI64(title_t*200+avg.y)%500;
    if (mod > 100) {
      if (mod < 200)
        dc->color = PURPLE;
      else if (mod < 300)
        dc->color = GREEN;
      else if (mod < 400)
        dc->color = RED;
      else
        dc->color = BLUE;
      GrLine3(dc, LL[i].x, LL[i].y, LL[i].z, LL[i+1].x, LL[i+1].y, LL [i+1].z);
    }
  }
}

// Draw Title
U0 DrawTitle(CTask *task, CDC *dc) {
  I64 mat[4][4], r[4][4], *old_r=dc->r;
  F64 time = tS;
  U8 *credStr;
  // Setup DC
  dc->x = task->pix_left + task->pix_width/2;
  dc->y = task->pix_top + task->pix_height/2;
  dc->flags |= DCF_TRANSFORMATION;

  // Draw Scum
  gCam.pos.x = Sin(time+pi)*8;
  gCam.pos.y = Cos(time+pi)*8;
  gCam.pos.z = -256;
  gCam.up.x = 0;
  gCam.up.y = -1;
  gCam.up.z = 0;
  gCam.zoom = 1.0;

  Mat4x4IdentEqu(r);
  //Mat4x4RotX(r, tS);
  CamUpdate(&gCam);
  CD3 pos;
  pos.x = 4+Abs(Sin(time))*4;
  pos.y = 0+Abs(Sin(time))*2;
  pos.z = 0;
  CamMVP(&gCam, &pos, r, mat);
  DCMat4x4SetFast(dc, mat);
  dc->color = BLUE;
  DrawTriFill(dc, Scum, Scum_tris, &scumBuf);
  dc->color = RED;
  pos.x = -4-Abs(Cos(time))*4;
  pos.y = 0-Abs(Cos(time))*2;
  pos.z = 40;
  CamMVP(&gCam, &pos, r, mat);
  DCMat4x4SetFast(dc, mat);
  DrawTriFill(dc, Scum, Scum_tris, &scumBuf);
  dc->color = WHITE;
  pos.x = 0;
  pos.y = 0;
  pos.z = 20;
  CamMVP(&gCam, &pos, r, mat);
  DCMat4x4SetFast(dc, mat);
  DrawTriFill(dc, Scum, Scum_tris, &scumBuf);

  credStr = "Published by";
  GrPutS(dc, SCX-FONT_WIDTH*StrLen(credStr)/2, FONT_HEIGHT*20, credStr);
  credStr = "By CrunkLord420";
  GrPutS(dc, SCX-FONT_WIDTH*StrLen(credStr)/2, FONT_HEIGHT*50, credStr);
  credStr = "Version 0.420";
  GrPutS(dc , SCX-FONT_WIDTH*StrLen(credStr)/2, FONT_HEIGHT*52, credStr);
  credStr = "Released August 11th 2020 under MIT+NIGGER license";
  GrPutS(dc , SCX-FONT_WIDTH*StrLen(credStr)/2, FONT_HEIGHT*53, credStr);

  // Draw BlazeItFgt Logo
  DrawLogo(dc);

  // Restore DC
  dc->x = 0;
  dc->y = 0;
  dc->r = old_r;
}

#endif