// -*- mode:unix-assembly; indent-tabs-mode:t; tab-width:8; coding:utf-8 -*-
// vi: set noet ft=asm ts=8 sw=8 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#include <exodus/abi.h>

// System V saved registers (a) := {rbx, r12 ~ r15}
// TempleOS saved registers (b) := {rdi, rsi, r10 ~ r15}
// (not counting stack registers)
//
// since we're calling HolyC from SysV, a - b = {rbx}
// (if vice versa (a la ffi.c), b - a)
// ∴ only push rbx

.text.hot
// i64 fficall(void *fp, i64 argc, i64 *argv);
fficall:
	push	%rbp
	mov	%rsp,%rbp
	push	%rbx
	mov	%rdi,%rax
	test	%esi,%esi
	jz	1f
	mov	%esi,%ecx
	shl	$3,%ecx
	sub	%rcx,%rsp
	sub	$1,%esi
	.balign	8
0:	mov	(%rdx,%rsi,8),%rcx
	mov	%rcx,(%rsp,%rsi,8)
	sub	$1,%esi
	jnb	0b
	.balign	8
1:	call	*%rax
	pop	%rbx
	pop	%rbp
	ret
	.endfn	fficall,globl

// i64 fficallnullbp(void *fp, i64 argc, i64 *argv);
// NULL base ptr/return addr to terminate stack trace
// used to start up cores (Seth)
fficallnullbp:
	push	%rbp
	push	%rbx
	mov	%rdi,%rax
	push	$0 // fake return addr ──┐ ← fake function call
	push	$0 // fake rbp ──────────┼────┬─ fake function prolog
	mov	%rsp,%rbp //  ───────────┼────┘
	test	%esi,%esi //             │
	jnz	1f //                    │
0:	call	*%rax //                 │
	add	$0x10,%rsp // ───────────┘ this block is one "function"
	pop	%rbx
	pop	%rbp
	ret
	.balign	8
1:	mov	%esi,%ecx
	shl	$3,%ecx
	sub	%rcx,%rsp
	sub	$1,%esi
	.balign	8
2:	mov	(%rdx,%rsi,8),%rcx
	mov	%rcx,(%rsp,%rsi,8)
	sub	$1,%esi
	jnb	2b
	jmp	0b
	.endfn	fficallnullbp,globl

// i64 fficallcustombp(void *rbp, void *fp, i64 argc, i64 *argv);
// user-supplied RBP so ProfTimerInt can correctly determine where RIP is
fficallcustombp:
	push	%rbp
	push	%rbx
	mov	%rdi,%rbp // fake rbp
	mov	%rsi,%rax
	test	%edx,%edx
	jz	1f
	mov	%edx,%ebx
	shl	$3,%ebx
	sub	%rbx,%rsp
	sub	$1,%edx
	.balign	8
0:	mov	(%rcx,%rdx,8),%rbx
	mov	%rbx,(%rsp,%rdx,8)
	sub	$1,%edx
	jnb	0b
	.balign	8
1:	call	*%rax
	pop	%rbx
	pop	%rbp
	ret
	.endfn	fficallcustombp,globl

.section .note.GNU-stack,"",@progbits
