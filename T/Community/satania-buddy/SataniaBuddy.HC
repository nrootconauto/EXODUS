#define MOVE_RANDOM 0
#define SNAP_TO_ACTIVE_WINDOW 1
#define SIT 2
#define STAND 3
#define TALK_RANDOM 4
#define TALK_INPUT 5

U8 *CONTEXT_MENU =
    "Move Random\0Snap to Active Window\0Sit\0Stand\0Talk Random\0Talk Input\0";

class Coords2D {
  I64 x;
  I64 y;
};

class Talk {
  U8 *text;
  U8 *src;
  I64 pos;
  I64 line;
  I64 ticks;
  I64 split_cnt;
};

class Window {
  CTask *task;
  I64 left;
  I64 top;
};

class Satania {
  Bool is_talking;
  Bool move_random;
  Bool snap_to_window;
  Coords2D mouth;
  Coords2D pos;
  Coords2D origin;
  CDC **frame;
  I64 sprite_index;
  Talk talk;
  Window window;
};

class Mouse {
  Bool is_dragging;
  Bool lb;
  Bool rb;
  Coords2D origin;
};

Mouse mouse;
Satania satania;

U0 string_append(U8 *dst, U8 *fmt, ...) {
  U8 *buf;
  if (argc) {
    buf = StrPrintJoin(NULL, fmt, argc, argv);
  } else {
    buf = StrNew(fmt);
  }
  U8 *src = buf;
  StrCpy(dst + StrLen(dst), src);
  Free(buf);
}

U8 **string_split(U8 *s) {
  U8 *p = s;
  satania.talk.split_cnt = 0;
  while (*p) {
    if (*p == ' ')
      satania.talk.split_cnt++;
    p++;
  }
  if (!(satania.talk.split_cnt))
    return NULL;
  satania.talk.split_cnt++;
  I64 i = -1;
  U8 **arr = CAlloc(sizeof(U8 *) * satania.talk.split_cnt);
  p = s;
  while (*p) {
    if (*p == ' ' || i < 0) {
      i++;
      arr[i] = p;
      if (*p == ' ') {
        arr[i]++;
        *p = NULL;
      }
    }
    p++;
  }
  return arr;
}

#define SATANIA_TEXT_CHOICES 2
U8 **satania_text = CAlloc(sizeof(U8 *) * SATANIA_TEXT_CHOICES);
satania_text[0] = "iToddlers BTFO!";
satania_text[1] =
    "I'd just like to interject for a moment. What you're referring to as "
    "Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, "
    "GNU plus Linux. Linux is not an operating system unto itself, but rather "
    "another free component of a fully functioning GNU system made useful by "
    "the GNU corelibs, shell utilities and vital system components comprising "
    "a full OS as defined by POSIX. Many computer users run a modified version "
    "of the GNU system every day, without realizing it. Through a peculiar "
    "turn of events, the version of GNU which is widely used today is often "
    "called \"Linux\", and many of its users are not aware that it is "
    "basically "
    "the GNU system, developed by the GNU Project. There really is a Linux, "
    "and these people are using it, but it is just a part of the system they "
    "use. Linux is the kernel: the program in the system that allocates the "
    "machine's resources to the other programs that you run. The kernel is an "
    "essential part of an operating system, but useless by itself; it can only "
    "function in the context of a complete operating system. Linux is normally "
    "used in combination with the GNU operating system: the whole system is "
    "basically GNU with Linux added, or GNU/Linux. All the so-called \"Linux\" "
    "distributions are really distributions of GNU/Linux.";

U0 @load_frames() {
  I64 i = 0;
  CDirEntry *de = FilesFind("assets/*.GR*");
  CDirEntry *de2 = de;
  while (de2) {
    i++;
    de2 = de2->next;
  }
  satania.frame = CAlloc(sizeof(CDC *) * i);
  i = 0;
  de2 = de;
  while (de2) {
    satania.frame[i++] = GRRead(de2->full_name);
    de2 = de2->next;
  }
  DirTreeDel(de);
}

U0 @set_initial_values() {
  satania.mouth.x = 27;
  satania.mouth.y = 44;
  satania.sprite_index = 5;
  satania.is_talking = FALSE;
  satania.move_random = TRUE;
  satania.snap_to_window = FALSE;
  satania.pos.x = 520;
  satania.pos.y = 200;
  mouse.is_dragging = FALSE;
  mouse.lb = ms.lb;
  mouse.rb = ms.rb;
}

	Bool @mouse_is_hovered() {
  return (
      ms.pos.x >= satania.pos.x &&
      ms.pos.x <= satania.pos.x + satania.frame[satania.sprite_index]->width &&
      ms.pos.y >= satania.pos.y &&
      ms.pos.y <= satania.pos.y + satania.frame[satania.sprite_index]->height);
}

CDC *mouth_sprite() {
  if (Blink(1.75))
    return satania.frame[3];
  return satania.frame[1];
}

U0 update_talking_text() {
  gr.dc->color = BLACK;
  U8 buf[1024];
  MemSet(buf, NULL, 1024);
  if (satania.talk.pos > StrLen(satania.talk.text))
    StrCpy(buf, satania.talk.text);
  else
    MemCpy(buf, satania.talk.text, satania.talk.pos);
  GrPrint(gr.dc, satania.pos.x - satania.frame[0]->width + 10,
          satania.pos.y + 10, buf);
  if (__GetTicks > satania.talk.ticks + 100) {
    satania.talk.pos++;
    if (satania.talk.text[satania.talk.pos] == '\n') {
      satania.talk.line++;
      if (satania.talk.line > 9) {
        satania.talk.pos -=
            StrFirstOcc(satania.talk.text, "\n") + 1 - satania.talk.text;
        satania.talk.text = StrFirstOcc(satania.talk.text, "\n") + 1;
      }
    }
    satania.talk.ticks = __GetTicks;
  }
}

U0 focus_popup_list() {
  CTask *task;
  CTask *child_task;
  while (1) {
    task = adam_task->next_child_task;
    while (task) {
      if (TaskValidate(task->next_child_task)) { //He checked for NULL by almost NULL's are lurking around.
        child_task = task->next_child_task;
        if (!MemCmp(child_task->task_name, "Servant", 7) &&
            child_task->win_left == 0x01 && child_task->win_right == 0x16) {
          WinToTop(child_task);
          break;
        }
      }
      task = task->next_sibling_task;
      Sleep(1);
    }
    Sleep(1);
  }
}

U8 *choose_random_text() { return satania_text[Rand * SATANIA_TEXT_CHOICES]; }

U8 *format_str(U8 *str) {
  I64 i = 0;
  I64 pos = 0;
  U8 *res = CAlloc(StrLen(str) * 2);
  U8 **strs = string_split(str);
  for (i = 0; i < satania.talk.split_cnt; i++) {
    if (pos + StrLen(strs[i]) > 22) {
      string_append(res, "\n");
      pos = 0;
    }
    string_append(res, strs[i]);
    pos += StrLen(strs[i]);
    string_append(res, " ");
    pos++;
  }
  return res;
}

U0 Finalize() {
  DCFill;
}
U0 SataniaBuddy() {
  @load_frames;
  @set_initial_values;
  Fs->task_end_cb=&Finalize;
  I64 lbtn, rbtn;
  I64 res;
  I64 rand_ticks;
  I64 rnd;
  Bool update = TRUE;
  CTask *task;
  U8 *input_str;
  U8 *wrap_str;
  while (1) {
    lbtn = ms.lb;
    rbtn = ms.rb;
    if (mouse.lb != lbtn) {
      if (lbtn) {
        if (@mouse_is_hovered) {
          mouse.origin.x = ms.pos.x;
          mouse.origin.y = ms.pos.y;
          satania.origin.x = satania.pos.x;
          satania.origin.y = satania.pos.y;
          mouse.is_dragging = TRUE;
        } else
          mouse.is_dragging = FALSE;
      } else
        mouse.is_dragging = FALSE;
      mouse.lb = lbtn;
    }
    if (mouse.rb != rbtn) {
      if (rbtn && @mouse_is_hovered) {
        task = Spawn(&focus_popup_list);
        res = PopUpPickLst(CONTEXT_MENU);
        Kill(task);
        switch (res) {
        case MOVE_RANDOM:
          rand_ticks = __GetTicks;
          satania.sprite_index = 5;
          satania.pos.x = Rand * 640;
          satania.pos.y = Rand * 480;
          satania.snap_to_window = FALSE;
          satania.move_random = TRUE;
          update = TRUE;
          break;
        case SNAP_TO_ACTIVE_WINDOW:
          satania.move_random = FALSE;
          satania.snap_to_window = TRUE;
          satania.window.task = NULL;
          satania.window.left = 0;
          satania.window.top = 0;
          break;
        case SIT:
          satania.sprite_index = 4;
          update = TRUE;
          break;
        case STAND:
          satania.sprite_index = 5;
          satania.snap_to_window = FALSE;
          update = TRUE;
          break;
        case TALK_RANDOM:
        satania_talk_random:
          input_str = StrNew(choose_random_text);
          wrap_str = format_str(input_str);
          satania.talk.text = wrap_str;
          satania.talk.src = wrap_str;
          Free(input_str);
          satania.talk.pos = 0;
          satania.talk.line = 0;
          satania.talk.ticks = __GetTicks;
          satania.is_talking = TRUE;
          update = TRUE;
          break;
        case TALK_INPUT:
          input_str = PopUpGetStr("Say:");
          wrap_str = format_str(input_str);
          satania.talk.text = wrap_str;
          satania.talk.src = wrap_str;
          Free(input_str);
          satania.talk.pos = 0;
          satania.talk.line = 0;
          satania.talk.ticks = __GetTicks;
          satania.is_talking = TRUE;
          update = TRUE;
          break;
        default:
          break;
        }
      }
      mouse.rb = rbtn;
    }
    if (__GetTicks > rand_ticks + 4096) {
      rnd = Rand * 1024;
      if (rnd < 256 && satania.move_random) {
        satania.pos.x = Rand * 640;
        satania.pos.y = Rand * 480;
        update = TRUE;
      }
      if (rnd > 256 && rnd < 384 && !satania.is_talking) {
        rand_ticks = __GetTicks;
        goto satania_talk_random;
        break;
      }
      rand_ticks = __GetTicks;
    }
    if (satania.snap_to_window)
      satania.sprite_index = 4;
    if(TaskValidate(sys_focus_task))
    if (satania.snap_to_window &&
        ((satania.window.task != sys_focus_task) ||
         (satania.window.left != sys_focus_task->win_left ||
          satania.window.top != sys_focus_task->win_top))) {
      satania.window.task = sys_focus_task;
      satania.window.left = sys_focus_task->win_left;
      satania.window.top = sys_focus_task->win_top;
      satania.pos.x = (sys_focus_task->win_left * 8) - 8;
      satania.pos.y = (sys_focus_task->win_top * 8) - 150;
      update = TRUE;
    }
    if (mouse.is_dragging) {
      satania.is_talking = FALSE;
      satania.snap_to_window = FALSE;
      update = TRUE;
    }
    if (mouse.is_dragging &&
        (mouse.origin.x != ms.pos.x || mouse.origin.y != ms.pos.y)) {
      satania.pos.x = satania.origin.x + (ms.pos.x - mouse.origin.x);
      satania.pos.y = satania.origin.y + (ms.pos.y - mouse.origin.y);
      update = TRUE;
    }
    if (update) {
      DCFill(gr.dc);
      GrBlot(gr.dc, satania.pos.x, satania.pos.y,
             satania.frame[satania.sprite_index]);
    }
    if (satania.is_talking) {
      GrBlot(gr.dc, satania.pos.x - satania.frame[0]->width, satania.pos.y,
             satania.frame[0]);
      update_talking_text;
      GrBlot(gr.dc, satania.pos.x + satania.mouth.x,
             satania.pos.y + satania.mouth.y, mouth_sprite);
    }
    update = FALSE;
    if (satania.is_talking &&
        satania.talk.pos > StrLen(satania.talk.text) + 5) {
      satania.talk.pos = 0;
      Free(satania.talk.src);
      satania.is_talking = FALSE;
      update = TRUE;
    }
    Refresh;
  }
}
Spawn(&SataniaBuddy, , "SataniaBuddy",,Fs);

