#include "TTL/TTL.h"

#define TILE_M 32
#define TILE_N 32
#define TILE_K 32

// Assume TEST_TENSOR_TYPE is float for this example
#ifndef TEST_TENSOR_TYPE
#define TEST_TENSOR_TYPE float
#endif

#undef TTL_EXT_TENSOR_TYPE
#define TTL_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, , ext_, TEST_TENSOR_TYPE, , _t)

#undef TTL_INT_TENSOR_TYPE
#define TTL_INT_TENSOR_TYPE __TTL_tensor_name(TTL_, , int_, TEST_TENSOR_TYPE, , _t)

__kernel void TTL_tiled_matmul(
    __global TEST_TENSOR_TYPE *restrict base_A, int stride_A,
    __global TEST_TENSOR_TYPE *restrict base_B, int stride_B,
    __global TEST_TENSOR_TYPE *restrict base_C, int stride_C,
    int M, int N, int K)
{
    // Shapes and tilers
    const TTL_shape_t shape_A = TTL_create_shape(M, K);
    const TTL_shape_t shape_B = TTL_create_shape(K, N);
    const TTL_shape_t shape_C = TTL_create_shape(M, N);

    const TTL_shape_t tile_shape_A = TTL_create_shape(TILE_M, TILE_K);
    const TTL_shape_t tile_shape_B = TTL_create_shape(TILE_K, TILE_N);
    const TTL_shape_t tile_shape_C = TTL_create_shape(TILE_M, TILE_N);

    const TTL_tiler_t tiler_A = TTL_create_tiler(shape_A, tile_shape_A);
    const TTL_tiler_t tiler_B = TTL_create_tiler(shape_B, tile_shape_B);
    const TTL_tiler_t tiler_C = TTL_create_tiler(shape_C, tile_shape_C);

    // Layouts
    const TTL_layout_t layout_A = TTL_create_layout(stride_A);
    const TTL_layout_t layout_B = TTL_create_layout(stride_B);
    const TTL_layout_t layout_C = TTL_create_layout(stride_C);

    // External tensors for the full matrices
    const TTL_EXT_TENSOR_TYPE ext_tensor_A = TTL_create_ext_tensor(base_A, shape_A, layout_A);
    const TTL_EXT_TENSOR_TYPE ext_tensor_B = TTL_create_ext_tensor(base_B, shape_B, layout_B);
    const TTL_EXT_TENSOR_TYPE ext_tensor_C = TTL_create_ext_tensor(base_C, shape_C, layout_C);

    // Internal layout: dense packing for tiles
    const TTL_layout_t int_layout_A = TTL_create_layout(TILE_K);
    const TTL_layout_t int_layout_B = TTL_create_layout(TILE_N);
    const TTL_layout_t int_layout_C = TTL_create_layout(TILE_N);

    // Allocate local memory for internal tiles
    __local TEST_TENSOR_TYPE local_A[TILE_M * TILE_K];
    __local TEST_TENSOR_TYPE local_B[TILE_K * TILE_N];
    __local TEST_TENSOR_TYPE local_C[TILE_M * TILE_N];

    int tiles_in_width_C = TTL_tiles_in_width(tiler_C);
    int tiles_in_height_C = TTL_tiles_in_height(tiler_C);
    int tiles_in_width_A = TTL_tiles_in_width(tiler_A); // for K dimension

    for (int tile_y = 0; tile_y < tiles_in_height_C; ++tile_y) {
        for (int tile_x = 0; tile_x < tiles_in_width_C; ++tile_x) {
            TTL_tile_t tile_C = TTL_create_tile(tile_x, tile_y, 0, tiler_C);
            int tile_M_eff = tile_C.shape.width;
            int tile_N_eff = tile_C.shape.height;

            // Create external sub-tensor for C tile
            TTL_EXT_TENSOR_TYPE ext_tile_C = TTL_create_ext_sub_tensor(ext_tensor_C, tile_C);
            TTL_INT_TENSOR_TYPE int_tile_C = TTL_create_int_tensor(local_C, tile_C.shape, int_layout_C);

            // Zero the C tile in local memory
            for (int i = 0; i < tile_M_eff; ++i)
                for (int j = 0; j < tile_N_eff; ++j)
                    TTL_write_tensor(int_tile_C, 0, j, i);

            for (int tile_k = 0; tile_k < tiles_in_width_A; ++tile_k) {
                TTL_tile_t tile_A = TTL_create_tile(tile_x, tile_k, 0, tiler_A);
                TTL_tile_t tile_B = TTL_create_tile(tile_k, tile_y, 0, tiler_B);
                int tile_K_eff = tile_A.shape.height;

                // Create external sub-tensors for A and B tiles
                TTL_EXT_TENSOR_TYPE ext_tile_A = TTL_create_ext_sub_tensor(ext_tensor_A, tile_A);
                TTL_EXT_TENSOR_TYPE ext_tile_B = TTL_create_ext_sub_tensor(ext_tensor_B, tile_B);

                TTL_INT_TENSOR_TYPE int_tile_A = TTL_create_int_tensor(local_A, tile_A.shape, int_layout_A);
                TTL_INT_TENSOR_TYPE int_tile_B = TTL_create_int_tensor(local_B, tile_B.shape, int_layout_B);

                // Import tiles from external to internal
                TTL_event_t event_A = TTL_get_event();
                TTL_event_t event_B = TTL_get_event();
                TTL_import(int_tile_A, ext_tile_A, &event_A);
                TTL_import(int_tile_B, ext_tile_B, &event_B);
                TTL_wait(1, &event_A);
                TTL_wait(1, &event_B);

                // Tile-level matmul: C_tile += A_tile * B_tile
                for (int i = 0; i < tile_M_eff; ++i) {
                    for (int j = 0; j < tile_N_eff; ++j) {
                        float sum = TTL_read_tensor(int_tile_C, j, i);
                        for (int k = 0; k < tile_K_eff; ++k) {
                            float a = TTL_read_tensor(int_tile_A, k, i);
                            float b = TTL_read_tensor(int_tile_B, j, k);
                            sum += a * b;
                        }
                        TTL_write_tensor(int_tile_C, sum, j, i);
                    }
                }
            }
            // Export result from internal to external
            TTL_event_t event_C = TTL_get_event();
            TTL_export(int_tile_C, ext_tile_C, &event_C);
            TTL_wait(1, &event_C);
        }
    }
} 