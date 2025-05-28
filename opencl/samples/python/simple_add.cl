#include "TTL/TTL.h"
#include "compute_cross.h"

#undef TTL_EXT_TENSOR_TYPE
#define TTL_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, , ext_, TEST_TENSOR_TYPE, , _t)

// -----------------------------------------------
// TTL Loop Kind Enum
// -----------------------------------------------
typedef enum {
    TTL_LOOP_1D = 1,
    TTL_LOOP_2D = 2,
    TTL_LOOP_3D = 3
} TTL_loop_kind_t;

// -----------------------------------------------
// TTL Loop Metadata
// -----------------------------------------------
typedef struct {
    TTL_loop_kind_t dim;
    volatile int x_start, x_end, x_step, x;
    volatile int y_start, y_end, y_step, y;
    volatile int z_start, z_end, z_step, z;
} TTL_loop_affine_t;

// -----------------------------------------------
// TTL Tensor Rank Enum
// -----------------------------------------------
typedef enum {
    TTL_TENSOR_RANK_1D = 1,
    TTL_TENSOR_RANK_2D = 2,
    TTL_TENSOR_RANK_3D = 3
} TTL_tensor_rank_t;

// -----------------------------------------------
// TTL Affine Access Metadata (Explicit Dimensions)
// -----------------------------------------------
typedef struct {
    __global TEST_TENSOR_TYPE* restrict base;
    TTL_tensor_rank_t rank;

    int x_stride;
    int y_stride;
    int z_stride;

    int x_index;
    int y_index;
    int z_index;
} TTL_affine_access_t;

// -----------------------------------------------
// TTL Affine Index Helper
// -----------------------------------------------
int TTL_affine_compute_index(const TTL_affine_access_t* access) {
    return access->x_index * access->x_stride
         + access->y_index * access->y_stride
         + access->z_index * access->z_stride;
}

// -----------------------------------------------
// TTL Loop Body
// -----------------------------------------------
void TTL_loop_affine_matmul_body(
    TTL_loop_affine_t loop,
    TTL_affine_access_t access_A,
    TTL_affine_access_t access_B,
    TTL_affine_access_t access_C)
{
    int idx_A = TTL_affine_compute_index(&access_A);
    int idx_B = TTL_affine_compute_index(&access_B);
    int idx_C = TTL_affine_compute_index(&access_C);

    access_C.base[idx_C] += access_A.base[idx_A] * access_B.base[idx_B];
}

// -----------------------------------------------
// TTL Entry Kernel
// -----------------------------------------------
__kernel void TTL_matmul_kernel(
    __global TEST_TENSOR_TYPE* restrict A_base, int A_row_stride, int A_plane_stride,
    __global TEST_TENSOR_TYPE* restrict B_base, int B_row_stride, int B_plane_stride,
    __global TEST_TENSOR_TYPE* restrict C_base, int C_row_stride, int C_plane_stride,
    int M, int N, int K)
{
    TTL_loop_affine_t loop = {
        .dim = TTL_LOOP_3D,
        .x_start = 0, .x_end = M, .x_step = 2, .x = 0, // i x=0 -> outer loop
        .y_start = 0, .y_end = N, .y_step = 3, .y = 1, // j y=1 -> inner loop
        .z_start = 0, .z_end = K, .z_step = 4, .z = 2  // k z=2 -> innermost loop
    };

    TTL_affine_access_t access_A = {
        .base = A_base,
        .rank = TTL_TENSOR_RANK_2D,
        .x_stride = 1,
        .y_stride = A_row_stride,
        .z_stride = 0,
        .x_index = loop.x, // i
        .y_index = loop.z, // k
        .z_index = 0
    };

    TTL_affine_access_t access_B = {
        .base = B_base,
        .rank = TTL_TENSOR_RANK_2D,
        .x_stride = 1,
        .y_stride = B_row_stride,
        .z_stride = 0,
        .x_index = loop.z, // k
        .y_index = loop.y, // j
        .z_index = 0
    };

    TTL_affine_access_t access_C = {
        .base = C_base,
        .rank = TTL_TENSOR_RANK_2D,
        .x_stride = 1,
        .y_stride = C_row_stride,
        .z_stride = 0,
        .x_index = loop.x, // i 
        .y_index = loop.y, // j
        .z_index = 0
    };

    TTL_loop_affine_matmul_body(loop, access_A, access_B, access_C);
}
