#ifndef SLIDER_HC
#define SLIDER_HC

#include "GameInput"
#include "Collision"
#include "Text"
/*
#include "Px/PxSlider"
#include "Px/PxSliderHover"
*/

#define SLIDER_BIT_W 8
#define SLIDER_BIT_H 22
#define SLIDER_BIT_HW 4

public class Slider {
  CD2I32 posBase;
  CD2I32 size;
  CD2I32 pos;
  PxData *bit;
  U8 str[6];
  I16 val;
  I16 max;
  Bool bitActive;
};

public U0 SliderDraw(U8 *fb, Slider *slider) {
  PxBlot(fb, slider->bit, slider->pos.x, slider->pos.y);
  DrawText(fb, &fontBig, slider->str, slider->posBase.x+slider->size.x+4, slider->posBase.y-3);
}

public U0 SliderHandle(Slider *slider, Controls *ctrl) {
  if (CheckPointAABB(ms.pos.x, ms.pos.y, slider->posBase.x,
                     slider->posBase.x+slider->size.x,
                     slider->posBase.y, slider->posBase.y+slider->size.y)) {
  }
  if (slider->bitActive) {
    if (ms.lb) {
      slider->pos.x = ms.pos.x;
      if (slider->pos.x < slider->posBase.x)
        slider->pos.x = slider->posBase.x;
      else if (slider->pos.x > slider->posBase.x+slider->size.x-SLIDER_BIT_W+1)
        slider->pos.x = slider->posBase.x+slider->size.x-SLIDER_BIT_W+1;
      F64 bitInc = ToF64(slider->size.x-SLIDER_BIT_W) / slider->max;
      slider->val = ToF64(slider->pos.x-slider->posBase.x) / bitInc;
      StrPrint(slider->str, "%d/%d", slider->val, slider->max);
    } else {
      slider->bitActive = FALSE;
    }
  } else if (CheckPointAABB(ms.pos.x, ms.pos.y, slider->pos.x,
                            slider->pos.x+SLIDER_BIT_W,
                            slider->pos.y, slider->pos.y+SLIDER_BIT_H)) {    
    slider->bit = &PxSlider;
    if (ctrl->mLDown) {
      slider->bitActive = TRUE;
    }
  } else {
    slider->bit = &PxSliderHover;
  }
}

public U0 SliderSet(Slider *slider, I16 val, I16 max) {
  slider->val = val;
  slider->max = max;
  slider->pos.x = slider->posBase.x;
  slider->pos.y = slider->posBase.y-6;
  StrPrint(slider->str, "%d/%d", val, max);
}

public U0 SliderInit(Slider *slider, I32 x, I32 y, I32 w, I32 h, I16 max) {
  slider->posBase.x = x;
  slider->posBase.y = y;
  slider->size.x = w;
  slider->size.y = h;
  slider->bit = &PxSlider;
  SliderSet(slider, 0, max);
}

#endif