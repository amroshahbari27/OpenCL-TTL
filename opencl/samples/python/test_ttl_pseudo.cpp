/*
 * test_ttl_pseudo.cpp
 *
 * One source file, two modes:
 * - Real TTL (build/link/run): include the real TTL umbrella header via <TTL/TTL.h>
 *   and compile with TTL_TARGET=c (CPU shim).
 * - Polygeist ingress (parse to MLIR): put our declarations-only shim directory
 *   first on the include path so <TTL/TTL.h> resolves to the shim.
 *
 * Real TTL compile (host / CPU):
 *   clang++ -std=c++17 -I/home/ubuntu/msc -DTTL_TARGET=c -DTEST_TENSOR_TYPE=float \
 *     -fsyntax-only /home/ubuntu/msc/TTL/opencl/samples/python/test_ttl_pseudo.cpp
 *
 * Polygeist/Clang parse (shim):
 *   clang++ -std=c++17 -I/home/ubuntu/msc/TTL/opencl/samples/python/polygeist_shim -DTEST_TENSOR_TYPE=float \
 *     -fsyntax-only /home/ubuntu/msc/TTL/opencl/samples/python/test_ttl_pseudo.cpp
 *
 * Notes:
 * - We intentionally use <...> include so the local source directory won’t
 *   “accidentally” shadow real TTL unless you pass -I for the shim.
 * - With the shim, this file is expected to PARSE (no linking).
 */

/* Default to the host-friendly TTL target unless the build overrides it. */
#ifndef TTL_TARGET
#define TTL_TARGET c
#endif

#include <TTL/TTL.h>

#ifndef TEST_TENSOR_TYPE
#define TEST_TENSOR_TYPE float
#endif

static TEST_TENSOR_TYPE input_buffer_1[1024 * 512];
static TEST_TENSOR_TYPE input_buffer_2[1024 * 512];
static TEST_TENSOR_TYPE input_b_buffer_1[1024 * 512];
static TEST_TENSOR_TYPE input_b_buffer_2[1024 * 512];
static TEST_TENSOR_TYPE output_buffer_1[1024 * 512];
static TEST_TENSOR_TYPE output_buffer_2[1024 * 512];

/* Tiled GEMM (pipelined): C[MxN] = A[MxK] * B[KxN] (row-major). */
void ttl_matmul_kernel_pipelined(TEST_TENSOR_TYPE *restrict A, int lda,
                                 TEST_TENSOR_TYPE *restrict B, int ldb,
                                 TEST_TENSOR_TYPE *restrict C, int ldc,
                                 TTL_dim M, TTL_dim N, TTL_dim K,
                                 TTL_dim Mt, TTL_dim Nt, TTL_dim Kt) {
    /* Shapes are (width=x=cols, height=y=rows). */
    const TTL_shape a_shape(K, M);
    const TTL_shape b_shape(N, K);
    const TTL_shape c_shape(N, M);

    const TTL_layout a_layout((TTL_dim)lda);
    const TTL_layout b_layout((TTL_dim)ldb);
    const TTL_layout c_layout((TTL_dim)ldc);

    const TTL_tensor<TEST_TENSOR_TYPE> ext_a(A, a_shape, a_layout);
    const TTL_tensor<TEST_TENSOR_TYPE> ext_b(B, b_shape, b_layout);
    const TTL_tensor<TEST_TENSOR_TYPE> ext_c(C, c_shape, c_layout);

    /* Tile over output C in (Nt x Mt) blocks. */
    const TTL_tiler c_tiler(c_shape, TTL_shape(Nt, Mt));

    /* Local tile buffers (2x for A and B to enable double buffering; 1x for C). */
    TEST_TENSOR_TYPE *const a_buf0 = input_buffer_1;
    TEST_TENSOR_TYPE *const a_buf1 = input_buffer_2;
    TEST_TENSOR_TYPE *const b_buf0 = input_b_buffer_1;
    TEST_TENSOR_TYPE *const b_buf1 = input_b_buffer_2;

    /* Non-blocking export of C tiles: export previous while computing current. */
    TTL_event export_e = TTL_get_event();
    TTL_export_double_buffering<TEST_TENSOR_TYPE> export_db(output_buffer_1, output_buffer_2, ext_c, &export_e);

    for (int tile_id = 0; tile_id < c_tiler.number_of_tiles(); ++tile_id) {
        const TTL_tile c_tile = c_tiler.get_tile(tile_id); /* offset.x = n0, offset.y = m0 */

        /* Clear local C tile. */
        TTL_sub_tensor<TEST_TENSOR_TYPE> c_local = export_db.step_buffering(c_tile);
        for (TTL_dim y = 0; y < c_tile.shape.height; ++y) {
            for (TTL_dim x = 0; x < c_tile.shape.width; ++x) {
                c_local.write((TEST_TENSOR_TYPE)0, x, y);
            }
        }

        /* How many K-blocks? */
        const TTL_dim k_blocks = (Kt == 0) ? 0 : (K + Kt - 1) / Kt;

        /* Build first A/B tiles for k=0 and start buffering. */
        TTL_tile a0;
        a0.shape = TTL_shape((k_blocks > 0 ? ((K < Kt) ? K : Kt) : 0), c_tile.shape.height);
        a0.offset = TTL_offset(0, c_tile.offset.y, 0);

        TTL_tile b0;
        b0.shape = TTL_shape(c_tile.shape.width, (k_blocks > 0 ? ((K < Kt) ? K : Kt) : 0));
        b0.offset = TTL_offset(c_tile.offset.x, 0, 0);

        TTL_event e_a = TTL_get_event();
        TTL_event e_b = TTL_get_event();
        TTL_import_double_buffering<TEST_TENSOR_TYPE> a_db(a_buf0, a_buf1, ext_a, &e_a, a0);
        TTL_import_double_buffering<TEST_TENSOR_TYPE> b_db(b_buf0, b_buf1, ext_b, &e_b, b0);

        for (TTL_dim kb = 0; kb < k_blocks; ++kb) {
            /* Next tiles to prefetch (kb+1) or empty at end. */
            const TTL_dim k0_next = (kb + 1) * Kt;
            const bool has_next = (kb + 1) < k_blocks;
            const TTL_dim k_width_next = has_next ? (TTL_dim)((k0_next + Kt <= K) ? Kt : (K - k0_next)) : 0;

            TTL_tile a_next;
            a_next.shape = TTL_shape(k_width_next, c_tile.shape.height);
            a_next.offset = TTL_offset((TTL_offset_dim)k0_next, c_tile.offset.y, 0);

            TTL_tile b_next;
            b_next.shape = TTL_shape(c_tile.shape.width, k_width_next);
            b_next.offset = TTL_offset(c_tile.offset.x, (TTL_offset_dim)k0_next, 0);

            TTL_sub_tensor<TEST_TENSOR_TYPE> a_blk = a_db.step_buffering(has_next ? a_next : TTL_tile());
            TTL_sub_tensor<TEST_TENSOR_TYPE> b_blk = b_db.step_buffering(has_next ? b_next : TTL_tile());

            if (!a_blk.empty() && !b_blk.empty()) {
                /* a_blk: [Mt x Kt_cur] with shape.width = Kt_cur, shape.height = Mt_cur
                   b_blk: [Kt_cur x Nt] with shape.width = Nt_cur, shape.height = Kt_cur */
                const TTL_dim Kt_cur = a_blk.tensor.shape.width;

                for (TTL_dim y = 0; y < c_tile.shape.height; ++y) {          /* m */
                    for (TTL_dim x = 0; x < c_tile.shape.width; ++x) {       /* n */
                        TEST_TENSOR_TYPE acc = c_local.read(x, y);
                        for (TTL_dim kk = 0; kk < Kt_cur; ++kk) {
                            acc = (TEST_TENSOR_TYPE)(acc + a_blk.read(kk, y) * b_blk.read(x, kk));
                        }
                        c_local.write(acc, x, y);
                    }
                }
            }
        }

        a_db.finish_buffering();
        b_db.finish_buffering();
    }

    /* Flush the last in-flight exports. */
    export_db.finish_buffering();
}

/* Tiled GEMM (non-pipelined):
 * - Still computes in C tiles (Nt x Mt) and K blocks (Kt)
 * - But each A/B block is imported with TTL_blocking_import and C is exported with TTL_blocking_export.
 */
void ttl_matmul_kernel_non_pipelined(TEST_TENSOR_TYPE *restrict A, int lda,
                                     TEST_TENSOR_TYPE *restrict B, int ldb,
                                     TEST_TENSOR_TYPE *restrict C, int ldc,
                                     TTL_dim M, TTL_dim N, TTL_dim K,
                                     TTL_dim Mt, TTL_dim Nt, TTL_dim Kt) {
    const TTL_shape a_shape(K, M);
    const TTL_shape b_shape(N, K);
    const TTL_shape c_shape(N, M);

    const TTL_layout a_layout((TTL_dim)lda);
    const TTL_layout b_layout((TTL_dim)ldb);
    const TTL_layout c_layout((TTL_dim)ldc);

    const TTL_tensor<TEST_TENSOR_TYPE> ext_a(A, a_shape, a_layout);
    const TTL_tensor<TEST_TENSOR_TYPE> ext_b(B, b_shape, b_layout);
    const TTL_tensor<TEST_TENSOR_TYPE> ext_c(C, c_shape, c_layout);

    const TTL_tiler c_tiler(c_shape, TTL_shape(Nt, Mt));

    TEST_TENSOR_TYPE *const a_buf = input_buffer_1;
    TEST_TENSOR_TYPE *const b_buf = input_b_buffer_1;
    TEST_TENSOR_TYPE *const c_buf = output_buffer_1;

    for (int tile_id = 0; tile_id < c_tiler.number_of_tiles(); ++tile_id) {
        const TTL_tile c_tile = c_tiler.get_tile(tile_id);

        /* Local C tile storage. */
        const TTL_layout c_local_layout(c_tile.shape.width, 0);
        TTL_tensor<TEST_TENSOR_TYPE> c_local_tensor(c_buf, c_tile.shape, c_local_layout);

        for (TTL_dim y = 0; y < c_tile.shape.height; ++y)
            for (TTL_dim x = 0; x < c_tile.shape.width; ++x)
                c_local_tensor.write((TEST_TENSOR_TYPE)0, x, y);

        const TTL_dim k_blocks = (Kt == 0) ? 0 : (K + Kt - 1) / Kt;

        for (TTL_dim kb = 0; kb < k_blocks; ++kb) {
            const TTL_dim k0 = kb * Kt;
            const TTL_dim k_width = (TTL_dim)((k0 + Kt <= K) ? Kt : (K - k0));

            /* External views for this A and B block. */
            const TTL_tensor<TEST_TENSOR_TYPE> a_ext_blk(
                ext_a.base, TTL_shape(k_width, c_tile.shape.height), ext_a.layout, TTL_offset((TTL_offset_dim)k0, c_tile.offset.y, 0), ext_a.elem_size);
            const TTL_tensor<TEST_TENSOR_TYPE> b_ext_blk(
                ext_b.base, TTL_shape(c_tile.shape.width, k_width), ext_b.layout, TTL_offset(c_tile.offset.x, (TTL_offset_dim)k0, 0), ext_b.elem_size);

            /* Local tensors for imported blocks (contiguous). */
            const TTL_layout a_loc_layout(k_width, 0);
            const TTL_layout b_loc_layout(c_tile.shape.width, 0);
            TTL_tensor<TEST_TENSOR_TYPE> a_loc(a_buf, TTL_shape(k_width, c_tile.shape.height), a_loc_layout);
            TTL_tensor<TEST_TENSOR_TYPE> b_loc(b_buf, TTL_shape(c_tile.shape.width, k_width), b_loc_layout);

            TTL_blocking_import(a_loc, a_ext_blk);
            TTL_blocking_import(b_loc, b_ext_blk);

            for (TTL_dim y = 0; y < c_tile.shape.height; ++y) {
                for (TTL_dim x = 0; x < c_tile.shape.width; ++x) {
                    TEST_TENSOR_TYPE acc = c_local_tensor.read(x, y);
                    for (TTL_dim kk = 0; kk < k_width; ++kk) {
                        acc = (TEST_TENSOR_TYPE)(acc + a_loc.read(kk, y) * b_loc.read(x, kk));
                    }
                    c_local_tensor.write(acc, x, y);
                }
            }
        }

        /* Blocking export of C tile (non-pipelined). */
        const TTL_tensor<TEST_TENSOR_TYPE> c_ext_tile(
            ext_c.base, c_tile.shape, ext_c.layout, c_tile.offset, ext_c.elem_size);
        TTL_blocking_export(c_local_tensor, c_ext_tile);
    }
}

