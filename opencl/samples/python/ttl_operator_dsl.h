// ttl_operator_dsl.h
//
// "Torch-like" operator DSL for C/OpenCL-ish kernels, designed to:
// - Keep source concise (write `TTL_OP_MATMUL_I32(...)` instead of nested loops).
// - Preserve *structured intent* via pragmas/config macros so MLIR can optimize
//   (tiling, fusion decisions, kernel selection) before lowering to TTL kernels.
//
// Important constraint:
// - Pragmas require compile-time constants. So tiling "hints" are compile-time
//   macros (set via build flags), not runtime parameters.
//
#pragma once

#include "TTL/TTL.h"

#ifndef __OPENCL_C_VERSION__
#ifndef __kernel
#define __kernel
#endif
#ifndef __global
#define __global
#endif
#endif

#ifndef restrict
#define restrict
#endif

// Compile-time hint knobs (set these via `-D...` when compiling/ingressing).
// No defaults: the caller must provide them (keeps the DSL non-hardcoded).
#ifndef TTL_TILE_M
#error "TTL_TILE_M must be provided via -DTTL_TILE_M=<int>"
#endif
#ifndef TTL_TILE_N
#error "TTL_TILE_N must be provided via -DTTL_TILE_N=<int>"
#endif

// Optional knobs the compiler/backend may use (kept as macros so they don't
// create extra functions in Polygeist output).
#ifndef TTL_TILE_K
#define TTL_TILE_K 0
#endif
#ifndef TTL_FUSE_POLICY
#define TTL_FUSE_POLICY 0
#endif
#ifndef TTL_KERNEL_CHOICE
#define TTL_KERNEL_CHOICE 0
#endif

#define TTL_DSL_PRAGMA(x) _Pragma(#x)
#define TTL_DSL_TILE(Mt, Nt) TTL_DSL_PRAGMA(TTLtile(Mt, Nt))
#define TTL_DSL_END_TILE() TTL_DSL_PRAGMA(endTTLtile)

// The "operator": expands to a region marked with `#pragma TTLtile`, plus a
// correct reference loop nest. A TTL backend is expected to replace this region
// with a handcrafted TTL kernel based on the compile-time knobs above.
#define TTL_OP_MATMUL_I32(A, LDA, B, LDB, C, LDC, M, N, K)                     \
  do {                                                                        \
    TTL_DSL_TILE(TTL_TILE_M, TTL_TILE_N);                                     \
    for (int i = 0; i < (M); ++i) {                                           \
      for (int j = 0; j < (N); ++j) {                                         \
        int acc = 0;                                                         \
        for (int k = 0; k < (K); ++k) {                                       \
          acc += (A)[i * (LDA) + k] * (B)[k * (LDB) + j];                     \
        }                                                                     \
        (C)[i * (LDC) + j] = acc;                                             \
      }                                                                       \
    }                                                                         \
    TTL_DSL_END_TILE();                                                       \
  } while (0)

