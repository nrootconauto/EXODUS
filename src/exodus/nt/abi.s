/*-*- mode:unix-assembly; indent-tabs-mode:t; tab-width:8; coding:utf-8     -*-│
│ vi: set noet ft=asm ts=8 sw=8 fenc=utf-8                                  :vi│
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
#include <exodus/abi.h>

// read posix/abi.s for more detailed explanation

// Win64 saved registers (a) := {rbx, rdi, rsi, r12 ~ r15}
// TempleOS saved registers (b) := {rdi, rdi, rsi, r10 ~ r15}
// ∴ regs to save := a - b = {rbx}

// i64 fficall(void *fp, i64 argc, i64 *argv);
fficall:
	push	%rbp
	mov	%rsp,%rbp
	push	%rbx
	mov	%rcx,%rax
	test	%edx,%edx
	jz	1f
	mov	%edx,%ecx
	shl	$3,%ecx
	sub	%rcx,%rsp
	.balign	8
0:	mov	-8(%r8,%rdx,8),%rbx
	mov	%rbx,-8(%rsp,%rdx,8)
	sub	$1,%edx
	jnz	0b
	.balign	8
1:	call	*%rax
	pop	%rbx
	pop	%rbp
	ret
	.endfn	fficall,globl

// i64 fficallnullbp(void *fp, i64 argc, i64 *argv);
fficallnullbp:
	push	%rbp
	push	%rbx
	mov	%rcx,%rax
	push	$0 // fake return addr ──┐ ← fake function call
	push	$0 // fake rbp ──────────┴┬─ ← fake function prolog
	mov	%rsp,%rbp //  ───────────┬┘
	test	%edx,%edx //             │
	jnz	1f //                    │
0:	call	*%rax //                 │
	add	$0x10,%rsp // ───────────┘ this block is one "function"
	pop	%rbx
	pop	%rbp
	ret
	.balign	8
1:	mov	%edx,%ecx
	shl	$3,%ecx
	sub	%rcx,%rsp
	.balign	8
2:	mov	-8(%r8,%rdx,8),%rbx
	mov	%rbx,-8(%rsp,%rdx,8)
	sub	$1,%edx
	jnz	2b
	jmp	0b
	.endfn	fficallnullbp,globl
