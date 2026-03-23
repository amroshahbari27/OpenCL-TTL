/*
 * TTL_matmul_compare.cl
 *
 * Two OpenCL C kernels:
 * - TTL_matmul_non_pipelined: blocking imports/exports (import+wait each K tile)
 * - TTL_matmul_pipelined: double-buffered imports for A and B + export double buffering for C tiles
 *
 * Notes:
 * - Intended for single work-item execution (global size = 1).
 * - Uses TTL C API (TTL_target=opencl).
 */

#include "TTL/TTL.h"

#ifndef TEST_TENSOR_TYPE
#define TEST_TENSOR_TYPE int
#endif

/* Tile sizes (can be overridden by -D). */
#ifndef TILE_M
#define TILE_M 16
#endif
#ifndef TILE_N
#define TILE_N 16
#endif
#ifndef TILE_K
#define TILE_K 16
#endif

/* -----------------------------------------------------------------------------
 * Baseline: NOT tiled, NOT pipelined (naive GEMM).
 * Single work-item, reads A/B from global and writes C to global.
 * ---------------------------------------------------------------------------*/
__kernel void matmul_naive(__global const TEST_TENSOR_TYPE *restrict base_A, int lda,
                           __global const TEST_TENSOR_TYPE *restrict base_B, int ldb,
                           __global TEST_TENSOR_TYPE *restrict base_C, int ldc,
                           int M, int N, int K) {
    for (int i = 0; i < M; ++i) {
        for (int j = 0; j < N; ++j) {
            long acc = 0;
            for (int k = 0; k < K; ++k) {
                const TEST_TENSOR_TYPE a = base_A[i * lda + k];
                const TEST_TENSOR_TYPE b = base_B[k * ldb + j];
                acc += (long)a * (long)b;
            }
            base_C[i * ldc + j] = (TEST_TENSOR_TYPE)acc;
        }
    }
}

/* Typed tensor names (TTL C API uses macro-generated typedefs). */
#undef TTL_EXT_TENSOR_TYPE
#define TTL_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, , ext_, TEST_TENSOR_TYPE, , _t)
#undef TTL_CONST_EXT_TENSOR_TYPE
#define TTL_CONST_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, const_, ext_, TEST_TENSOR_TYPE, , _t)
#undef TTL_INT_TENSOR_TYPE
#define TTL_INT_TENSOR_TYPE __TTL_tensor_name(TTL_, , int_, TEST_TENSOR_TYPE, , _t)
#undef TTL_INT_SUB_TENSOR_TYPE
#define TTL_INT_SUB_TENSOR_TYPE __TTL_tensor_name(TTL_, , int_, TEST_TENSOR_TYPE, sub_, _t)

#undef TTL_IMPORT_DOUBLE_BUFFERING_TYPE
#define TTL_IMPORT_DOUBLE_BUFFERING_TYPE \
    __TTL_tensor_name(TTL_import_double_, const_, , TEST_TENSOR_TYPE, , _buffering_t)
#undef TTL_EXPORT_DOUBLE_BUFFERING_TYPE
#define TTL_EXPORT_DOUBLE_BUFFERING_TYPE \
    __TTL_tensor_name(TTL_export_double_, const_, , TEST_TENSOR_TYPE, , _buffering_t)

/* Local buffers:
 * - A: 2x (double buffering) for pipelined kernel
 * - B: 2x
 * - C: 2x (export double buffering)
 *
 * For non-pipelined kernel, only the first buffers are used.
 */
__kernel void TTL_matmul_non_pipelined(__global TEST_TENSOR_TYPE *restrict base_A, int lda,
                                       __global TEST_TENSOR_TYPE *restrict base_B, int ldb,
                                       __global TEST_TENSOR_TYPE *restrict base_C, int ldc,
                                       int M, int N, int K) {
    __local TEST_TENSOR_TYPE local_A[TILE_M * TILE_K];
    __local TEST_TENSOR_TYPE local_B[TILE_K * TILE_N];
    __local TEST_TENSOR_TYPE local_C[TILE_M * TILE_N];

    const TTL_shape_t shape_A = TTL_create_shape((TTL_dim_t)K, (TTL_dim_t)M); /* width=K, height=M */
    const TTL_shape_t shape_B = TTL_create_shape((TTL_dim_t)N, (TTL_dim_t)K); /* width=N, height=K */
    const TTL_shape_t shape_C = TTL_create_shape((TTL_dim_t)N, (TTL_dim_t)M); /* width=N, height=M */

    const TTL_layout_t layout_A = TTL_create_layout((TTL_dim_t)lda);
    const TTL_layout_t layout_B = TTL_create_layout((TTL_dim_t)ldb);
    const TTL_layout_t layout_C = TTL_create_layout((TTL_dim_t)ldc);

    /* Inputs are const ext tensors; output is ext tensor. */
    const TTL_CONST_EXT_TENSOR_TYPE ext_A = TTL_create_const_ext_tensor(base_A, shape_A, layout_A);
    const TTL_CONST_EXT_TENSOR_TYPE ext_B = TTL_create_const_ext_tensor(base_B, shape_B, layout_B);
    const TTL_EXT_TENSOR_TYPE ext_C = TTL_create_ext_tensor(base_C, shape_C, layout_C);

    const TTL_tiler_t tiler_A = TTL_create_tiler(shape_A, TTL_create_shape(TILE_K, TILE_M));
    const TTL_tiler_t tiler_B = TTL_create_tiler(shape_B, TTL_create_shape(TILE_N, TILE_K));
    const TTL_tiler_t tiler_C = TTL_create_tiler(shape_C, TTL_create_shape(TILE_N, TILE_M));

    const int tiles_n = TTL_tiles_in_width(tiler_C);
    const int tiles_m = TTL_tiles_in_height(tiler_C);
    const int tiles_k = TTL_tiles_in_width(tiler_A);
    const int tiles_n_B = TTL_tiles_in_width(tiler_B);
    const int tiles_k_B = TTL_tiles_in_height(tiler_B);

    const TTL_layout_t a_loc_layout = TTL_create_layout(TILE_K);
    const TTL_layout_t b_loc_layout = TTL_create_layout(TILE_N);
    const TTL_layout_t c_loc_layout = TTL_create_layout(TILE_N);

    for (int tm = 0; tm < tiles_m; ++tm) {
        for (int tn = 0; tn < tiles_n; ++tn) {
            /* C tile */
            TTL_tile_t tile_C = TTL_create_tile((TTL_dim_t)tn, (TTL_dim_t)tm, 0, tiler_C);
            const int Mt_eff = (int)tile_C.shape.height;
            const int Nt_eff = (int)tile_C.shape.width;

            TTL_INT_TENSOR_TYPE int_C = TTL_create_int_tensor(local_C, tile_C.shape, c_loc_layout);

            /* Zero C */
            for (int y = 0; y < Mt_eff; ++y)
                for (int x = 0; x < Nt_eff; ++x)
                    TTL_write_tensor(int_C, (TEST_TENSOR_TYPE)0, (unsigned)x, (unsigned)y);

            for (int tk = 0; tk < tiles_k; ++tk) {
                /* A tile: (k, m) */
                const int tile_id_A = tk + tm * TTL_tiles_in_width(tiler_A);
                TTL_tile_t tile_A = TTL_get_tile(tile_id_A, tiler_A);

                /* B tile: (n, k) */
                const int tile_id_B = tn + tk * tiles_n_B;
                TTL_tile_t tile_B = TTL_get_tile(tile_id_B, tiler_B);

                if (TTL_tile_empty(tile_A) || TTL_tile_empty(tile_B)) continue;

                const int Kt_eff = (int)tile_A.shape.width;
                /* Consistency: tile_B.shape.height should match Kt_eff; clamp to min */
                const int K_eff = (tile_B.shape.height < (TTL_dim_t)Kt_eff) ? (int)tile_B.shape.height : Kt_eff;

                /* Create tensor views for the tile regions using offset overloads. */
                TTL_CONST_EXT_TENSOR_TYPE ext_tile_A =
                    TTL_create_const_ext_tensor(base_A, tile_A.shape, layout_A, tile_A.offset, sizeof(TEST_TENSOR_TYPE));
                TTL_CONST_EXT_TENSOR_TYPE ext_tile_B =
                    TTL_create_const_ext_tensor(base_B, tile_B.shape, layout_B, tile_B.offset, sizeof(TEST_TENSOR_TYPE));

                TTL_INT_TENSOR_TYPE int_A = TTL_create_int_tensor(local_A, tile_A.shape, a_loc_layout);
                TTL_INT_TENSOR_TYPE int_B = TTL_create_int_tensor(local_B, tile_B.shape, b_loc_layout);

                TTL_event_t eA = TTL_get_event();
                TTL_event_t eB = TTL_get_event();
                TTL_import(int_A, ext_tile_A, &eA);
                TTL_import(int_B, ext_tile_B, &eB);
                TTL_wait(1, &eA);
                TTL_wait(1, &eB);

                /* C += A * B for this K block */
                for (int y = 0; y < Mt_eff; ++y) {
                    for (int x = 0; x < Nt_eff; ++x) {
                        TEST_TENSOR_TYPE acc = TTL_read_tensor(int_C, (unsigned)x, (unsigned)y);
                        for (int kk = 0; kk < K_eff; ++kk) {
                            const TEST_TENSOR_TYPE a = TTL_read_tensor(int_A, (unsigned)kk, (unsigned)y);
                            const TEST_TENSOR_TYPE b = TTL_read_tensor(int_B, (unsigned)x, (unsigned)kk);
                            acc = (TEST_TENSOR_TYPE)(acc + a * b);
                        }
                        TTL_write_tensor(int_C, acc, (unsigned)x, (unsigned)y);
                    }
                }
            }

            /* Export C tile */
            TTL_EXT_TENSOR_TYPE ext_tile_C =
                TTL_create_ext_tensor(base_C, tile_C.shape, layout_C, tile_C.offset, sizeof(TEST_TENSOR_TYPE));
            TTL_event_t eC = TTL_get_event();
            TTL_export(int_C, ext_tile_C, &eC);
            TTL_wait(1, &eC);
        }
    }
}

__kernel void TTL_matmul_pipelined(__global TEST_TENSOR_TYPE *restrict base_A, int lda,
                                   __global TEST_TENSOR_TYPE *restrict base_B, int ldb,
                                   __global TEST_TENSOR_TYPE *restrict base_C, int ldc,
                                   int M, int N, int K) {
    __local TEST_TENSOR_TYPE local_A0[TILE_M * TILE_K];
    __local TEST_TENSOR_TYPE local_A1[TILE_M * TILE_K];
    __local TEST_TENSOR_TYPE local_B0[TILE_K * TILE_N];
    __local TEST_TENSOR_TYPE local_B1[TILE_K * TILE_N];
    __local TEST_TENSOR_TYPE local_C0[TILE_M * TILE_N];
    __local TEST_TENSOR_TYPE local_C1[TILE_M * TILE_N];

    const TTL_shape_t shape_A = TTL_create_shape((TTL_dim_t)K, (TTL_dim_t)M);
    const TTL_shape_t shape_B = TTL_create_shape((TTL_dim_t)N, (TTL_dim_t)K);
    const TTL_shape_t shape_C = TTL_create_shape((TTL_dim_t)N, (TTL_dim_t)M);

    const TTL_layout_t layout_A = TTL_create_layout((TTL_dim_t)lda);
    const TTL_layout_t layout_B = TTL_create_layout((TTL_dim_t)ldb);
    const TTL_layout_t layout_C = TTL_create_layout((TTL_dim_t)ldc);

    const TTL_CONST_EXT_TENSOR_TYPE ext_A = TTL_create_const_ext_tensor(base_A, shape_A, layout_A);
    const TTL_CONST_EXT_TENSOR_TYPE ext_B = TTL_create_const_ext_tensor(base_B, shape_B, layout_B);
    const TTL_EXT_TENSOR_TYPE ext_C = TTL_create_ext_tensor(base_C, shape_C, layout_C);

    const TTL_tiler_t tiler_A = TTL_create_tiler(shape_A, TTL_create_shape(TILE_K, TILE_M));
    const TTL_tiler_t tiler_B = TTL_create_tiler(shape_B, TTL_create_shape(TILE_N, TILE_K));
    const TTL_tiler_t tiler_C = TTL_create_tiler(shape_C, TTL_create_shape(TILE_N, TILE_M));

    const int tiles_n = TTL_tiles_in_width(tiler_C);
    const int tiles_m = TTL_tiles_in_height(tiler_C);
    const int tiles_k = TTL_tiles_in_width(tiler_A);
    const int tiles_n_B = TTL_tiles_in_width(tiler_B);

    /* Export double buffering across output tiles */
    TTL_event_t eC = TTL_get_event();
    TTL_EXPORT_DOUBLE_BUFFERING_TYPE export_db =
        TTL_start_export_double_buffering(local_C0, local_C1, ext_C, &eC);

    for (int tm = 0; tm < tiles_m; ++tm) {
        for (int tn = 0; tn < tiles_n; ++tn) {
            TTL_tile_t tile_C = TTL_create_tile((TTL_dim_t)tn, (TTL_dim_t)tm, 0, tiler_C);
            const int Mt_eff = (int)tile_C.shape.height;
            const int Nt_eff = (int)tile_C.shape.width;

            /* Get internal buffer for current tile; exports previous tile in background */
            TTL_INT_SUB_TENSOR_TYPE out_tile = TTL_step_buffering(&export_db, tile_C);

            /* Zero local C */
            for (int y = 0; y < Mt_eff; ++y)
                for (int x = 0; x < Nt_eff; ++x)
                    TTL_write_tensor(out_tile, (TEST_TENSOR_TYPE)0, (unsigned)x, (unsigned)y);

            /* Start import buffering for A and B for this output tile */
            TTL_event_t eA = TTL_get_event();
            TTL_event_t eB = TTL_get_event();

            const int tile_id_A0 = 0 + tm * TTL_tiles_in_width(tiler_A);
            const int tile_id_B0 = tn + 0 * tiles_n_B;

            TTL_IMPORT_DOUBLE_BUFFERING_TYPE import_A =
                TTL_start_import_double_buffering(local_A0, local_A1, ext_A, &eA, TTL_get_tile(tile_id_A0, tiler_A));
            TTL_IMPORT_DOUBLE_BUFFERING_TYPE import_B =
                TTL_start_import_double_buffering(local_B0, local_B1, ext_B, &eB, TTL_get_tile(tile_id_B0, tiler_B));

            for (int tk = 0; tk < tiles_k; ++tk) {
                /* Next tiles (or empty at end) */
                TTL_tile_t next_A = TTL_create_empty_tile();
                if (tk + 1 < tiles_k) {
                    const int tile_id_A_next = (tk + 1) + tm * TTL_tiles_in_width(tiler_A);
                    next_A = TTL_get_tile(tile_id_A_next, tiler_A);
                }

                const int tile_id_B_next = tn + (tk + 1) * tiles_n_B;
                TTL_tile_t next_B = TTL_get_tile(tile_id_B_next, tiler_B); /* invalid if out-of-range */

                TTL_INT_SUB_TENSOR_TYPE a_blk = TTL_step_buffering(&import_A, next_A);
                TTL_INT_SUB_TENSOR_TYPE b_blk = TTL_step_buffering(&import_B, next_B);

                if (TTL_shape_empty(a_blk.tensor.shape) || TTL_shape_empty(b_blk.tensor.shape)) continue;

                const int Kt_eff = (int)a_blk.tensor.shape.width;
                const int K_eff = (b_blk.tensor.shape.height < (TTL_dim_t)Kt_eff) ? (int)b_blk.tensor.shape.height : Kt_eff;

                for (int y = 0; y < Mt_eff; ++y) {
                    for (int x = 0; x < Nt_eff; ++x) {
                        TEST_TENSOR_TYPE acc = TTL_read_tensor(out_tile, (unsigned)x, (unsigned)y);
                        for (int kk = 0; kk < K_eff; ++kk) {
                            const TEST_TENSOR_TYPE a = TTL_read_tensor(a_blk, (unsigned)kk, (unsigned)y);
                            const TEST_TENSOR_TYPE b = TTL_read_tensor(b_blk, (unsigned)x, (unsigned)kk);
                            acc = (TEST_TENSOR_TYPE)(acc + a * b);
                        }
                        TTL_write_tensor(out_tile, acc, (unsigned)x, (unsigned)y);
                    }
                }
            }

            TTL_finish_buffering(&import_A);
            TTL_finish_buffering(&import_B);
        }
    }

    TTL_finish_buffering(&export_db);
}

