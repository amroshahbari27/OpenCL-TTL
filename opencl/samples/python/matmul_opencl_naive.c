#include "TTL/TTL.h"

/* Allow Polygeist/Clang to parse OpenCL address space qualifiers during ingress.
 * For real OpenCL C compilation, these are built-in keywords and this header
 * is not used (it is only for host-side ingestion). */
#ifndef __OPENCL_C_VERSION__
#define __kernel
#define __global
#endif

/* Naive matmul (baseline):
 * - A: [M x K] row-major, lda = K
 * - B: [K x N] row-major, ldb = N
 * - C: [M x N] row-major, ldc = N
 *
 * This is intentionally NOT tiled manually.
 * The tiling intent is communicated only through `#pragma TTLtile`.
 */
__kernel void matmul_naive(__global int *restrict base_A, int lda,
                           __global int *restrict base_B, int ldb,
                           __global int *restrict base_C, int ldc,
                           int M, int N, int K) {
#pragma TTLtile(8, 8)
  for (int i = 0; i < M; ++i) {
    for (int j = 0; j < N; ++j) {
      int acc = 0;
      for (int k = 0; k < K; ++k) {
        acc += base_A[i * lda + k] * base_B[k * ldb + j];
      }
      base_C[i * ldc + j] = acc;
    }
  }
#pragma endTTLtile
}

