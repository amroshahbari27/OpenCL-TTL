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
 *                   TTL_DOUBLE_BUFFER, {
 *           TTL_2D(C, i,1,0, j,1,0) += TTL_2D(A, i,1,0, k,1,0) * TTL_2D(B, k,1,0, j,1,0);
 *       })
 *   }
 *
 * Body is a macro argument (trailing { ... }, not a bare brace block after
 * the call) -- same syntax on both the C and C++ paths. IV name hiding:
 * TTL_LOOP declares 'i_MUST_BE_DECLARED_BY_TTL_LOOP' (not 'i'), and
 * TTL_2D(C, i, ...) expands to reference that exact derived name (C mode)
 * or a body-local '_TTL_Induc'-typed alias named 'i' the macro declares
 * from it (C++ mode, see the C++ branch below for why). If 'i' didn't
 * come from TTL_LOOP, the reference fails to compile either way.
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
 * RESOLVED: Compile-time constant enforcement (scale/offset)
 *
 * The scale and offset fields in TTL_1D/2D/3D (si, oi, sj, oj, ...)
 * MUST be compile-time constants for correct affine analysis. This used
 * to be enforced ONLY by the compiler downstream (cgeist rejects
 * non-affine patterns with a confusing error far from the macro
 * expansion site) -- now it's enforced right at the TTL_1D/2D/3D call
 * site, with a real, specific diagnostic.
 *
 * _Static_assert doesn't work here (it's a declaration, not an
 * expression -- can't appear inside TTL_1D/2D/3D's array subscripts),
 * and the classic __builtin_constant_p + sizeof(int[cond?1:-1]) trick,
 * while it DOES work (verified directly against cgeist -- Clang's Sema
 * checks array-size validity, and Polygeist reuses Sema unmodified),
 * only gives a generic "array size is negative" error with no domain
 * information. A second attempt, __attribute__((error(...))) on a
 * poisoned function gated by __builtin_constant_p in a ternary, gives a
 * fully custom message on plain clang -- but does NOT survive cgeist:
 * verified directly, Polygeist's custom AST-to-MLIR walker doesn't
 * replicate the CodeGen-level dead-branch elimination this trick needs,
 * so it conservatively assumes __builtin_constant_p is always false and
 * calls the poisoned function unconditionally, breaking even the
 * correct/constant case.
 *
 * WORKING: __attribute__((diagnose_if(...))) (Clang-specific, checked
 * during Sema -- same phase Polygeist reuses unmodified, which is why
 * this survives cgeist where the poison-function trick didn't). Verified
 * directly: the constant case compiles clean and inlines away completely
 * (identical affine.load/store MLIR to the unchecked version, zero
 * codegen cost); the non-constant case fails with the exact custom
 * message below, at the exact usage site, on both cgeist and the
 * direct-exec leg (clang -cl-std=... -> SPIR-V). Both TTLCompiler legs
 * are Clang-based, so diagnose_if's non-portability to GCC isn't a
 * practical restriction here.
 *
 * IV provenance (as opposed to scale/offset constant-ness) is a
 * different, harder problem -- see the C++ branch below and
 * TTL-CPP-STRUCTURED-ACCESS-DESIGN.md §16 for why no C-portable
 * equivalent of the C++ _TTL_Induc body-alias check was found; plain C
 * keeps the name-mangled rename (_TTL_IV, "hide it behind a prefix/suffix
 * so the wrong name doesn't exist") as its only IV-provenance mechanism.
 * Every angle tried to give it C++'s type-based protection instead was
 * ruled out directly, not assumed:
 *   - plain C `enum` gives zero protection on its own -- implicit
 *     int-to-enum conversion is silently allowed, even at -Wall -Wextra.
 *   - Clang DOES have a warning for exactly this
 *     (-Wimplicit-int-enum-cast, promotable to a hard error via a
 *     _Pragma right in this header) -- but it does not exist in Clang 18,
 *     the actual pinned toolchain both TTLCompiler legs use (confirmed:
 *     grepped a -Weverything run against the real pinned binary). It
 *     only appears in much newer Clang. So this specific fix is blocked
 *     on a toolchain upgrade, not a fundamental language limitation --
 *     if this project ever moves off Clang 18, this is worth retrying.
 *   - The one diagnostic Clang 18 does have for this
 *     (-Wsign-conversion) is too broad to promote to an error: it fires
 *     129 times on TTL's own existing upstream runtime headers alone.
 *   - C11 _Generic (exact-type dispatch, which would sidestep the
 *     implicit-conversion problem entirely) crashes cgeist unconditionally
 *     -- confirmed with the simplest possible _Generic expression, no
 *     relation to IV-checking specifically. Polygeist's MLIRScanner has
 *     no visitor for GenericSelectionExpr at all.
 * ----------------------------------------------------------------------- */

/* Compile-time-constant checks for TTL_1D/2D/3D's scale/offset. Each
 * function just returns its argument unchanged (fully inlined away by
 * cgeist/clang for any real, constant call -- verified: zero codegen
 * cost, affine recognition unaffected) -- diagnose_if is what actually
 * does the work, firing only when the argument isn't a compile-time
 * constant. */
static inline int _ttl_check_constant_scale(int scale)
    __attribute__((diagnose_if(!__builtin_constant_p(scale),
        "TTL_1D/2D/3D: scale must be a compile-time constant", "error")))
{
    return scale;
}
static inline int _ttl_check_constant_offset(int offset)
    __attribute__((diagnose_if(!__builtin_constant_p(offset),
        "TTL_1D/2D/3D: offset must be a compile-time constant", "error")))
{
    return offset;
}

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

/* Renamed from the earlier v##_iv_ttl: this identifier only exists if
 * TTL_LOOP declared it, and the name itself now says so directly --
 * misuse (an identifier TTL_LOOP never declared) fails with
 * "use of undeclared identifier 'x_MUST_BE_DECLARED_BY_TTL_LOOP'"
 * instead of a scarier, unexplained-looking 'x_iv_ttl'. Does not change
 * what's enforced (existence of this exact derived name) -- see
 * TTL-CPP-STRUCTURED-ACCESS-DESIGN.md §16.4(ii), §18 for why this,
 * not the C++ enum-typed check below, is what actually does the
 * enforcement; the enum only adds a secondary, narrower check. */
#define _TTL_IV(v) v##_MUST_BE_DECLARED_BY_TTL_LOOP

#define TTL_1D(name, i, si, oi) \
    _TTL_NAME(name)[_ttl_check_constant_scale(si) * _TTL_IV(i) + _ttl_check_constant_offset(oi)]
#define TTL_2D(name, i, si, oi, j, sj, oj) \
    _TTL_NAME(name)[_ttl_check_constant_scale(si) * _TTL_IV(i) + _ttl_check_constant_offset(oi)][_ttl_check_constant_scale(sj) * _TTL_IV(j) + _ttl_check_constant_offset(oj)]
#define TTL_3D(name, i, si, oi, j, sj, oj, k, sk, ok) \
    _TTL_NAME(name)[_ttl_check_constant_scale(si) * _TTL_IV(i) + _ttl_check_constant_offset(oi)][_ttl_check_constant_scale(sj) * _TTL_IV(j) + _ttl_check_constant_offset(oj)][_ttl_check_constant_scale(sk) * _TTL_IV(k) + _ttl_check_constant_offset(ok)]

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
 *               TTL_DOUBLE_BUFFER, { body })
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
 * induction variable types, full stop. The loop's OWN declared variable
 * must stay a literal int -- this holds regardless of what's tried below.
 *
 * IMPORTANT CORRECTION (re-verified twice, do not re-attempt without new
 * evidence): a later attempt used explicit static_cast round-trips
 * instead of operator overloads for the header's comparison/increment,
 * on the theory that operator-overload CALLS (not the type itself) were
 * the crash trigger. That version does NOT crash and DOES still lower to
 * a clean affine.for -- but it STILL silently defeats ttl.tile/pipeline
 * attachment, confirmed against the real GEMM kernel (TTL_LOOP_3D +
 * TTL_DOUBLE_BUFFER): cgeist stage-1 output has zero ttl.* attributes
 * beyond ttl.kernel/argname/restrict, and the full pipeline through
 * ttl-translate produces flat untiled index arithmetic with no __local
 * buffers and no DMA/double-buffering calls at all -- while still being
 * numerically correct (untiled code is still correct code), which makes
 * this failure mode dangerous: a 15/15 bit-exact matrix run does NOT
 * catch it. So there are two SEPARATE cgeist limitations here, not one:
 * (a) operator-overload calls in the for-header crash (fixable by using
 * casts instead -- see _TTL_Induc below), and (b) any non-int induction
 * variable type defeats ttl.tile attachment regardless of crash-safety
 * (NOT fixable from TTL.h; this is what actually keeps the loop's own
 * declared variable pinned to plain int). Do not conflate the two.
 * =============================================================================== */

enum class _TTL_Induc : int {};

template <int Scale, int Offset>
__attribute__((always_inline))
constexpr int _ttl_affine_idx(_TTL_Induc iv) {
    return Scale * static_cast<int>(iv) + Offset;
}

/* BODY-ALIAS DESIGN (supersedes the tag-cast approach above for C++ mode):
 * the physical loop counter cgeist sees in the for-header stays a plain
 * int, under an internal name (_TTL_RAW) -- this is what keeps
 * ttl.tile/ttl.pipeline attachment working, per the IMPORTANT CORRECTION
 * above. TTL_LOOP now injects a body-local alias, declared as the FIRST
 * statement of the loop body with the user's own name (i/j/k) and typed
 * as _TTL_Induc DIRECTLY -- no cast at the access site. Verified against
 * real cgeist + the full ttl-opt/ttl-translate pipeline, both 1D and a
 * 3D/GEMM-shaped kernel: ttl.tile/ttl.pipeline attached, real __local
 * buffers and TTL_start_import/export_double_buffering calls in the
 * final .cl (identical tiling footprint to the plain-int baseline), AND
 * a wrong/unrelated int variable now fails with a real, direct type
 * error ("no known conversion from 'int' to '_TTL_Induc'") instead of
 * relying on name-mangling. This requires TTL_LOOP to own the opening of
 * the loop body (so it can inject the alias declaration before user
 * code runs), which means the body is now a macro argument:
 *   TTL_LOOP_3D(i, 0, M, 64, j, 0, N, 64, k, 0, K, 64, MODE, { ...body... })
 * instead of a bare trailing brace block. This is a real, one-time
 * syntax change across every C++-mode kernel call site.
 *
 * Validated end-to-end on 01_gemm.c (migrated to the new call syntax,
 * both TTL_LOOP_*D branches -- C and C++ share this shape now, Rule 1
 * single-code-path): plain-C leg compiles clean; C++ direct leg (real
 * clang -> SPIR-V, no cgeist) compiles clean; C++ cgeist leg attaches
 * ttl.tile/ttl.pipeline and produces real __local/DMA codegen; direct
 * and cgeist execution both bit-exact (err=0) against the NumPy
 * reference. The remaining kernels in tests/cpragma/e2e/pragma_c/ still
 * use the old trailing-brace call syntax and have NOT been migrated or
 * re-verified yet -- this is a corpus-wide follow-up, not done here.
 *
 * The body-local alias is declared `const` -- this is deliberate, not
 * incidental, and turns out to be the RIGHT call on reflection, not just
 * an accepted limitation: an induction variable produced by TTL_LOOP is
 * supposed to be immutable within the loop body (that's what makes the
 * access affine in the first place -- TTL_1D/2D/3D's whole contract is
 * `scale*i+offset` where `i` is exactly the loop's own value, not
 * something the body reassigned mid-iteration). Making it `const`
 * enforces that structurally, which is exactly what a "structured
 * access" mode should do. Verified directly what actually happens on
 * misuse, three cases:
 *   - `i = j;` (reassignment, no arithmetic, both sides already
 *     _TTL_Induc): clean single diagnostic, no crash --
 *     "cannot assign to variable 'i' with const-qualified type", with a
 *     note pointing at the TTL_LOOP declaration. This is the case that
 *     actually demonstrates the const check on its own.
 *   - `i = i + 1;` / `j = i + 1;` (any arithmetic on the alias):
 *     `_TTL_Induc` (enum class) has no operator+, so Clang's Sema
 *     rejects the RHS ("invalid operands to binary expression") BEFORE
 *     it ever gets to checking whether the LHS is assignable -- the
 *     const error never surfaces in this case, the missing-operator
 *     error does, first. Both of these then crash cgeist afterward
 *     (RecoveryExpr not handled cleanly by MLIRScanner -- the same
 *     pre-existing, separate cgeist diagnostic-recovery gap documented
 *     elsewhere in this file, not something new). Whichever diagnostic
 *     fires, the non-affine attempt is caught -- it just isn't always a
 *     clean single error, depending on which Sema rule trips first. */

#define _TTL_RAW(v) v##_TTL_RAW_COUNTER

#undef TTL_1D
#undef TTL_2D
#undef TTL_3D
#undef TTL_1D_2IV
#undef TTL_2D_2IV
#undef TTL_3D_2IV

#define TTL_1D(name, i, si, oi) \
    _TTL_NAME(name)[_ttl_affine_idx<si, oi>(i)]
#define TTL_2D(name, i, si, oi, j, sj, oj) \
    _TTL_NAME(name)[_ttl_affine_idx<si, oi>(i)][_ttl_affine_idx<sj, oj>(j)]
#define TTL_3D(name, i, si, oi, j, sj, oj, k, sk, ok) \
    _TTL_NAME(name)[_ttl_affine_idx<si, oi>(i)][_ttl_affine_idx<sj, oj>(j)][_ttl_affine_idx<sk, ok>(k)]

/* _TTL_Induc (enum class) has no operator+, so the 2IV combiner form
 * casts back to int explicitly -- an ordinary expression context, not a
 * for-header, so this doesn't affect tile/pipeline attachment. */
#define TTL_1D_2IV(name, a, b) \
    _TTL_NAME(name)[static_cast<int>(a) + static_cast<int>(b)]
#define TTL_2D_2IV(name, a1, b1, a2, b2) \
    _TTL_NAME(name)[static_cast<int>(a1) + static_cast<int>(b1)][static_cast<int>(a2) + static_cast<int>(b2)]
#define TTL_3D_2IV(name, a1, b1, a2, b2, a3, b3) \
    _TTL_NAME(name)[static_cast<int>(a1) + static_cast<int>(b1)][static_cast<int>(a2) + static_cast<int>(b2)][static_cast<int>(a3) + static_cast<int>(b3)]

#define TTL_LOOP_1D(i, i0, i1, t1, mode, ...) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1)) \
    for (int _TTL_RAW(i) = (i0); _TTL_RAW(i) < (i1); _TTL_RAW(i)++) { \
        const _TTL_Induc i = static_cast<_TTL_Induc>(_TTL_RAW(i)); \
        __VA_ARGS__ \
    }

#define TTL_LOOP_2D(i, i0, i1, t1, j, j0, j1, t2, mode, ...) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2)) \
    for (int _TTL_RAW(i) = (i0); _TTL_RAW(i) < (i1); _TTL_RAW(i)++) \
    for (int _TTL_RAW(j) = (j0); _TTL_RAW(j) < (j1); _TTL_RAW(j)++) { \
        const _TTL_Induc i = static_cast<_TTL_Induc>(_TTL_RAW(i)); \
        const _TTL_Induc j = static_cast<_TTL_Induc>(_TTL_RAW(j)); \
        __VA_ARGS__ \
    }

#define TTL_LOOP_3D(i, i0, i1, t1, j, j0, j1, t2, k, k0, k1, t3, mode, ...) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2, t3)) \
    for (int _TTL_RAW(i) = (i0); _TTL_RAW(i) < (i1); _TTL_RAW(i)++) \
    for (int _TTL_RAW(j) = (j0); _TTL_RAW(j) < (j1); _TTL_RAW(j)++) \
    for (int _TTL_RAW(k) = (k0); _TTL_RAW(k) < (k1); _TTL_RAW(k)++) { \
        const _TTL_Induc i = static_cast<_TTL_Induc>(_TTL_RAW(i)); \
        const _TTL_Induc j = static_cast<_TTL_Induc>(_TTL_RAW(j)); \
        const _TTL_Induc k = static_cast<_TTL_Induc>(_TTL_RAW(k)); \
        __VA_ARGS__ \
    }

#else /* !__cplusplus : plain OpenCL C */

/* Body-as-macro-argument, matching the C++ branch's call syntax exactly
 * (Rule 1: single code path, same source/same syntax on both legs --
 * TTL_LOOP_3D(..., mode, { body }) works identically for C and C++ now).
 * Enforcement itself is unchanged from before: still the name-mangled
 * _TTL_IV(i) rename, still plain int -- this is purely a call-shape
 * change so shared kernel sources compile under both language modes. */
#define TTL_LOOP_1D(i, i0, i1, t1, mode, ...) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1)) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); _TTL_IV(i)++) \
        { __VA_ARGS__ }

#define TTL_LOOP_2D(i, i0, i1, t1, j, j0, j1, t2, mode, ...) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2)) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); _TTL_IV(i)++) \
        for (int _TTL_IV(j) = (j0); _TTL_IV(j) < (j1); _TTL_IV(j)++) \
            { __VA_ARGS__ }

#define TTL_LOOP_3D(i, i0, i1, t1, j, j0, j1, t2, k, k0, k1, t3, mode, ...) \
    _TTL_SCHED_PRAGMA(_TTL_MODE(mode)(t1, t2, t3)) \
    for (int _TTL_IV(i) = (i0); _TTL_IV(i) < (i1); _TTL_IV(i)++) \
        for (int _TTL_IV(j) = (j0); _TTL_IV(j) < (j1); _TTL_IV(j)++) \
            for (int _TTL_IV(k) = (k0); _TTL_IV(k) < (k1); _TTL_IV(k)++) \
                { __VA_ARGS__ }

#endif /* __cplusplus */

