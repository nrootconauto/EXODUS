/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ exodus: executable divine operating system in userspace                      │
│                                                                              │
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for citations.                                               │
│                                                                              │
│ This software is provided 'as-is', without any express or implied            │
│ warranty. In no event will the authors be held liable for any damages        │
│ arising from the use of this software.                                       │
│                                                                              │
│ Permission is granted to anyone to use this software for any purpose,        │
│ including commercial applications, and to alter it and redistribute it       │
│ freely, subject to the following restrictions:                               │
│                                                                              │
│ 1. The origin of this software must not be misrepresented; you must not      │
│    claim that you wrote the original software. If you use this software      │
│    in a product, an acknowledgment in the product documentation would be     │
│    appreciated but is not required.                                          │
│ 2. Altered source versions must be plainly marked as such, and must not be   │
│    misrepresented as being the original software.                            │
│ 3. This notice may not be removed or altered from any source distribution.   │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <SDL.h>

#include <exodus/misc.h>
#include <exodus/shims.h>
#include <exodus/sound.h>

static u64 sample, freq;
static SDL_AudioSpec have;
static f64 volume = .2;

enum {
  MAX = (1 << 15) - 1
};

static void AudioCB(argign void *ud, u8 *_out, int _len) {
  i16 *out = (i16 *)_out;
  int len = _len / 2;
  if (unlikely(!freq)) {
    memset(_out, 0, _len);
    return;
  }
  for (int i = 0; i < len / have.channels; ++i) {
    f64 t = (f64)++sample / have.freq;
    f64 w = sin(2 * M_PI * t * freq);
    w /= fabs(w);
    w *= MAX;
    i16 maxed = w * volume;
    for (int j = 0; j < have.channels; ++j)
      out[have.channels * i + j] = maxed;
  }
}

void InitSound(void) {
  if (SDL_Init(SDL_INIT_AUDIO)) {
    flushprint(stderr,
               "Failed to init SDL_Audio: "
               "\"%s\"\n",
               SDL_GetError());
    terminate(1);
  }
  SDL_AudioDeviceID out = SDL_OpenAudioDevice(NULL, 0,
                                              &(SDL_AudioSpec){
                                                  .freq = 24000,
                                                  .format = AUDIO_S16,
                                                  .channels = 1,
                                                  .samples = 256,
                                                  .callback = AudioCB,
                                              },
                                              &have, 0);
  SDL_PauseAudioDevice(out, 0);
}

void SndFreq(u64 f) {
  freq = f;
}

void SetVolume(f64 v) {
  if (v > 1.)
    v = 1.;
  else if (v < 0.)
    v = 0.;
  volume = v;
}

f64 GetVolume(void) {
  return volume;
}
