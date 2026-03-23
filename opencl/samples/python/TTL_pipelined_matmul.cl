/*
 * TTL_pipelined_matmul.cl
 *
 * Three matmul kernels demonstrating the full TTL tiling + buffering API:
 *
 *   1) matmul_naive        - Direct global-memory access, no tiling at all.
 *   2) matmul_tiled_blocking - Tiled with TTL tensors but blocking imports
 *                              (no overlap of DMA and compute).
 *   3) matmul_tiled_pipelined - Fully pipelined: double-buffered import for
 *                               A and B tiles, double-buffered export for C,
 *                               so DMA and compute overlap across K-iterations
 *                               and across output tiles.
 *
 * All three compute C = A * B for int32 matrices.
 * A is M x K (row-major, stride = lda), B is K x N, C is M x N.
 *
 * Compile with:
 *   -DTTL_COPY_3D -DTILE_M=<m> -DTILE_N=<n> -DTILE_K=<k>
 */

#include "TTL/TTL.h"

#ifndef TEST_TENSOR_TYPE
#define TEST_TENSOR_TYPE int
#endif

#ifndef TILE_M
#define TILE_M 32
#endif
#ifndef TILE_N
#define TILE_N 32
#endif
#ifndef TILE_K
#define TILE_K 32
#endif

/* =========================================================================
 * Typed tensor name macros (TTL C API generates per-type typedefs)
 * ========================================================================= */
#undef TTL_EXT_TENSOR_TYPE
#define TTL_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, , ext_, TEST_TENSOR_TYPE, , _t)
#undef TTL_CONST_EXT_TENSOR_TYPE
#define TTL_CONST_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, const_, ext_, TEST_TENSOR_TYPE, , _t)
#undef TTL_INT_TENSOR_TYPE
#define TTL_INT_TENSOR_TYPE __TTL_tensor_name(TTL_, , int_, TEST_TENSOR_TYPE, , _t)
#undef TTL_CONST_INT_TENSOR_TYPE
#define TTL_CONST_INT_TENSOR_TYPE __TTL_tensor_name(TTL_, const_, int_, TEST_TENSOR_TYPE, , _t)
#undef TTL_INT_SUB_TENSOR_TYPE
#define TTL_INT_SUB_TENSOR_TYPE __TTL_tensor_name(TTL_, , int_, TEST_TENSOR_TYPE, sub_, _t)
#undef TTL_IMPORT_DOUBLE_BUFFERING_TYPE
#define TTL_IMPORT_DOUBLE_BUFFERING_TYPE \
    __TTL_tensor_name(TTL_import_double_, const_, , TEST_TENSOR_TYPE, , _buffering_t)
#undef TTL_EXPORT_DOUBLE_BUFFERING_TYPE
#define TTL_EXPORT_DOUBLE_BUFFERING_TYPE \
    __TTL_tensor_name(TTL_export_double_, const_, , TEST_TENSOR_TYPE, , _buffering_t)

/* =========================================================================
 * 1) NAIVE: global memory, no tiling, no TTL
 * ========================================================================= */
__kernel void matmul_naive(__global const TEST_TENSOR_TYPE *restrict A, int lda,
                           __global const TEST_TENSOR_TYPE *restrict B, int ldb,
                           __global TEST_TENSOR_TYPE *restrict C, int ldc,
                           int M, int N, int K) {
    for (int i = 0; i < M; ++i) {
        for (int j = 0; j < N; ++j) {
            long acc = 0;
            for (int k = 0; k < K; ++k)
                acc += (long)A[i * lda + k] * (long)B[k * ldb + j];
            C[i * ldc + j] = (TEST_TENSOR_TYPE)acc;
        }
    }
}

/* =========================================================================
 * 2) TILED + BLOCKING: uses TTL shapes/tensors/tiler/import/export but
 *    every DMA is immediately waited on (no overlap).
 * ========================================================================= */
__kernel void matmul_tiled_blocking(__global TEST_TENSOR_TYPE *restrict base_A, int lda,
                                    __global TEST_TENSOR_TYPE *restrict base_B, int ldb,
                                    __global TEST_TENSOR_TYPE *restrict base_C, int ldc,
                                    int M, int N, int K) {
    /* Local buffers - single set (no double buffering) */
    __local TEST_TENSOR_TYPE loc_A[TILE_M * TILE_K];
    __local TEST_TENSOR_TYPE loc_B[TILE_K * TILE_N];
    __local TEST_TENSOR_TYPE loc_C[TILE_M * TILE_N];

    /* Describe external tensors */
    const TTL_shape_t shape_A = TTL_create_shape((TTL_dim_t)K, (TTL_dim_t)M);
    const TTL_shape_t shape_B = TTL_create_shape((TTL_dim_t)N, (TTL_dim_t)K);
    const TTL_shape_t shape_C = TTL_create_shape((TTL_dim_t)N, (TTL_dim_t)M);

    const TTL_layout_t layout_A = TTL_create_layout((TTL_dim_t)lda);
    const TTL_layout_t layout_B = TTL_create_layout((TTL_dim_t)ldb);
    const TTL_layout_t layout_C = TTL_create_layout((TTL_dim_t)ldc);

    const TTL_CONST_EXT_TENSOR_TYPE ext_A = TTL_create_const_ext_tensor(base_A, shape_A, layout_A);
    const TTL_CONST_EXT_TENSOR_TYPE ext_B = TTL_create_const_ext_tensor(base_B, shape_B, layout_B);
    const TTL_EXT_TENSOR_TYPE ext_C       = TTL_create_ext_tensor(base_C, shape_C, layout_C);

    /* Create tilers */
    const TTL_tiler_t tiler_A = TTL_create_tiler(shape_A, TTL_create_shape(TILE_K, TILE_M));
    const TTL_tiler_t tiler_B = TTL_create_tiler(shape_B, TTL_create_shape(TILE_N, TILE_K));
    const TTL_tiler_t tiler_C = TTL_create_tiler(shape_C, TTL_create_shape(TILE_N, TILE_M));

    const int tiles_n = TTL_tiles_in_width(tiler_C);
    const int tiles_m = TTL_tiles_in_height(tiler_C);
    const int tiles_k = TTL_tiles_in_width(tiler_A);
    const int tiles_n_B = TTL_tiles_in_width(tiler_B);

    /* Local layouts (packed tiles) */
    const TTL_layout_t loc_layout_A = TTL_create_layout(TILE_K);
    const TTL_layout_t loc_layout_B = TTL_create_layout(TILE_N);
    const TTL_layout_t loc_layout_C = TTL_create_layout(TILE_N);

    for (int tm = 0; tm < tiles_m; ++tm) {
        for (int tn = 0; tn < tiles_n; ++tn) {
            /* Get C tile info */
            TTL_tile_t tile_C = TTL_create_tile((TTL_dim_t)tn, (TTL_dim_t)tm, 0, tiler_C);
            const int Mt = (int)tile_C.shape.height;
            const int Nt = (int)tile_C.shape.width;

            TTL_INT_TENSOR_TYPE int_C = TTL_create_int_tensor(loc_C, tile_C.shape, loc_layout_C);

            /* Zero local C */
            for (int y = 0; y < Mt; ++y)
                for (int x = 0; x < Nt; ++x)
                    TTL_write_tensor(int_C, (TEST_TENSOR_TYPE)0, (unsigned)x, (unsigned)y);

            /* Accumulate over K tiles */
            for (int tk = 0; tk < tiles_k; ++tk) {
                /* A tile at (tk, tm) */
                TTL_tile_t tile_A = TTL_get_tile(tk + tm * TTL_tiles_in_width(tiler_A), tiler_A);
                /* B tile at (tn, tk) */
                TTL_tile_t tile_B = TTL_get_tile(tn + tk * tiles_n_B, tiler_B);

                if (TTL_tile_empty(tile_A) || TTL_tile_empty(tile_B)) continue;

                const int Kt = (int)tile_A.shape.width;
                const int K_eff = ((int)tile_B.shape.height < Kt)
                                      ? (int)tile_B.shape.height : Kt;

                /* Create ext tensor views with tile offsets */
                TTL_CONST_EXT_TENSOR_TYPE ext_tile_A = TTL_create_const_ext_tensor(
                    base_A, tile_A.shape, layout_A, tile_A.offset, sizeof(TEST_TENSOR_TYPE));
                TTL_CONST_EXT_TENSOR_TYPE ext_tile_B = TTL_create_const_ext_tensor(
                    base_B, tile_B.shape, layout_B, tile_B.offset, sizeof(TEST_TENSOR_TYPE));

                TTL_INT_TENSOR_TYPE int_A = TTL_create_int_tensor(loc_A, tile_A.shape, loc_layout_A);
                TTL_INT_TENSOR_TYPE int_B = TTL_create_int_tensor(loc_B, tile_B.shape, loc_layout_B);

                /* Blocking import - wait for each transfer */
                TTL_blocking_import(int_A, ext_tile_A);
                TTL_blocking_import(int_B, ext_tile_B);

                /* Compute C += A * B */
                for (int y = 0; y < Mt; ++y) {
                    for (int x = 0; x < Nt; ++x) {
                        TEST_TENSOR_TYPE acc = TTL_read_tensor(int_C, (unsigned)x, (unsigned)y);
                        for (int kk = 0; kk < K_eff; ++kk) {
                            acc = (TEST_TENSOR_TYPE)(
                                acc + TTL_read_tensor(int_A, (unsigned)kk, (unsigned)y) *
                                      TTL_read_tensor(int_B, (unsigned)x, (unsigned)kk));
                        }
                        TTL_write_tensor(int_C, acc, (unsigned)x, (unsigned)y);
                    }
                }
            }

            /* Blocking export C tile */
            TTL_EXT_TENSOR_TYPE ext_tile_C = TTL_create_ext_tensor(
                base_C, tile_C.shape, layout_C, tile_C.offset, sizeof(TEST_TENSOR_TYPE));
            TTL_blocking_export(int_C, ext_tile_C);
        }
    }
}

/* =========================================================================
 * 3) TILED + PIPELINED: double-buffered import for A & B across K-tiles,
 *    double-buffered export for C across output tiles.
 *    DMA for the NEXT tile overlaps with compute on the CURRENT tile.
 * ========================================================================= */
__kernel void matmul_tiled_pipelined(__global TEST_TENSOR_TYPE *restrict base_A, int lda,
                                     __global TEST_TENSOR_TYPE *restrict base_B, int ldb,
                                     __global TEST_TENSOR_TYPE *restrict base_C, int ldc,
                                     int M, int N, int K) {
    /* Double buffers: 2x for A, 2x for B, 2x for C */
    __local TEST_TENSOR_TYPE loc_A0[TILE_M * TILE_K];
    __local TEST_TENSOR_TYPE loc_A1[TILE_M * TILE_K];
    __local TEST_TENSOR_TYPE loc_B0[TILE_K * TILE_N];
    __local TEST_TENSOR_TYPE loc_B1[TILE_K * TILE_N];
    __local TEST_TENSOR_TYPE loc_C0[TILE_M * TILE_N];
    __local TEST_TENSOR_TYPE loc_C1[TILE_M * TILE_N];

    /* Describe external tensors */
    const TTL_shape_t shape_A = TTL_create_shape((TTL_dim_t)K, (TTL_dim_t)M);
    const TTL_shape_t shape_B = TTL_create_shape((TTL_dim_t)N, (TTL_dim_t)K);
    const TTL_shape_t shape_C = TTL_create_shape((TTL_dim_t)N, (TTL_dim_t)M);

    const TTL_layout_t layout_A = TTL_create_layout((TTL_dim_t)lda);
    const TTL_layout_t layout_B = TTL_create_layout((TTL_dim_t)ldb);
    const TTL_layout_t layout_C = TTL_create_layout((TTL_dim_t)ldc);

    const TTL_CONST_EXT_TENSOR_TYPE ext_A = TTL_create_const_ext_tensor(base_A, shape_A, layout_A);
    const TTL_CONST_EXT_TENSOR_TYPE ext_B = TTL_create_const_ext_tensor(base_B, shape_B, layout_B);
    const TTL_EXT_TENSOR_TYPE ext_C       = TTL_create_ext_tensor(base_C, shape_C, layout_C);

    /* Tilers */
    const TTL_tiler_t tiler_A = TTL_create_tiler(shape_A, TTL_create_shape(TILE_K, TILE_M));
    const TTL_tiler_t tiler_B = TTL_create_tiler(shape_B, TTL_create_shape(TILE_N, TILE_K));
    const TTL_tiler_t tiler_C = TTL_create_tiler(shape_C, TTL_create_shape(TILE_N, TILE_M));

    const int tiles_n   = TTL_tiles_in_width(tiler_C);
    const int tiles_m   = TTL_tiles_in_height(tiler_C);
    const int tiles_k   = TTL_tiles_in_width(tiler_A);
    const int tiles_n_B = TTL_tiles_in_width(tiler_B);

    /* ---- Export double buffering: pipelines C tile writeback ---- */
    TTL_event_t eC = TTL_get_event();
    TTL_EXPORT_DOUBLE_BUFFERING_TYPE export_db =
        TTL_start_export_double_buffering(loc_C0, loc_C1, ext_C, &eC);

    for (int tm = 0; tm < tiles_m; ++tm) {
        for (int tn = 0; tn < tiles_n; ++tn) {
            TTL_tile_t tile_C = TTL_create_tile((TTL_dim_t)tn, (TTL_dim_t)tm, 0, tiler_C);
            const int Mt = (int)tile_C.shape.height;
            const int Nt = (int)tile_C.shape.width;

            /* Get local C buffer; previous C tile is being exported in background */
            TTL_INT_SUB_TENSOR_TYPE out_sub = TTL_step_buffering(&export_db, tile_C);

            /* Zero local C */
            for (int y = 0; y < Mt; ++y)
                for (int x = 0; x < Nt; ++x)
                    TTL_write_tensor(out_sub, (TEST_TENSOR_TYPE)0, (unsigned)x, (unsigned)y);

            /* ---- Import double buffering for A and B over K tiles ---- */
            TTL_event_t eA = TTL_get_event();
            TTL_event_t eB = TTL_get_event();

            /* First A and B tile IDs for this (tm, tn) output tile */
            const int first_A = 0 + tm * TTL_tiles_in_width(tiler_A);
            const int first_B = tn + 0 * tiles_n_B;

            TTL_IMPORT_DOUBLE_BUFFERING_TYPE import_A = TTL_start_import_double_buffering(
                loc_A0, loc_A1, ext_A, &eA, TTL_get_tile(first_A, tiler_A));
            TTL_IMPORT_DOUBLE_BUFFERING_TYPE import_B = TTL_start_import_double_buffering(
                loc_B0, loc_B1, ext_B, &eB, TTL_get_tile(first_B, tiler_B));

            for (int tk = 0; tk < tiles_k; ++tk) {
                /* Compute next tile (or empty sentinel if last) */
                TTL_tile_t next_A = TTL_create_empty_tile();
                if (tk + 1 < tiles_k)
                    next_A = TTL_get_tile((tk + 1) + tm * TTL_tiles_in_width(tiler_A), tiler_A);

                TTL_tile_t next_B = TTL_get_tile(tn + (tk + 1) * tiles_n_B, tiler_B);

                /* Step: wait for current tile import, start next tile prefetch */
                TTL_INT_SUB_TENSOR_TYPE a_blk = TTL_step_buffering(&import_A, next_A);
                TTL_INT_SUB_TENSOR_TYPE b_blk = TTL_step_buffering(&import_B, next_B);

                if (TTL_shape_empty(a_blk.tensor.shape) || TTL_shape_empty(b_blk.tensor.shape))
                    continue;

                const int Kt = (int)a_blk.tensor.shape.width;
                const int K_eff = ((int)b_blk.tensor.shape.height < Kt)
                                      ? (int)b_blk.tensor.shape.height : Kt;

                /* Compute: C += A * B for this K-block */
                for (int y = 0; y < Mt; ++y) {
                    for (int x = 0; x < Nt; ++x) {
                        TEST_TENSOR_TYPE acc = TTL_read_tensor(out_sub, (unsigned)x, (unsigned)y);
                        for (int kk = 0; kk < K_eff; ++kk) {
                            acc = (TEST_TENSOR_TYPE)(
                                acc + TTL_read_tensor(a_blk, (unsigned)kk, (unsigned)y) *
                                      TTL_read_tensor(b_blk, (unsigned)x, (unsigned)kk));
                        }
                        TTL_write_tensor(out_sub, acc, (unsigned)x, (unsigned)y);
                    }
                }
            }

            /* Drain A/B import pipelines for this output tile */
            TTL_finish_buffering(&import_A);
            TTL_finish_buffering(&import_B);
        }
    }

    /* Drain C export pipeline */
    TTL_finish_buffering(&export_db);
}
