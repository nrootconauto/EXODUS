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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <SDL.h>
#include <argtable3.h>
#include <isocline.h>

#include <exodus/dbg.h>
#include <exodus/ffi.h>
#include <exodus/loader.h>
#include <exodus/main.h>
#include <exodus/misc.h>
#include <exodus/seth.h>
#include <exodus/shims.h>
#include <exodus/sound.h>
#include <exodus/vfs.h>
#include <exodus/window.h>

static char bin_path[0x200], *boot_str;
__attribute__((constructor)) static void init(void) {
  strcpy(bin_path, "HCRT.BIN");
}

static struct arg_lit *help, *_60fps, *cli;
static struct arg_file *clifiles, *drv, *hcrt;
static struct arg_end *end;

u64 IsCmdLine(void) {
  return !!cli->count;
}

char *CmdLineBootText(void) {
  return boot_str;
}

int GetFPS(void) {
  return _60fps->count ? 60 : 30;
}

int main(int argc, char **argv) {
  prepare();
  void *argtable[] = {
      help = arg_lit0("h", "help", "This help message"),
      _60fps = arg_lit0("6", "60fps", "Run in 60 FPS"),
      cli = arg_lit0("c", "com", "Command line mode"),
      hcrt = arg_file0("f", "hcrtfile", NULL, "Specify HolyC runtime"),
      drv = arg_file0("t", "root", NULL, "Specify boot folder"),
      clifiles = arg_filen(NULL, NULL, "<files>", 0, 100,
                           ".HC files that run on startup, used with -c"),
      end = arg_end(10),
  };
  int errs = arg_parse(argc, argv, argtable);
  if (help->count || errs > 0 || !drv->count) {
    if (errs)
      arg_print_errors(stderr, end, argv[0]);
    flushprint(stderr, "Usage: %s", argv[0]);
    arg_print_syntaxv(stderr, argtable, "\n");
    arg_print_glossary_gnu(stderr, argtable);
    return 1;
  }
  if (fexists(drv->filename[0])) {
    VFsMountDrive('T', drv->filename[0]);
  } else {
    flushprint(stderr, "Can't find \"%s\"", drv->filename[0]);
    return 1;
  }
  VFsMountDrive('Z', ".");
  vec_char_t boot = {0};
  if (cli->count) {
    ic_set_history(NULL, -1);
    ic_enable_auto_tab(true);
    char buf[0x100];
    for (int i = 0; i < clifiles->count; ++i) {
      snprintf(buf, sizeof buf, "#include \"%s\";\n", clifiles->filename[i]);
      vec_pushstr(&boot, buf);
    }
#ifdef _WIN32
    vec_push(&boot, '\0');
    char *s;
    while ((s = strchr(boot.data, '\\')))
      *s++ = '/';
    vec_pop(&boot);
#endif
  }
  if (_60fps->count)
    vec_pushstr(&boot, "SetFPS(60.);\n");
  vec_push(&boot, '\0');
  boot_str = boot.data;
  if (hcrt->count)
    strcpy(bin_path, hcrt->filename[0]);
  if (!fexists(bin_path)) {
    flushprint(stderr,
               "%s DOES NOT EXIST, MAYBE YOU FORGOT TO BOOTSTRAP IT? REFER "
               "TO README FOR GUIDANCE\n",
               bin_path);
    return 1;
  }
  BootstrapLoader();
  CreateCore(LoadHCRT(bin_path));
  EventLoop();
  return 0;
}