/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#ifndef _WIN32
  #include <sys/resource.h>
#endif

#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tos_callconv.h"

#include "isocline.h"
#include "vendor/argtable3.h"

#include "dbg.h"
#include "ffi.h"
#include "main.h"
#include "misc.h"
#include "sdl_window.h"
#include "seth.h"
#include "shims.h"
#include "sound.h"
#include "tos_aot.h"
#include "vfs.h"

static char bin_path[0x400], *boot_str;
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
  setlocale(LC_ALL, "C");
#ifndef _WIN32
  struct rlimit rl;
  getrlimit(RLIMIT_NOFILE, &rl);
  rl.rlim_cur = rl.rlim_max;
  setrlimit(RLIMIT_NOFILE, &rl);
#endif
  void *argtable[] = {
      help = arg_lit0("h", "help", "Display this help message"),
      _60fps = arg_lit0("6", "60fps", "Run in 60 fps mode."),
      cli = arg_lit0("c", "com", "Command line mode, cwd -> Z:/"),
      hcrt = arg_file0("f", "file", NULL, "Specify HolyC runtime"),
      drv = arg_file0("t", "root", NULL, "Specify boot folder"),
      clifiles = arg_filen(NULL, NULL, "<files>", 0, 100,
                           "Files that run on boot(cmdline mode specific)"),
      end = arg_end_(10),
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
  if (cli->count) {
    VFsMountDrive('Z', ".");
    ic_set_history(NULL, -1);
    ic_enable_auto_tab(true);
    vec_char_t tmp;
    vec_init(&tmp);
    char buf[0x200];
    for (int i = 0; i < clifiles->count; ++i) {
      snprintf(buf, sizeof buf, "#include \"%s\";\n", clifiles->filename[i]);
      vec_pusharr(&tmp, buf, strlen(buf));
    }
    vec_push(&tmp, 0);
#ifdef _WIN32
    char *s;
    while ((s = strchr(tmp.data, '\\')))
      *s++ = '/';
#endif
    boot_str = strdup(tmp.data);
  } else if (_60fps->count)
    boot_str = strdup("SetFPS(60.);\n");
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
