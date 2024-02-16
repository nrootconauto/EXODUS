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

#include "misc.h"
#include "shims.h"
#include "sound.h"

static u64 sample, freq;
static SDL_AudioSpec have;
static f64 volume = .1;

static void AudioCB(argign void *ud, Uint8 *out, int len) {
  for (int i = 0; i < len / have.channels; ++i) {
    f64 t = (f64)++sample / have.freq;
    Sint8 maxed = (sin(2 * M_PI * t * freq) > 0. ? 127 : -127) * volume;
    if (!freq)
      maxed = 0;
    for (Uint8 j = 0; j < have.channels; ++j)
      out[have.channels * i + j] = (Uint8)maxed;
  }
}

void InitSound(void) {
#ifdef __linux__
  /* Spent two hours figuring out why there was static in the tunes.
   * Linux devs, presumably a highly acclaimed group,
   * cannot reach a consensus on how to push waves through speakers. */
  SDL_SetHint(SDL_HINT_AUDIODRIVER, "pipewire");
  if (SDL_Init(SDL_INIT_AUDIO))
    SDL_SetHintWithPriority(SDL_HINT_AUDIODRIVER, NULL, SDL_HINT_OVERRIDE);
    /* Calling init twice doesn't seem to impose a problem */
#endif
  if (SDL_Init(SDL_INIT_AUDIO)) {
    flushprint(stderr,
               "Failed to init SDL_Audio: "
               "\"%s\"\n",
               SDL_GetError());
    terminate(1);
  }
  SDL_AudioDeviceID out =
      SDL_OpenAudioDevice(NULL, 0,
                          &(SDL_AudioSpec){
                              .freq = 24000,
                              .format = AUDIO_S8,
                              .channels = 2,
                              .samples = 512,
                              .callback = AudioCB,
                          },
                          &have, SDL_AUDIO_ALLOW_FREQUENCY_CHANGE);
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
