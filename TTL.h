/*
 * TTL.h
 *
 * Copyright (c) 2025 Mobileye
 *
 * Licensed under the Apache License, Version 2.0 (the License);
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#pragma once

#ifndef TTL_COPY_3D
#define TTL_COPY_3D
#endif

/* The Khronos TTL runtime library (event_t, tiler, DMA helpers) is only
 * needed when compiling for actual OpenCL execution.  The TTL compiler
 * frontend (cgeist) only needs the scheduling macros below --- pass
 * -DTTL_MACROS_ONLY on the cgeist command line to skip the library. */
#ifndef TTL_MACROS_ONLY
#ifdef __cplusplus
#include "TTL_cpp/TTL.h"
#else
#include "TTL_c/TTL.h"
#endif
#endif

/* ===============================================================================
 * TTL Compiler Macros
 *
 * Scheduling hints consumed by the TTL compiler (cgeist -x cl + ttl-opt).
 * Standard OpenCL compilers ignore unknown pragmas --- safe in any source.
 * No tiling? Just write normal for-loops --- the compiler won't touch them.
 *
 * Usage:
 *   #include "TTL/TTL.h"
 *
 *   __kernel void gemm(const TTL_TENSOR_2D(A, int, M, K),
 *                      const TTL_TENSOR_2D(B, int, K, N),
 *                      TTL_TENSOR_2D(C, int, M, N)) {
 *
 *       TTL_LOOP_3D(i, 0, M, 64,
 *                   j, 0, N, 64,
 *                   k, 0, K, 64,
 *                   TTL_DOUBLE_BUFFER) {
 *           TTL_2D(C, i,1,0, j,1,0) += TTL_2D(A, i,1,0, k,1,0) * TTL_2D(B, k,1,0, j,1,0);
 *       }
 *   }
 * =============================================================================== */

#define _TTL_SCHED_STR_HELPER(...) #__VA_ARGS__
#define _TTL_SCHED_STR(...)        _TTL_SCHED_STR_HELPER(__VA_ARGS__)
#define _TTL_SCHED_PRAGMA(...)     _Pragma(_TTL_SCHED_STR(ttl __VA_ARGS__))

/* ===============================================================================
 * Kernel Parameter Macros
 *
 *   TTL_TENSOR_2D(A, int, M, K)  -> __global int _ttl_A[restrict M][K]
 *   Access via TTL_2D(A, i,1,0, k,1,0) expands to _ttl_A[1*i+0][1*k+0]
 *
 * The raw variable is hidden --- all accesses must go through TTL().
 *
 * LIMITATION: VLA declarations assume contiguous row-major storage
 * (stride == innermost dimension).  Unlike the Khronos runtime, which
 * separates TTL_shape_t (logical size) from TTL_layout_t (memory stride),
 * our macros cannot represent padded allocations where stride > width
 * or sub-views into a larger matrix.  This is a deliberate trade-off:
 * full-rank static shapes give MLIR complete affine analysis information,
 * at the cost of not supporting non-contiguous global layouts.
 * Future work: an optional stride parameter could lift this restriction.
 * =============================================================================== */

#define _TTL_NAME(name) _ttl_##name

/* -----------------------------------------------------------------------
 * DESIGN REQUIREMENT: Single code path
 *
 * The SAME source file must compile and run correctly via:
 *   1. cgeist → ttl-opt → ttl-translate  (compiler optimization path)
 *   2. OpenCL compiler (e.g. PoCL) directly  (unoptimized execution)
 *
 * No #ifdef splits between the two paths.  Every macro must expand to
 * valid C / OpenCL C in both contexts.
 *
 * OPEN ISSUE: Compile-time constant enforcement
 *
 * The scale and offset fields in TTL_1D/2D/3D (si, oi, sj, oj, ...)
 * and the tile sizes / bounds in TTL_LOOP_1D/2D/3D MUST be compile-time
 * constants for correct affine analysis.  Currently this is enforced
 * ONLY by the compiler (cgeist rejects non-affine patterns), NOT by
 * the macros.  Macro-level enforcement is blocked by two C limitations:
 *
 *   1. _Static_assert is a declaration, not an expression.  It cannot
 *      appear inside the array subscripts of TTL_1D/2D/3D.
 *
 *   2. TTL_LOOP_*D may appear as a single-statement for-body (e.g.
 *      04_batch_gemm.c: "for (b ...) TTL_LOOP_3D(...)").  Emitting a
 *      declaration before the for-loop would break that scoping.
 *
 * Resolving this requires either:
 *   - A cgeist-level diagnostic (proper compiler error, not macro trick)
 *   - A C language extension that provides expression-level constant
 *     checking across both OpenCL C and plain C
 *
 * Until then, misuse produces a confusing downstream error from cgeist
 * rather than a clear message at the macro expansion site.
 * ----------------------------------------------------------------------- */

#define TTL_TENSOR_1D(name, type, N)       __global type _TTL_NAME(name)[restrict N]
#define TTL_TENSOR_2D(name, type, R, C)    __global type _TTL_NAME(name)[restrict R][C]
#define TTL_TENSOR_3D(name, type, D, H, W) __global type _TTL_NAME(name)[restrict D][H][W]

#define TTL_1D(name, i, si, oi) \
    _TTL_NAME(name)[(si) * (i) + (oi)]
#define TTL_2D(name, i, si, oi, j, sj, oj) \
    _TTL_NAME(name)[(si) * (i) + (oi)][(sj) * (j) + (oj)]
#define TTL_3D(name, i, si, oi, j, sj, oj, k, sk, ok) \
    _TTL_NAME(name)[(si) * (i) + (oi)][(sj) * (j) + (oj)][(sk) * (k) + (ok)]

#define TTL_1D_2IV(name, a, b) \
    _TTL_NAME(name)[(a) + (b)]
#define TTL_2D_2IV(name, a1, b1, a2, b2) \
    _TTL_NAME(name)[(a1) + (b1)][(a2) + (b2)]
#define TTL_3D_2IV(name, a1, b1, a2, b2, a3, b3) \
    _TTL_NAME(name)[(a1) + (b1)][(a2) + (b2)][(a3) + (b3)]

/* ===============================================================================
 * Tiled Loop Nest
 *
 * Each dimension is (var, start, end, tile_size).
 * Last argument: buffering mode --- TTL_DOUBLE_BUFFER or TTL_TILE_ONLY.
 * The compiler decides what to pipeline and how much local memory to use.
 *
 *   TTL_LOOP_3D(i, 0, M, 64,
 *               j, 0, N, 64,
 *               k, 0, K, 64,
 *               TTL_DOUBLE_BUFFER) { body }
 * =============================================================================== */

#define TTL_DOUBLE_BUFFER 1
#define TTL_TILE_ONLY     0

#define _TTL_MODE_1 tiled_pipeline
#define _TTL_MODE_0 tile
#define _TTL_CAT2(a, b) a##b
#define _TTL_CAT(a, b)  _TTL_CAT2(a, b)
#define _TTL_MODE(p)    _TTL_CAT(_TTL_MODE_, p)

#define TTL_LOOP_1D(i, i0, i1, t1, mode) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1)) \
    for (int i = (i0); i < (i1); i++)

#define TTL_LOOP_2D(i, i0, i1, t1, j, j0, j1, t2, mode) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2)) \
    for (int i = (i0); i < (i1); i++) \
        for (int j = (j0); j < (j1); j++)

#define TTL_LOOP_3D(i, i0, i1, t1, j, j0, j1, t2, k, k0, k1, t3, mode) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2, t3)) \
    for (int i = (i0); i < (i1); i++) \
        for (int j = (j0); j < (j1); j++) \
            for (int k = (k0); k < (k1); k++)

