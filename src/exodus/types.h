#pragma once

/* u64: uintptr_t, uint64_t, size_t, uintmax_t
 *      (uintmax_t is left for debate, ∵ __uint128_t)
 * i64: intptr_t, int64_t, ptrdiff_t, intmax_t */
typedef int i64 __attribute__((mode(DI)));
typedef int i32 __attribute__((mode(SI)));
typedef int i16 __attribute__((mode(HI)));
typedef int i8 __attribute__((mode(QI)));

typedef unsigned u64 __attribute__((mode(DI)));
typedef unsigned u32 __attribute__((mode(SI)));
typedef unsigned u16 __attribute__((mode(HI)));
typedef unsigned u8 __attribute__((mode(QI)));

typedef double f64;
typedef float f32;
