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
 *
 * IV name hiding: TTL_LOOP declares 'i_iv_ttl' (not 'i'), and TTL_2D(C, i, ...)
 * expands to '_ttl_C[... i_iv_ttl ...]'.  If 'i' didn't come from TTL_LOOP,
 * 'i_iv_ttl' is undeclared -> compile error.  The user writes short names (i, j, k)
 * in both TTL_LOOP and TTL_2D; the _iv_ttl suffix is added automatically.
 *
 * Trade-off: the error message for misuse is "undeclared identifier 'x_iv_ttl'"
 * rather than a domain-specific diagnostic.  Also, the user cannot reference
 * the loop IV directly in the body (e.g. 'int row = i * width' fails because
 * 'i' doesn't exist -- the actual variable is 'i_iv_ttl').  This is the cost
 * of structural enforcement via C macros; a cgeist-level diagnostic could
 * provide better error messages in the future.
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

#ifdef __cplusplus
/* C99's array-parameter-qualifier syntax `type name[restrict N]` is not
 * valid C++ (any spelling of restrict) -- C++ has no array-qualifier
 * declarator.
 *
 * TRIED FIRST: the semantically-equivalent pointer-to-array form
 * `type (*__restrict__ name)[C]`. Valid C++, but verified (both in C++
 * AND in plain C -- not a C++-specific bug) to make cgeist's memref shape
 * inference collapse the type to 1-D and miscompute multi-dimensional
 * subscripts (e.g. a[3][5] on a 512-wide array came out as index 8,
 * i.e. 3+5, instead of 3*512+5). cgeist's --memref-fullrank logic only
 * recognizes the literal C99 bracket-array declarator syntax.
 *
 * FIX: drop the qualifier and keep the plain bracket-array declarator
 * (`type name[R][C]`), which is valid C++ on its own -- only the
 * C99 *qualifier-inside-brackets* part was ever illegal. Verified this
 * produces correct memref<RxCxtype> shape and correct affine.load/store
 * subscripts. Restrict semantics are not lost: OpenCL C++ kernel
 * parameters default to no-alias, and ttl.restrict is still observed
 * on the resulting argument (verified in the generated MLIR) even
 * without writing `restrict` explicitly. */
#define TTL_TENSOR_1D(name, type, N)       __global type _TTL_NAME(name)[N]
#define TTL_TENSOR_2D(name, type, R, C)    __global type _TTL_NAME(name)[R][C]
#define TTL_TENSOR_3D(name, type, D, H, W) __global type _TTL_NAME(name)[D][H][W]
#else
#define TTL_TENSOR_1D(name, type, N)       __global type _TTL_NAME(name)[restrict N]
#define TTL_TENSOR_2D(name, type, R, C)    __global type _TTL_NAME(name)[restrict R][C]
#define TTL_TENSOR_3D(name, type, D, H, W) __global type _TTL_NAME(name)[restrict D][H][W]
#endif

#define _TTL_IV(v) v##_iv_ttl

#define TTL_1D(name, i, si, oi) \
    _TTL_NAME(name)[(si) * _TTL_IV(i) + (oi)]
#define TTL_2D(name, i, si, oi, j, sj, oj) \
    _TTL_NAME(name)[(si) * _TTL_IV(i) + (oi)][(sj) * _TTL_IV(j) + (oj)]
#define TTL_3D(name, i, si, oi, j, sj, oj, k, sk, ok) \
    _TTL_NAME(name)[(si) * _TTL_IV(i) + (oi)][(sj) * _TTL_IV(j) + (oj)][(sk) * _TTL_IV(k) + (ok)]

#define TTL_1D_2IV(name, a, b) \
    _TTL_NAME(name)[_TTL_IV(a) + _TTL_IV(b)]
#define TTL_2D_2IV(name, a1, b1, a2, b2) \
    _TTL_NAME(name)[_TTL_IV(a1) + _TTL_IV(b1)][_TTL_IV(a2) + _TTL_IV(b2)]
#define TTL_3D_2IV(name, a1, b1, a2, b2, a3, b3) \
    _TTL_NAME(name)[_TTL_IV(a1) + _TTL_IV(b1)][_TTL_IV(a2) + _TTL_IV(b2)][_TTL_IV(a3) + _TTL_IV(b3)]

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

#ifdef __cplusplus
/* ===============================================================================
 * C++ structured access (opt-in via --std=clc++2021 / -x c++ compilation)
 *
 * Solves the compile-time-constant enforcement problem documented above
 * (six approaches tried and rejected in plain C, all blocked by C's lack
 * of an expression-level compile-time assertion): Scale/Offset become
 * non-type template parameters. A non-constant value now fails to
 * compile AT THE CALL SITE with a real template-instantiation error,
 * instead of a confusing downstream cgeist affine-analysis failure.
 * The loop induction variable stays a PLAIN int, unchanged from the C
 * path -- see the two rejected designs below for why.
 *
 * This does NOT replace the C path -- it is a strictly additive, opt-in
 * mode selected by the compiler invocation's language standard, mirroring
 * the existing __cplusplus branch this file already uses for the runtime
 * include (TTL_cpp/ vs TTL_c/, above).
 *
 * REJECTED DESIGN 1 -- class-with-methods IV strong type (TTL_IV_t as a
 * class with a constructor, operator<, operator++): crashes cgeist.
 * Polygeist's MLIRScanner hits "unhandled cast" (clang-mlir.cc:4452),
 * verified directly. Originally attributed to the implicit `this`
 * address-space conversion for member calls specifically -- that
 * attribution is too narrow (re-verified with free, non-member
 * operators AND with by-reference parameters: identical crash, same
 * location, either way). The actual trigger is broader: OpenCL C++
 * implicitly inserts an AddressSpaceConversion cast (__private ->
 * __generic) whenever ANY struct/class-typed local crosses ANY
 * function-parameter boundary, by value or by reference, member or
 * free function -- MLIRScanner::VisitCastExpr has no case for
 * CK_AddressSpaceConversion at all, so this is a genuine cgeist gap,
 * not something a different calling convention routes around. Full
 * experiment log, including the by-reference retest: see
 * TTL-CPP-STRUCTURED-ACCESS-DESIGN.md §16.3.
 *
 * REJECTED DESIGN 2 -- `enum class TTL_IV_t` for the loop variable
 * (method-free, sidesteps the crash above): compiles, but verified to
 * silently defeat affine promotion. Polygeist's isTrivialAffineLoop()
 * requires the induction variable to be a plain integer type; a
 * TTL_LOOP_3D loop declared as TTL_IV_t never gets ttl.tile/ttl.pipeline
 * attached and stays scf.for all the way through -emit-ttl, verified
 * against a real GEMM kernel (plain-C same kernel: full affine.for +
 * ttl.tile preserved; TTL_IV_t version: scf.for, no ttl.* attributes at
 * all -- not even on the outermost loop). Any *distinct* IV type hits
 * this wall, not just classes -- it's not about strong-typing specifically,
 * it's that cgeist's affine-loop detector doesn't recognize non-primitive
 * induction variable types, full stop. Since this would have only added a
 * narrow secondary protection (catching a user who hand-declares
 * `int i_iv_ttl` to impersonate a loop-declared IV -- a deliberate,
 * adversarial edge case, not a realistic mistake) at the cost of breaking
 * the actual affine/tiling pipeline for every kernel, it is not worth
 * keeping. The IV-hiding suffix trick (above) already makes the
 * realistic misuse -- using a variable that never came from TTL_LOOP at
 * all -- a compile error on its own.
 * =============================================================================== */

template <int Scale, int Offset>
__attribute__((always_inline))
constexpr int _ttl_affine_idx(int iv) {
    return Scale * iv + Offset;
}

#undef TTL_1D
#undef TTL_2D
#undef TTL_3D
#undef TTL_1D_2IV
#undef TTL_2D_2IV
#undef TTL_3D_2IV

#define TTL_1D(name, i, si, oi) \
    _TTL_NAME(name)[_ttl_affine_idx<si, oi>(_TTL_IV(i))]
#define TTL_2D(name, i, si, oi, j, sj, oj) \
    _TTL_NAME(name)[_ttl_affine_idx<si, oi>(_TTL_IV(i))][_ttl_affine_idx<sj, oj>(_TTL_IV(j))]
#define TTL_3D(name, i, si, oi, j, sj, oj, k, sk, ok) \
    _TTL_NAME(name)[_ttl_affine_idx<si, oi>(_TTL_IV(i))][_ttl_affine_idx<sj, oj>(_TTL_IV(j))][_ttl_affine_idx<sk, ok>(_TTL_IV(k))]

#define TTL_1D_2IV(name, a, b) \
    _TTL_NAME(name)[_TTL_IV(a) + _TTL_IV(b)]
#define TTL_2D_2IV(name, a1, b1, a2, b2) \
    _TTL_NAME(name)[_TTL_IV(a1) + _TTL_IV(b1)][_TTL_IV(a2) + _TTL_IV(b2)]
#define TTL_3D_2IV(name, a1, b1, a2, b2, a3, b3) \
    _TTL_NAME(name)[_TTL_IV(a1) + _TTL_IV(b1)][_TTL_IV(a2) + _TTL_IV(b2)][_TTL_IV(a3) + _TTL_IV(b3)]

#define TTL_LOOP_1D(i, i0, i1, t1, mode) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1)) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); _TTL_IV(i)++)

#define TTL_LOOP_2D(i, i0, i1, t1, j, j0, j1, t2, mode) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2)) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); _TTL_IV(i)++) \
        for (int _TTL_IV(j) = (j0); _TTL_IV(j) < (j1); _TTL_IV(j)++)

#define TTL_LOOP_3D(i, i0, i1, t1, j, j0, j1, t2, k, k0, k1, t3, mode) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2, t3)) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); _TTL_IV(i)++) \
        for (int _TTL_IV(j) = (j0); _TTL_IV(j) < (j1); _TTL_IV(j)++) \
            for (int _TTL_IV(k) = (k0); _TTL_IV(k) < (k1); _TTL_IV(k)++)

#else /* !__cplusplus : plain OpenCL C, unchanged from before */

#define TTL_LOOP_1D(i, i0, i1, t1, mode) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1)) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); _TTL_IV(i)++)

#define TTL_LOOP_2D(i, i0, i1, t1, j, j0, j1, t2, mode) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2)) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); _TTL_IV(i)++) \
        for (int _TTL_IV(j) = (j0); _TTL_IV(j) < (j1); _TTL_IV(j)++)

#define TTL_LOOP_3D(i, i0, i1, t1, j, j0, j1, t2, k, k0, k1, t3, mode) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2, t3)) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); _TTL_IV(i)++) \
        for (int _TTL_IV(j) = (j0); _TTL_IV(j) < (j1); _TTL_IV(j)++) \
            for (int _TTL_IV(k) = (k0); _TTL_IV(k) < (k1); _TTL_IV(k)++)

#endif /* __cplusplus */

