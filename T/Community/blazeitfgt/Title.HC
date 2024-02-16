#ifndef TITLE_HC
#define TITLE_HC
extern Cam gCam;
extern U0 (*ActiveUpdate)(F64 delta);
extern U0 (*ActiveInput)();

#include "TitleDraw";
#include "TitleInput";


F64 title_t;

public U0 UpdateTitle(F64 delta) {
  // Update Timers
  title_t += delta;
}

public U0 InitTitle() {
  gCam.pos.x = 0.0;
  gCam.pos.y = 0.0;
  gCam.pos.z = 0.0;
  gCam.zoom = 1.0;
  title_t = 0;
  ActiveInput = &TitleInput;
  ActiveUpdate = &UpdateTitle;
  Fs->draw_it = &DrawTitle;
}

#endif
