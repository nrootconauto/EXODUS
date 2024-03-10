/*-*- vi: set et ft=asm ts=2 sts=2 sw=2 fenc=utf-8                      :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
.intel_syntax noprefix
.global __TOSTHUNK_START
.global __TOSTHUNK_END
// separate file because asm() in glbl scope will be deleted by LTO
.data

__TOSTHUNK_START:
    push   rbp
    mov    rbp,rsp
    and    rsp,-16 // ...F0h, both ABIs require alignment
    push   rsi
    push   rdi
    push   r10
    push   r11
    push   r12
    push   r13
    push   r14
    push   r15
#ifdef _WIN32
    lea    rcx,[rbp+0x10]
    push   r9 /* 4 register homes required for win32[1] */
    push   r8
    push   rdx
    push   rcx
#else
    lea    rdi,[rbp+0x10]
#endif
/* CCh is INT3, an assembler won't just randomly insert a bunch of them */
    movabs rax,0xCCCCCCCCCCCCCCCC
    call   rax
#ifdef _WIN32
    add    rsp,0x20 // volatile regs don't need restore, so no pop
#endif
    pop    r15
    pop    r14
    pop    r13
    pop    r12
    pop    r11
    pop    r10
    pop    rdi
    pop    rsi
    leave
/* F4h is HLT, a ring0 opcode, so we can safely assume this is the only instance */
    ret   0xF4F4
__TOSTHUNK_END:

#ifndef _WIN32
// Richard, the fuck
.section .note.GNU-stack,"",@progbits
#endif

/* CITATIONS:
 * [1]
 * https://learn.microsoft.com/en-us/cpp/build/stack-usage?view=msvc-170#stack-allocation
 *     (https://archive.md/4HDA0#selection-2085.429-2085.1196)
 */
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
