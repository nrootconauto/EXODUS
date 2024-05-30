#pragma once

/* u64: uintptr_t, uint64_t, size_t, uintmax_t
 *      (uintmax_t is left for debate, ∵ __uint128_t)
 * i64: intptr_t, int64_t, ptrdiff_t, intmax_t */
typedef int i64 __attribute__((mode(DI), may_alias));
typedef int i32 __attribute__((mode(SI), may_alias));
typedef int i16 __attribute__((mode(HI), may_alias));
typedef int i8 __attribute__((mode(QI), may_alias));

typedef unsigned u64 __attribute__((mode(DI), may_alias));
typedef unsigned u32 __attribute__((mode(SI), may_alias));
typedef unsigned u16 __attribute__((mode(HI), may_alias));
typedef unsigned u8 __attribute__((mode(QI), may_alias));

typedef double f64 __attribute__((may_alias));
typedef float f32 __attribute__((may_alias));
