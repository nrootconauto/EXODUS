/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <SDL2/SDL.h>

#include <EXODUS/misc.h>
#include <EXODUS/shims.h>
#include <EXODUS/sound.h>

static u64 sample, freq;
static SDL_AudioSpec have;
static f64 volume = .2;

enum {
  MAX = 1 << 14 // headspace for vol=1.f
};

static void AudioCB(argign void *ud, Uint8 *_out, int _len) {
  Sint16 *out = (Sint16 *)_out;
  int len = _len / 2;
  if (unlikely(!freq)) {
    memset(_out, 0, _len);
    return;
  }
  for (int i = 0; i < len / have.channels; ++i) {
    f64 t = (f64)++sample / have.freq;
    double w = sin(2 * M_PI * t * freq);
    w /= fabs(w);
    w *= MAX;
    Sint16 maxed = w * volume;
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
                                                  .samples = 512,
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

/*═════════════════════════════════════════════════════════════════════════════╡
│ EXODUS: Executable Divine Operating System in Userspace                      │
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ This file is part of EXODUS.                                                 │
│                                                                              │
│ Permission to use, copy, modify, and/or distribute this software for         │
│ any purpose with or without fee is hereby granted, provided that the         │
│ above copyright notice and this permission notice appear in all copies.      │
│                                                                              │
│ THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL                │
│ WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED                │
│ WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE             │
│ AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL         │
│ DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR        │
│ PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER               │
│ TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR             │
│ PERFORMANCE OF THIS SOFTWARE.                                                │
╚─────────────────────────────────────────────────────────────────────────────*/
