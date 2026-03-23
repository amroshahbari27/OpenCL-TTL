// ttl_kernel_dsl.h
//
// A tiny C/OpenCL-friendly DSL for writing structured kernels that a compiler
// can analyze and lower into TTL-style tiled OpenCL code (local buffers +
// import/export + optional pipelining).
//
// Design goals:
// - Easy kernel signatures for OpenCL (`__kernel`, `__global`) and Polygeist ingress.
// - Explicit tile intent via `#pragma TTLtile(Mt, Nt)` (through _Pragma).
// - A small "op" surface (`ttl_dsl_matmul_i32`) that is readable and can be
//   pattern-matched during lowering.
//
// Notes:
// - This is not a performance implementation by itself; it is a *front-end DSL*.
// - Backends can choose to lower either:
//   - the `ttl_dsl_matmul_i32` call, or
//   - the explicit loop nest under `TTL_TILE(...)`.
//
#pragma once

#include "TTL/TTL.h"  // dual-use shim in this folder

// Make host-side compilation / Polygeist ingress tolerant of OpenCL keywords.
#ifndef __OPENCL_C_VERSION__
#ifndef __kernel
#define __kernel
#endif
#ifndef __global
#define __global
#endif
#ifndef __local
#define __local
#endif
#endif

#ifndef restrict
#define restrict
#endif

// For Polygeist ingress, keep the DSL "declarations-only" to avoid emitting lots
// of helper functions into the MLIR module (some flows expect a single entry
// function). The compiler backend can pattern-match calls and replace them.
#if defined(TTL_INGRESS_C)

// ---- Pragmas (portable through macros) ----
#define TTL_DSL_PRAGMA(x) _Pragma(#x)
#define TTL_DSL_TILE(Mt, Nt) TTL_DSL_PRAGMA(TTLtile(Mt, Nt))
#define TTL_DSL_END_TILE() TTL_DSL_PRAGMA(endTTLtile)

// ---- Tensor views (row-major) ----
typedef struct {
  __global const int *restrict base;
  int rows;
  int cols;
  int stride; // elements per row
} ttl_tensor2d_const_i32;

typedef struct {
  __global int *restrict base;
  int rows;
  int cols;
  int stride; // elements per row
} ttl_tensor2d_i32;

// Declarations only (no bodies in ingress mode).
ttl_tensor2d_const_i32 ttl_make_tensor2d_const_i32(
    __global const int *restrict base, int rows, int cols, int stride);
ttl_tensor2d_i32 ttl_make_tensor2d_i32(__global int *restrict base, int rows,
                                       int cols, int stride);
int ttl_read2d_const_i32(ttl_tensor2d_const_i32 t, int r, int c);
void ttl_write2d_i32(ttl_tensor2d_i32 t, int v, int r, int c);
void ttl_dsl_matmul_i32(ttl_tensor2d_const_i32 A, ttl_tensor2d_const_i32 B,
                        ttl_tensor2d_i32 C, int M, int N, int K);

#else

// ---- Pragmas (portable through macros) ----
#define TTL_DSL_PRAGMA(x) _Pragma(#x)
#define TTL_DSL_TILE(Mt, Nt) TTL_DSL_PRAGMA(TTLtile(Mt, Nt))
#define TTL_DSL_END_TILE() TTL_DSL_PRAGMA(endTTLtile)

// ---- Tensor views (row-major) ----
typedef struct {
  __global const int *restrict base;
  int rows;
  int cols;
  int stride; // elements per row
} ttl_tensor2d_const_i32;

typedef struct {
  __global int *restrict base;
  int rows;
  int cols;
  int stride; // elements per row
} ttl_tensor2d_i32;

static inline ttl_tensor2d_const_i32
ttl_make_tensor2d_const_i32(__global const int *restrict base, int rows, int cols,
                            int stride) {
  ttl_tensor2d_const_i32 t;
  t.base = base;
  t.rows = rows;
  t.cols = cols;
  t.stride = stride;
  return t;
}

static inline ttl_tensor2d_i32
ttl_make_tensor2d_i32(__global int *restrict base, int rows, int cols,
                      int stride) {
  ttl_tensor2d_i32 t;
  t.base = base;
  t.rows = rows;
  t.cols = cols;
  t.stride = stride;
  return t;
}

static inline int ttl_read2d_const_i32(ttl_tensor2d_const_i32 t, int r, int c) {
  return t.base[r * t.stride + c];
}

static inline void ttl_write2d_i32(ttl_tensor2d_i32 t, int v, int r, int c) {
  t.base[r * t.stride + c] = v;
}

// ---- DSL ops ----
//
// This "op" is intentionally a single function call so a backend can recognize
// it and replace it with a TTL non-pipelined tiled kernel, e.g. the structure in
// `TTL_matmul_compare.cl` (TTL_import/TTL_wait + local buffers + TTL_export/TTL_wait).
static inline void ttl_dsl_matmul_i32(ttl_tensor2d_const_i32 A,
                                      ttl_tensor2d_const_i32 B,
                                      ttl_tensor2d_i32 C,
                                      int M, int N, int K) {
  // Naive reference. A backend should replace this (or the surrounding tiled
  // loops) with a TTL tiled version.
  for (int i = 0; i < M; ++i) {
    for (int j = 0; j < N; ++j) {
      int acc = 0;
      for (int k = 0; k < K; ++k) {
        acc += ttl_read2d_const_i32(A, i, k) * ttl_read2d_const_i32(B, k, j);
      }
      ttl_write2d_i32(C, acc, i, j);
    }
  }
}

#endif // TTL_INGRESS_C

