/*-*- vi: set noet ft=asm ts=8 sw=8 fenc=utf-8                          :vi -*-│
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
.global __TOSTHUNK_START
.global __TOSTHUNK_END

.data

__TOSTHUNK_START:
	push	%rbp
	mov	%rsp,%rbp
/* both ABIs require alignment so we just cut down (this is okay since the stack grows down) */
	and	$~0xF,%rsp
	push	%r10
	push	%r11
#ifdef _WIN32
	sub 	$0x20,%rsp /* 4 register homes required for win32[1] */
	lea	0x10(%rbp),%rcx
#else
	push	%rsi
	push	%rdi
	lea	0x10(%rbp),%rdi
#endif
/* F3h is the REP prefix, a repeated sequence of it isn't valid code */
	movabs  $0xF3f3F3f3F3f3F3f3,%rax
	call	*%rax
#ifdef _WIN32
	add	$0x20,%rsp /* volatile regs don't need restore, so just add */
#else
	pop	%rdi
	pop	%rsi
#endif
	pop	%r11
	pop	%r10
/* restoring %rsp is mandatory here because we cut %rsp down and the callee expects a preserved %rsp */
	mov	%rbp,%rsp 
	pop	%rbp
/* F4h is HLT, a ring0 opcode, so we can safely assume this is the only instance */
	ret	$0xF4f4
__TOSTHUNK_END:

#ifndef _WIN32
/* Stallman wants you to write this or else he makes your stack executable */
.section .note.GNU-stack,"",@progbits
#endif

/* CITATIONS:
 * [1]
 * https://learn.microsoft.com/en-us/cpp/build/stack-usage?view=msvc-170#stack-allocation
 *     (https://archive.md/4HDA0#selection-2085.429-2085.1196)
 */

