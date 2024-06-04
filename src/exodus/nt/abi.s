// -*- mode:unix-assembly; indent-tabs-mode:t; tab-width:8; coding:utf-8 -*-
// vi: set noet ft=asm ts=8 sw=8 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#include <exodus/abi.h>

// read posix/abi.s for more detailed explanation

// Win64 saved registers    (a) := {rbx, rdi, rsi, r12 ~ r15}
// TempleOS saved registers (b) := {rdi, rsi, r10 ~ r15}
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
	sub	$1,%edx
	.balign	8
0:	mov	(%r8,%rdx,8),%rbx
	mov	%rbx,(%rsp,%rdx,8)
	sub	$1,%edx
	jnb	0b
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
	push	$0 // fake rbp ──────────┼────┬─ fake function prolog
	mov	%rsp,%rbp //  ───────────┼────┘
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
	sub	$1,%edx
	.balign	8
2:	mov	(%r8,%rdx,8),%rbx
	mov	%rbx,(%rsp,%rdx,8)
	sub	$1,%edx
	jnb	2b
	jmp	0b
	.endfn	fficallnullbp,globl

// i64 fficallcustombp(void *rbp, void *fp, i64 argc, i64 *argv)
fficallcustombp:
	push	%rbp
	push	%rbx
	mov	%rcx,%rbp // fake rbp
	mov	%rdx,%rax
	test	%r8,%r8
	jz	1f
	mov	%r8,%rbx
	shl	$3,%ebx
	sub	%rbx,%rsp
	sub	$1,%r8
	.balign	8
0:	mov	(%r9,%r8,8),%rbx
	mov	%rbx,(%rsp,%r8,8)
	sub	$1,%r8
	jnb	0b
	.balign	8
1:	call	*%rax
	pop	%rbx
	pop	%rbp
	ret
	.endfn	fficallcustombp,globl
