// dsl_matmul_op_example.c
//
// Example of the higher-level operator DSL usage. The compiler is expected to:
// - recognize `ttl_op_matmul_i32` as a single matmul op,
// - optionally fuse surrounding ops,
// - apply tiling based on the config,
// - lower to a TTL kernel (e.g. blocking non-pipelined) in the OpenCL backend.
//
// This file is designed to be parseable by Polygeist (C ingress) and also
// readable as OpenCL-ish C.

#include "ttl_operator_dsl.h"

// Problem sizes are parameters (no hardcoding in the op itself).
__kernel void dsl_matmul_i32_kernel(__global const int *restrict A, int lda,
                                    __global const int *restrict B, int ldb,
                                    __global int *restrict C, int ldc, int M,
                                    int N, int K) {
  TTL_OP_MATMUL_I32(A, lda, B, ldb, C, ldc, M, N, K);
}

