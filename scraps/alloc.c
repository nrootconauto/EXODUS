/*
 * This is garbage for alloc_unix.c.
 * I'm using a simple bump allocator instead.
 */
static uint64_t lexhex(char *s, char **next) {
  uint64_t ret = 0;
  for (char c; Bt(char_bmp_hex_numeric, c = *s); s++) {
    ret <<= 4;
    ret |= Bt(char_bmp_alpha, c) ? (c & ~(uchar)0b100000) - 'A' + 10 : c - '0';
  }
  *next = s;
  return ret;
}

static intptr_t low32(size_t sz) {
  int fd = open("/proc/self/maps", O_RDONLY);
  if (veryunlikely(fd == -1))
    return 0;
  char buf[BUFSIZ], *cur;
  // base address of allocation gap/region
  ssize_t bytesread, pos;
  // hi: upper bound of previous region
  // lo: lower bound of current region
  int64_t lo, hi = 0;
  while ((bytesread = read(fd, buf, BUFSIZ)) > 0) {
    pos = 0;
    while (pos < bytesread) {
      /* ↓
       * ????-???? */
      cur = buf + pos;
      lo = lexhex(cur, &cur);
      hi = ALIGN(hi, pag); // MAP_FIXED req.
      if (hi && lo - hi >= sz)
        goto ret;
      /*     ↓
       * ????-???? */
      cur++;
      hi = lexhex(cur, &cur);
      pos = cur - buf;
      while (pos < bytesread && buf[pos] != '\n')
        pos++;
      pos++;
    }
  }
ret:
  close(fd);
  if (hi > UINT32_MAX)
    return 0;
  return hi;
}

