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
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <SDL.h>

#include <exodus/callconv.h>
#include <exodus/ffi.h>
#include <exodus/main.h>
#include <exodus/misc.h>
#include <exodus/shims.h>
#include <exodus/sound.h>
#include <exodus/types.h>
#include <exodus/window.h>

static struct {
  SDL_mutex *screen_mutex;
  SDL_cond *screen_done_cond;
  SDL_Window *window;
  SDL_Palette *palette;
  SDL_Surface *surf;
  SDL_Renderer *rend;
  i32 sz_x, sz_y;
  i32 margin_x, margin_y;
  bool ready;
} win;

enum {
  WIDTH = 640,
  HEIGHT = 480,
};

static void updatescrn(u8 *px) {
  SDL_LockSurface(win.surf);
  u8 *dst = win.surf->pixels, *src = px;
  u64 sz = WIDTH * HEIGHT;
  asm("rep movsb" : "+D"(dst), "+S"(src), "+c"(sz), "=m"(*(char(*)[sz])dst));
  SDL_UnlockSurface(win.surf);
  SDL_RenderClear(win.rend);
  int w, h, w2, h2, margin_x = 0, margin_y = 0;
  SDL_GetWindowSize(win.window, &w, &h);
  f32 ratio = (f32)WIDTH / HEIGHT;
  if (w > h * ratio) {
    h2 = h;
    w2 = ratio * h;
    margin_x = (w - w2) / 2;
  } else {
    h2 = w / ratio;
    w2 = w;
    margin_y = (h - h2) / 2;
  }
  SDL_Rect viewport = {
      .x = win.margin_x = margin_x,
      .y = win.margin_y = margin_y,
      .w = win.sz_x = w2,
      .h = win.sz_y = h2,
  };
  SDL_Texture *t = SDL_CreateTextureFromSurface(win.rend, win.surf);
  SDL_RenderCopy(win.rend, t, NULL, &viewport);
  SDL_RenderPresent(win.rend);
  SDL_DestroyTexture(t);
  SDL_CondBroadcast(win.screen_done_cond);
}

static void newwindow(void) {
  if (SDL_Init(SDL_INIT_VIDEO)) {
    flushprint(stderr,
               "Failed to init SDL_video: "
               "\"%s\"\n",
               SDL_GetError());
    terminate(1);
  }
  SDL_SetHintWithPriority(SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR, "0",
                          SDL_HINT_OVERRIDE);
  SDL_SetHintWithPriority(SDL_HINT_RENDER_SCALE_QUALITY, "linear",
                          SDL_HINT_OVERRIDE);
  win.screen_mutex = SDL_CreateMutex();
  win.screen_done_cond = SDL_CreateCond();
  SDL_LockMutex(win.screen_mutex);
  win.window =
      SDL_CreateWindow("EXODUS", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                       640, 480, SDL_WINDOW_RESIZABLE);
  win.surf = SDL_CreateRGBSurface(0, 640, 480, 8, 0, 0, 0, 0);
  win.palette = SDL_AllocPalette(256);
  SDL_SetSurfacePalette(win.surf, win.palette);
  SDL_SetWindowMinimumSize(win.window, 640, 480);
  win.rend = SDL_CreateRenderer(win.window, -1, SDL_RENDERER_ACCELERATED);
  win.margin_y = win.margin_x = 0;
  win.sz_x = 640;
  win.sz_y = 480;
  /* let TempleOS manage the cursor */
  SDL_ShowCursor(SDL_DISABLE);
  SDL_SetWindowKeyboardGrab(win.window, SDL_TRUE);
  SDL_UnlockMutex(win.screen_mutex);
  LBts(&win.ready, 0);
}

enum {
  WINDOW_UPDATE,
  WINDOW_NEW,
  AUDIO_INIT,
};

// clang-format off
enum {
  CH_CTRLA       = 0x01,
  CH_CTRLB       = 0x02,
  CH_CTRLC       = 0x03,
  CH_CTRLD       = 0x04,
  CH_CTRLE       = 0x05,
  CH_CTRLF       = 0x06,
  CH_CTRLG       = 0x07,
  CH_CTRLH       = 0x08,
  CH_CTRLI       = 0x09,
  CH_CTRLJ       = 0x0A,
  CH_CTRLK       = 0x0B,
  CH_CTRLL       = 0x0C,
  CH_CTRLM       = 0x0D,
  CH_CTRLN       = 0x0E,
  CH_CTRLO       = 0x0F,
  CH_CTRLP       = 0x10,
  CH_CTRLQ       = 0x11,
  CH_CTRLR       = 0x12,
  CH_CTRLS       = 0x13,
  CH_CTRLT       = 0x14,
  CH_CTRLU       = 0x15,
  CH_CTRLV       = 0x16,
  CH_CTRLW       = 0x17,
  CH_CTRLX       = 0x18,
  CH_CTRLY       = 0x19,
  CH_CTRLZ       = 0x1A,
  CH_CURSOR      = 0x05,
  CH_BACKSPACE   = 0x08,
  CH_ESC         = 0x1B,
  CH_SHIFT_ESC   = 0x1C,
  CH_SHIFT_SPACE = 0x1F,
  CH_SPACE       = 0x20,
};

// Scan code flags
enum {
  SCf_E0_PREFIX = 7,
  SCf_KEY_UP    = 8,
  SCf_SHIFT     = 9,
  SCf_CTRL      = 10,
  SCf_ALT       = 11,
  SCf_CAPS      = 12,
  SCf_NUM       = 13,
  SCf_SCROLL    = 14,
  SCf_NEW_KEY   = 15,
  SCf_MS_L_DOWN = 16,
  SCf_MS_R_DOWN = 17,
  SCf_DELETE    = 18,
  SCf_INS       = 19,
  SCf_NO_SHIFT  = 30,
  SCf_KEY_DESC  = 31,
};

#define SCF_E0_PREFIX  (1u << SCf_E0_PREFIX)
#define SCF_KEY_UP     (1u << SCf_KEY_UP)
#define SCF_SHIFT      (1u << SCf_SHIFT)
#define SCF_CTRL       (1u << SCf_CTRL)
#define SCF_ALT        (1u << SCf_ALT)
#define SCF_CAPS       (1u << SCf_CAPS)
#define SCF_NUM        (1u << SCf_NUM)
#define SCF_SCROLL     (1u << SCf_SCROLL)
#define SCF_NEW_KEY    (1u << SCf_NEW_KEY)
#define SCF_MS_L_DOWN  (1u << SCf_MS_L_DOWN)
#define SCF_MS_R_DOWN  (1u << SCf_MS_R_DOWN)
#define SCF_DELETE     (1u << SCf_DELETE)
#define SCF_INS        (1u << SCf_INS)
#define SCF_NO_SHIFT   (1u << SCf_NO_SHIFT)
#define SCF_KEY_DESC   (1u << SCf_KEY_DESC)

// TempleOS places a 1 in bit 7 for
// keys with an E0 prefix.
// See $LK,"::/Doc/CharOverview.DD"$
// and
// $LK,"KbdHndlr",A="MN:KbdHndlr"$().
enum {
  SC_ESC          = 0x01,
  SC_BACKSPACE    = 0x0E,
  SC_TAB          = 0x0F,
  SC_ENTER        = 0x1C,
  SC_SHIFT        = 0x2A,
  SC_CTRL         = 0x1D,
  SC_ALT          = 0x38,
  SC_CAPS         = 0x3A,
  SC_NUM          = 0x45,
  SC_SCROLL       = 0x46,
  SC_CURSOR_UP    = 0x48,
  SC_CURSOR_DOWN  = 0x50,
  SC_CURSOR_LEFT  = 0x4B,
  SC_CURSOR_RIGHT = 0x4D,
  SC_PAGE_UP      = 0x49,
  SC_PAGE_DOWN    = 0x51,
  SC_HOME         = 0x47,
  SC_END          = 0x4F,
  SC_INS          = 0x52,
  SC_DELETE       = 0x53,
  SC_F1           = 0x3B,
  SC_F2           = 0x3C,
  SC_F3           = 0x3D,
  SC_F4           = 0x3E,
  SC_F5           = 0x3F,
  SC_F6           = 0x40,
  SC_F7           = 0x41,
  SC_F8           = 0x42,
  SC_F9           = 0x43,
  SC_F10          = 0x44,
  SC_F11          = 0x57,
  SC_F12          = 0x58,
  SC_PAUSE        = 0x61,
  SC_GUI          = 0xDB,
  SC_PRTSCRN1     = 0xAA,
  SC_PRTSCRN2     = 0xB7,
};
// clang-format on

static u8 keytab[256] = {
    [CH_ESC] = 1, ['1'] = 2,  ['2'] = 3,   ['3'] = 4,   ['4'] = 5,
    ['5'] = 6,    ['6'] = 7,  ['7'] = 8,   ['8'] = 9,   ['9'] = 10,
    ['0'] = 11,   ['-'] = 12, ['='] = 13,  ['\b'] = 14, ['\t'] = 15,
    ['q'] = 16,   ['w'] = 17, ['e'] = 18,  ['r'] = 19,  ['t'] = 20,
    ['y'] = 21,   ['u'] = 22, ['i'] = 23,  ['o'] = 24,  ['p'] = 25,
    ['['] = 26,   [']'] = 27, ['\n'] = 28, ['a'] = 30,  ['s'] = 31,
    ['d'] = 32,   ['f'] = 33, ['g'] = 34,  ['h'] = 35,  ['j'] = 36,
    ['k'] = 37,   ['l'] = 38, [';'] = 39,  ['\''] = 40, ['`'] = 41,
    ['\\'] = 43,  ['z'] = 44, ['x'] = 45,  ['c'] = 46,  ['v'] = 47,
    ['b'] = 48,   ['n'] = 49, ['m'] = 50,  [','] = 51,  ['.'] = 52,
    ['/'] = 53,   ['*'] = 55, [' '] = 57,  ['+'] = 78,
};
/*static u8 keytab[] = {
    0,   CH_ESC, '1',  '2', '3',  '4', '5', '6', '7', '8', '9', '0', '-',
    '=', '\b',   '\t', 'q', 'w',  'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
    '[', ']',    '\n', 0,   'a',  's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
    ';', '\'',   '`',  0,   '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',',
    '.', '/',    0,    '*', 0,    ' ', 0,   0,   0,   0,   0,   0,   0,
    0,   0,      0,    0,   0,    0,   0,   0,   0,   '-', 0,   '5', 0,
    '+', 0,      0,    0,   0,    0,   0,   0,   0,   0,   0,   0,
};

u64 keymap(u8 ch) {
  for (u64 i = 0; i < Arrlen(keytab); ++i)
    if (keytab[i] == ch)
      return i;
  __builtin_unreachable();
}*/

int ScanKey(u64 *sc, SDL_Event *restrict ev) {
  u64 mod = 0;
  switch (ev->type) {
  case SDL_KEYDOWN:
  ent:
    *sc = ev->key.keysym.scancode;
    if (ev->key.keysym.mod & (KMOD_LSHIFT | KMOD_RSHIFT))
      mod |= SCF_SHIFT;
    else
      mod |= SCF_NO_SHIFT;
    if (ev->key.keysym.mod & (KMOD_LCTRL | KMOD_RCTRL))
      mod |= SCF_CTRL;
    if (ev->key.keysym.mod & (KMOD_LALT | KMOD_RALT))
      mod |= SCF_ALT;
    if (ev->key.keysym.mod & KMOD_CAPS)
      mod |= SCF_CAPS;
    if (ev->key.keysym.mod & KMOD_NUM)
      mod |= SCF_NUM;
    if (ev->key.keysym.mod & KMOD_LGUI)
      mod |= SCF_MS_L_DOWN;
    if (ev->key.keysym.mod & KMOD_RGUI)
      mod |= SCF_MS_R_DOWN;
    switch (ev->key.keysym.scancode) {
    case SDL_SCANCODE_SPACE:
      return *sc = keytab[' '] | mod;
    case SDL_SCANCODE_APOSTROPHE:
      return *sc = keytab['\''] | mod;
    case SDL_SCANCODE_COMMA:
      return *sc = keytab[','] | mod;
    case SDL_SCANCODE_KP_MINUS:
    case SDL_SCANCODE_MINUS:
      return *sc = keytab['-'] | mod;
    case SDL_SCANCODE_KP_PERIOD:
    case SDL_SCANCODE_PERIOD:
      return *sc = keytab['.'] | mod;
    case SDL_SCANCODE_GRAVE:
      return *sc = keytab['`'] | mod;
    case SDL_SCANCODE_KP_DIVIDE:
    case SDL_SCANCODE_SLASH:
      return *sc = keytab['/'] | mod;
    case SDL_SCANCODE_KP_0:
    case SDL_SCANCODE_0:
      return *sc = keytab['0'] | mod;
    case SDL_SCANCODE_KP_1:
    case SDL_SCANCODE_1:
      return *sc = keytab['1'] | mod;
    case SDL_SCANCODE_KP_2:
    case SDL_SCANCODE_2:
      return *sc = keytab['2'] | mod;
    case SDL_SCANCODE_KP_3:
    case SDL_SCANCODE_3:
      return *sc = keytab['3'] | mod;
    case SDL_SCANCODE_KP_4:
    case SDL_SCANCODE_4:
      return *sc = keytab['4'] | mod;
    case SDL_SCANCODE_KP_5:
    case SDL_SCANCODE_5:
      return *sc = keytab['5'] | mod;
    case SDL_SCANCODE_KP_6:
    case SDL_SCANCODE_6:
      return *sc = keytab['6'] | mod;
    case SDL_SCANCODE_KP_7:
    case SDL_SCANCODE_7:
      return *sc = keytab['7'] | mod;
    case SDL_SCANCODE_KP_8:
    case SDL_SCANCODE_8:
      return *sc = keytab['8'] | mod;
    case SDL_SCANCODE_KP_9:
    case SDL_SCANCODE_9:
      return *sc = keytab['9'] | mod;
    case SDL_SCANCODE_SEMICOLON:
      return *sc = keytab[';'] | mod;
    case SDL_SCANCODE_EQUALS:
      return *sc = keytab['='] | mod;
    case SDL_SCANCODE_LEFTBRACKET:
      return *sc = keytab['['] | mod;
    case SDL_SCANCODE_RIGHTBRACKET:
      return *sc = keytab[']'] | mod;
    case SDL_SCANCODE_BACKSLASH:
      return *sc = keytab['\\'] | mod;
    case SDL_SCANCODE_Q:
      return *sc = keytab['q'] | mod;
    case SDL_SCANCODE_W:
      return *sc = keytab['w'] | mod;
    case SDL_SCANCODE_E:
      return *sc = keytab['e'] | mod;
    case SDL_SCANCODE_R:
      return *sc = keytab['r'] | mod;
    case SDL_SCANCODE_T:
      return *sc = keytab['t'] | mod;
    case SDL_SCANCODE_Y:
      return *sc = keytab['y'] | mod;
    case SDL_SCANCODE_U:
      return *sc = keytab['u'] | mod;
    case SDL_SCANCODE_I:
      return *sc = keytab['i'] | mod;
    case SDL_SCANCODE_O:
      return *sc = keytab['o'] | mod;
    case SDL_SCANCODE_P:
      return *sc = keytab['p'] | mod;
    case SDL_SCANCODE_A:
      return *sc = keytab['a'] | mod;
    case SDL_SCANCODE_S:
      return *sc = keytab['s'] | mod;
    case SDL_SCANCODE_D:
      return *sc = keytab['d'] | mod;
    case SDL_SCANCODE_F:
      return *sc = keytab['f'] | mod;
    case SDL_SCANCODE_G:
      return *sc = keytab['g'] | mod;
    case SDL_SCANCODE_H:
      return *sc = keytab['h'] | mod;
    case SDL_SCANCODE_J:
      return *sc = keytab['j'] | mod;
    case SDL_SCANCODE_K:
      return *sc = keytab['k'] | mod;
    case SDL_SCANCODE_L:
      return *sc = keytab['l'] | mod;
    case SDL_SCANCODE_Z:
      return *sc = keytab['z'] | mod;
    case SDL_SCANCODE_X:
      return *sc = keytab['x'] | mod;
    case SDL_SCANCODE_C:
      return *sc = keytab['c'] | mod;
    case SDL_SCANCODE_V:
      return *sc = keytab['v'] | mod;
    case SDL_SCANCODE_B:
      return *sc = keytab['b'] | mod;
    case SDL_SCANCODE_N:
      return *sc = keytab['n'] | mod;
    case SDL_SCANCODE_M:
      return *sc = keytab['m'] | mod;
    case SDL_SCANCODE_KP_MULTIPLY:
      return *sc = keytab['*'] | mod;
    case SDL_SCANCODE_KP_PLUS:
      return *sc = keytab['+'] | mod;
    case SDL_SCANCODE_ESCAPE:
      *sc = mod | SC_ESC;
      return 1;
    case SDL_SCANCODE_BACKSPACE:
      *sc = mod | SC_BACKSPACE;
      return 1;
    case SDL_SCANCODE_TAB:
      *sc = mod | SC_TAB;
      return 1;
    case SDL_SCANCODE_KP_ENTER:
    case SDL_SCANCODE_RETURN:
      *sc = mod | SC_ENTER;
      return 1;
    case SDL_SCANCODE_LSHIFT:
    case SDL_SCANCODE_RSHIFT:
      *sc = mod | SC_SHIFT;
      return 1;
    case SDL_SCANCODE_LALT:
    case SDL_SCANCODE_RALT:
      *sc = mod | SC_ALT;
      return 1;
    case SDL_SCANCODE_LCTRL:
    case SDL_SCANCODE_RCTRL:
      *sc = mod | SC_CTRL;
      return 1;
    case SDL_SCANCODE_CAPSLOCK:
      *sc = mod | SC_CAPS;
      return 1;
    case SDL_SCANCODE_NUMLOCKCLEAR:
      *sc = mod | SC_NUM;
      return 1;
    case SDL_SCANCODE_SCROLLLOCK:
      *sc = mod | SC_SCROLL;
      return 1;
    case SDL_SCANCODE_DOWN:
      *sc = mod | SC_CURSOR_DOWN;
      return 1;
    case SDL_SCANCODE_UP:
      *sc = mod | SC_CURSOR_UP;
      return 1;
    case SDL_SCANCODE_RIGHT:
      *sc = mod | SC_CURSOR_RIGHT;
      return 1;
    case SDL_SCANCODE_LEFT:
      *sc = mod | SC_CURSOR_LEFT;
      return 1;
    case SDL_SCANCODE_PAGEDOWN:
      *sc = mod | SC_PAGE_DOWN;
      return 1;
    case SDL_SCANCODE_PAGEUP:
      *sc = mod | SC_PAGE_UP;
      return 1;
    case SDL_SCANCODE_HOME:
      *sc = mod | SC_HOME;
      return 1;
    case SDL_SCANCODE_END:
      *sc = mod | SC_END;
      return 1;
    case SDL_SCANCODE_INSERT:
      *sc = mod | SC_INS;
      return 1;
    case SDL_SCANCODE_DELETE:
      *sc = mod | SC_DELETE;
      return 1;
    case SDL_SCANCODE_APPLICATION:
    case SDL_SCANCODE_LGUI:
    case SDL_SCANCODE_RGUI:
      *sc = mod | SC_GUI;
      return 1;
    case SDL_SCANCODE_PRINTSCREEN:
      *sc = mod | SC_PRTSCRN1;
      return 1;
    case SDL_SCANCODE_PAUSE:
      *sc = mod | SC_PAUSE;
      return 1;
    case SDL_SCANCODE_F1 ... SDL_SCANCODE_F12:
      *sc = mod | (SC_F1 + (ev->key.keysym.scancode - SDL_SCANCODE_F1));
      return 1;
    default:;
    }
    break;
  case SDL_KEYUP:
    mod |= SCF_KEY_UP;
    goto ent;
  }
  return -1;
}

static void *kb_cb = NULL;
static bool kb_init = false;

int SDLCALL KBCallback(argign void *arg, SDL_Event *e) {
  u64 sc;
  if (kb_cb && (-1 != ScanKey(&sc, e)))
    FFI_CALL_TOS_1(kb_cb, sc);
  return 0;
}

static void *ms_cb = NULL;
static bool ms_init = false;

int SDLCALL MSCallback(argign void *arg, SDL_Event *e) {
  static i32 x, y;
  static int state;
  static int z;
  int x2, y2;
  // return value is actually ignored
  if (!ms_cb)
    return 0;
  switch (e->type) {
  case SDL_MOUSEBUTTONDOWN:
    x = e->button.x, y = e->button.y;
    if (e->button.button == SDL_BUTTON_LEFT)
      state |= 1 << 1;
    else // right
      state |= 1;
    goto ent;
  case SDL_MOUSEBUTTONUP:
    x = e->button.x, y = e->button.y;
    if (e->button.button == SDL_BUTTON_LEFT)
      state &= ~(1 << 1);
    else // right
      state &= ~1;
    goto ent;
  case SDL_MOUSEWHEEL:
    z -= e->wheel.y; // ???, inverted
    goto ent;
  case SDL_MOUSEMOTION:
    x = e->motion.x, y = e->motion.y;
  ent:
    if (x < win.margin_x)
      x2 = 0;
    else if (x > win.margin_x + win.sz_x)
      x2 = 640 - 1; // -1 because zero-indexed
    else
      x2 = (x - win.margin_x) * 640. / win.sz_x;

    if (y < win.margin_y)
      y2 = 0;
    else if (y > win.margin_y + win.sz_y)
      y2 = 480 - 1; // -1 because zero-indexed
    else
      y2 = (y - win.margin_y) * 480. / win.sz_y;
    FFI_CALL_TOS_4(ms_cb, x2, y2, z, state);
  }
  return 0;
}

void EventLoop(void) {
  if (SDL_Init(SDL_INIT_EVENTS)) {
    flushprint(stderr, "%s\n", SDL_GetError());
    terminate(1);
  }
  /* SDL2 src/events/SDL_events.c
   * Will always return SDL_UserEvent */
  SDL_RegisterEvents(1);
  SDL_Event e;
  while (true) {
    if (!SDL_WaitEvent(&e))
      continue;
    switch (e.type) {
    case SDL_QUIT:
      /* I will not attempt to clean and synchronize things up */
      terminate(0);
      break;
    case SDL_USEREVENT:
      switch (e.user.code) {
      case WINDOW_UPDATE:
        updatescrn(e.user.data1);
        break;
      case WINDOW_NEW:
        newwindow();
        break;
      case AUDIO_INIT:
        InitSound();
        break;
      }
    }
  }
}

void SetClipboard(char const *text) {
  SDL_SetClipboardText(text);
}

static void _sdlfree(void *_p) {
  void **p = _p;
  SDL_free(*p);
}

char *ClipboardText(argign void *args) {
  char cleanup(_sdlfree) *s = SDL_GetClipboardText();
  if (!s)
    return NULL;
  return HolyStrDup(s);
}

void DrawWindowUpdate(u8 *px) {
  /* SDL is not fond of threads other than the thread that initialized SDL, so
   * we push to the event queue and let SDL do the rest */
  SDL_PushEvent(&(SDL_Event){
      .user = {
               .type = SDL_USEREVENT,
               .code = WINDOW_UPDATE,
               .data1 = px,
               }
  });
  SDL_LockMutex(win.screen_mutex);
  SDL_CondWaitTimeout(win.screen_done_cond, win.screen_mutex, 1000 / GetFPS());
  // CondWaitTimeout unlocks the mutex for us
}

void DrawWindowNew(void) {
  SDL_PushEvent(&(SDL_Event){
      .user = {
               .type = SDL_USEREVENT,
               .code = WINDOW_NEW,
               }
  });
  while (!Bt(&win.ready, 0))
    __builtin_ia32_pause();
}

void PCSpkInit(void) {
  SDL_PushEvent(&(SDL_Event){
      .user = {
               .type = SDL_USEREVENT,
               .code = AUDIO_INIT,
               }
  });
}

void SetKBCallback(void *fptr) {
  kb_cb = fptr;
  if (kb_init)
    return;
  kb_init = true;
  SDL_AddEventWatch(KBCallback, NULL);
}

void SetMSCallback(void *fptr) {
  ms_cb = fptr;
  if (ms_init)
    return;
  ms_init = true;
  SDL_AddEventWatch(MSCallback, NULL);
}

void GrPaletteColorSet(u64 i, u64 _u) {
  union /* CBGR48 */ {
    u64 i;
    struct __attribute__((packed)) {
      u16 b, g, r, pad;
    };
  } u = {.i = _u};
  /* 0xffff is 100% so 0x7fff/0xffff would be about .50
   * this gets multiplied by 0xff to get 0x7f */
  SDL_Color c = {
      .r = u.r / (double)0xffff * 0xff,
      .g = u.g / (double)0xffff * 0xff,
      .b = u.b / (double)0xffff * 0xff,
      .a = 0xff,
  };
  // set column
  for (int col = 0; col < 256 / 16; ++col)
    SDL_SetPaletteColors(win.palette, &c, i + col * 16, 1);
}
