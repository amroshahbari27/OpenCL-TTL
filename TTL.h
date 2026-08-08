/*
 * TTL.h
 *
 * Copyright (c) 2025 Mobileye
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#pragma once

/*
 * The source DSL below is also parsed with TTL_MACROS_ONLY, which keeps
 * cgeist away from runtime-only OpenCL builtins. Normal OpenCL compilation
 * includes the upstream TTL implementation.
 */
#ifndef TTL_COPY_3D
#define TTL_COPY_3D
#endif

#ifndef TTL_MACROS_ONLY
#ifdef __cplusplus
#include "TTL_cpp/TTL.h"
#else
#include "TTL_c/TTL.h"
#endif
#else
/* Reuse TTL's C-compatible target type/address-space definitions in DSL IR. */
#include "TTL_c/opencl/TTL_types.h"
#endif

#define _TTL_SCHED_STR_HELPER(...) #__VA_ARGS__
#define _TTL_SCHED_STR(...) _TTL_SCHED_STR_HELPER(__VA_ARGS__)
#define _TTL_SCHED_PRAGMA(...) _Pragma(_TTL_SCHED_STR(ttl __VA_ARGS__))
#define _TTL_NAME(name) _ttl_##name
#define _TTL_IV(v) v##_MUST_BE_DECLARED_BY_TTL_LOOP

/*
 * TTL_LOOP_*D's last two arguments before the body are bare, unlabeled
 * parenthesized tensor-name lists -- e.g. `(C), (A, B), { ... }` -- which
 * reads fine once you already know the convention but says nothing at the
 * call site about which list is which. These two macros are the standing,
 * canonical way to name that convention instead of leaving it implicit:
 * wrap each list in the one that matches its role. Both simply forward
 * their arguments unchanged in parentheses -- there is no new parsing,
 * behavior, or attribute; TTL_LOOP_*D sees an identical token stream
 * either way. Language-independent (no #ifdef __cplusplus split needed):
 * pure textual substitution, defined once, used by both the C and C++
 * TTL_LOOP_*D forms below.
 *
 *   TTL_LOOP_3D(i, 0, M, 64, j, 0, N, 64, k, 0, K, 64,
 *               TTL_PROMOTE_ONLY(C),
 *               TTL_PROMOTE_AND_DOUBLE_BUFFER(A, B), {
 *       ...
 *   })
 */
#define TTL_PROMOTE_ONLY(...) (__VA_ARGS__)
#define TTL_PROMOTE_AND_DOUBLE_BUFFER(...) (__VA_ARGS__)

/*
 * Pure full-rank declarators: name, rank, and static extents only. Element
 * type, constness, and address space stay explicit at the use site through
 * upstream TTL's TTL_global(type)/TTL_local(type) vocabulary.
 */
#define TTL_TENSOR_1D(name, N) _TTL_NAME(name)[N]
#define TTL_TENSOR_2D(name, R, C) _TTL_NAME(name)[R][C]
#define TTL_TENSOR_3D(name, D, H, W) _TTL_NAME(name)[D][H][W]

#ifndef __cplusplus
/*
 * Scale and offset must be compile-time constants. The derived IV name also
 * ensures that an access names an induction variable declared by TTL_LOOP.
 */
static inline int _ttl_check_constant_scale(int scale)
    __attribute__((diagnose_if(!__builtin_constant_p(scale),
        "TTL_1D_AR/2D_AR/3D_AR: scale must be a compile-time constant", "error"))) {
  return scale;
}

static inline int _ttl_check_constant_offset(int offset)
    __attribute__((diagnose_if(!__builtin_constant_p(offset),
        "TTL_1D_AR/2D_AR/3D_AR: offset must be a compile-time constant", "error"))) {
  return offset;
}

#define _TTL_CHECK_DIAG2(a, b) \
    ({ _Static_assert(__builtin_strcmp(#a, #b) != 0, \
        "diagonal access: index '" #a \
        "' used for two axes of the same tensor access"); 0; })
#define _TTL_IS_ZERO_LIT(s) (__builtin_strcmp(#s, "0") == 0)
#define _TTL_CHECK_DIAG2_SCALED(a, sa, b, sb) \
    ({ _Static_assert(_TTL_IS_ZERO_LIT(sa) || _TTL_IS_ZERO_LIT(sb) || \
        __builtin_strcmp(#a, #b) != 0, \
        "diagonal access uses one index on two nonzero-scale axes"); 0; })

#define TTL_1D_AR(name, i, si, oi) \
    _TTL_NAME(name)[_ttl_check_constant_scale(si) * _TTL_IV(i) + \
                    _ttl_check_constant_offset(oi)]
#define TTL_2D_AR(name, i, si, oi, j, sj, oj) \
    _TTL_NAME(name)[(_TTL_CHECK_DIAG2_SCALED(i, si, j, sj), \
                     _ttl_check_constant_scale(si) * _TTL_IV(i) + \
                     _ttl_check_constant_offset(oi))] \
                   [_ttl_check_constant_scale(sj) * _TTL_IV(j) + \
                    _ttl_check_constant_offset(oj)]
#define TTL_3D_AR(name, i, si, oi, j, sj, oj, k, sk, ok) \
    _TTL_NAME(name)[(_TTL_CHECK_DIAG2_SCALED(i, si, j, sj), \
                     _TTL_CHECK_DIAG2_SCALED(i, si, k, sk), \
                     _ttl_check_constant_scale(si) * _TTL_IV(i) + \
                     _ttl_check_constant_offset(oi))] \
                   [(_TTL_CHECK_DIAG2_SCALED(j, sj, k, sk), \
                     _ttl_check_constant_scale(sj) * _TTL_IV(j) + \
                     _ttl_check_constant_offset(oj))] \
                   [_ttl_check_constant_scale(sk) * _TTL_IV(k) + \
                    _ttl_check_constant_offset(ok)]

#define TTL_1D_ID(name, i) _TTL_NAME(name)[_TTL_IV(i)]
#define TTL_2D_ID(name, i, j) \
    _TTL_NAME(name)[(_TTL_CHECK_DIAG2(i, j), _TTL_IV(i))][_TTL_IV(j)]
#define TTL_3D_ID(name, i, j, k) \
    _TTL_NAME(name)[(_TTL_CHECK_DIAG2(i, j), _TTL_CHECK_DIAG2(i, k), \
                     _TTL_IV(i))] \
                   [(_TTL_CHECK_DIAG2(j, k), _TTL_IV(j))][_TTL_IV(k)]

#define TTL_LOOP_1D(i, i0, i1, t1, promote, db, ...) \
    _TTL_SCHED_PRAGMA(tiled_pipeline_mb(t1) promote db) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); ++_TTL_IV(i)) { \
      __VA_ARGS__ \
    }

#define TTL_LOOP_2D(i, i0, i1, t1, j, j0, j1, t2, promote, db, ...) \
    _TTL_SCHED_PRAGMA(tiled_pipeline_mb(t1, t2) promote db) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); ++_TTL_IV(i)) \
      for (int _TTL_IV(j) = (j0); _TTL_IV(j) < (j1); ++_TTL_IV(j)) { \
        __VA_ARGS__ \
      }

#define TTL_LOOP_3D(i, i0, i1, t1, j, j0, j1, t2, k, k0, k1, t3, \
                    promote, db, ...) \
    _TTL_SCHED_PRAGMA(tiled_pipeline_mb(t1, t2, t3) promote db) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); ++_TTL_IV(i)) \
      for (int _TTL_IV(j) = (j0); _TTL_IV(j) < (j1); ++_TTL_IV(j)) \
        for (int _TTL_IV(k) = (k0); _TTL_IV(k) < (k1); ++_TTL_IV(k)) { \
          __VA_ARGS__ \
        }

#else

/*
 * The physical C++ loop counters remain int so Polygeist recognizes affine
 * loops. Body-local typed aliases make access scales and offsets template
 * constants and reject unrelated integer indices.
 */
enum class _TTL_Induc : int {};

template <int Scale, int Offset>
__attribute__((always_inline))
constexpr int _ttl_affine_idx(_TTL_Induc iv) {
  return Scale * static_cast<int>(iv) + Offset;
}

static inline constexpr bool _ttl_streq(__constant const char *a,
                                        __constant const char *b) {
  while (*a && *b) {
    if (*a != *b)
      return false;
    ++a;
    ++b;
  }
  return *a == *b;
}

#define _TTL_CHECK_DIAG2(a, b) \
    ({ static_assert(!_ttl_streq(#a, #b), \
        "diagonal access: index '" #a \
        "' used for two axes of the same tensor access"); 0; })
#define _TTL_IS_ZERO_LIT(s) (_ttl_streq(#s, "0"))
#define _TTL_CHECK_DIAG2_SCALED(a, sa, b, sb) \
    ({ static_assert(_TTL_IS_ZERO_LIT(sa) || _TTL_IS_ZERO_LIT(sb) || \
        !_ttl_streq(#a, #b), \
        "diagonal access uses one index on two nonzero-scale axes"); 0; })

#define _TTL_RAW(v) v##_TTL_RAW_COUNTER

#define TTL_1D_AR(name, i, si, oi) \
    _TTL_NAME(name)[_ttl_affine_idx<si, oi>(i)]
#define TTL_2D_AR(name, i, si, oi, j, sj, oj) \
    _TTL_NAME(name)[(_TTL_CHECK_DIAG2_SCALED(i, si, j, sj), \
                     _ttl_affine_idx<si, oi>(i))] \
                   [_ttl_affine_idx<sj, oj>(j)]
#define TTL_3D_AR(name, i, si, oi, j, sj, oj, k, sk, ok) \
    _TTL_NAME(name)[(_TTL_CHECK_DIAG2_SCALED(i, si, j, sj), \
                     _TTL_CHECK_DIAG2_SCALED(i, si, k, sk), \
                     _ttl_affine_idx<si, oi>(i))] \
                   [(_TTL_CHECK_DIAG2_SCALED(j, sj, k, sk), \
                     _ttl_affine_idx<sj, oj>(j))] \
                   [_ttl_affine_idx<sk, ok>(k)]

#define TTL_1D_ID(name, i) \
    _TTL_NAME(name)[_ttl_affine_idx<1, 0>(i)]
#define TTL_2D_ID(name, i, j) \
    _TTL_NAME(name)[(_TTL_CHECK_DIAG2(i, j), _ttl_affine_idx<1, 0>(i))] \
                   [_ttl_affine_idx<1, 0>(j)]
#define TTL_3D_ID(name, i, j, k) \
    _TTL_NAME(name)[(_TTL_CHECK_DIAG2(i, j), _TTL_CHECK_DIAG2(i, k), \
                     _ttl_affine_idx<1, 0>(i))] \
                   [(_TTL_CHECK_DIAG2(j, k), _ttl_affine_idx<1, 0>(j))] \
                   [_ttl_affine_idx<1, 0>(k)]

#define TTL_LOOP_1D(i, i0, i1, t1, promote, db, ...) \
    _TTL_SCHED_PRAGMA(tiled_pipeline_mb(t1) promote db) \
    for (int _TTL_RAW(i) = (i0); _TTL_RAW(i) < (i1); ++_TTL_RAW(i)) { \
      const _TTL_Induc i = static_cast<_TTL_Induc>(_TTL_RAW(i)); \
      __VA_ARGS__ \
    }

#define TTL_LOOP_2D(i, i0, i1, t1, j, j0, j1, t2, promote, db, ...) \
    _TTL_SCHED_PRAGMA(tiled_pipeline_mb(t1, t2) promote db) \
    for (int _TTL_RAW(i) = (i0); _TTL_RAW(i) < (i1); ++_TTL_RAW(i)) \
      for (int _TTL_RAW(j) = (j0); _TTL_RAW(j) < (j1); ++_TTL_RAW(j)) { \
        const _TTL_Induc i = static_cast<_TTL_Induc>(_TTL_RAW(i)); \
        const _TTL_Induc j = static_cast<_TTL_Induc>(_TTL_RAW(j)); \
        __VA_ARGS__ \
      }

#define TTL_LOOP_3D(i, i0, i1, t1, j, j0, j1, t2, k, k0, k1, t3, \
                    promote, db, ...) \
    _TTL_SCHED_PRAGMA(tiled_pipeline_mb(t1, t2, t3) promote db) \
    for (int _TTL_RAW(i) = (i0); _TTL_RAW(i) < (i1); ++_TTL_RAW(i)) \
      for (int _TTL_RAW(j) = (j0); _TTL_RAW(j) < (j1); ++_TTL_RAW(j)) \
        for (int _TTL_RAW(k) = (k0); _TTL_RAW(k) < (k1); ++_TTL_RAW(k)) { \
          const _TTL_Induc i = static_cast<_TTL_Induc>(_TTL_RAW(i)); \
          const _TTL_Induc j = static_cast<_TTL_Induc>(_TTL_RAW(j)); \
          const _TTL_Induc k = static_cast<_TTL_Induc>(_TTL_RAW(k)); \
          __VA_ARGS__ \
        }

#endif
