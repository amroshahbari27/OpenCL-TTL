#include "TTL/TTL.h"
#include "compute_cross.h"

// Tensor type configuration
#undef TTL_EXT_TENSOR_TYPE
#define TTL_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, , ext_, TEST_TENSOR_TYPE, , _t)

// -----------------------------------------------
// Loop Metadata (Affine Structured Representation)
// -----------------------------------------------
typedef enum {
    LOOP_1D = 0,
    LOOP_2D = 1,
    LOOP_3D = 2
} loop_affine_dim_t;

typedef struct {
    loop_affine_dim_t dim;
    volatile int x_start, x_end, x_step, x;  // i
    volatile int y_start, y_end, y_step, y;  // j
    volatile int z_start, z_end, z_step, z;  // k
} loop_affine_t;

// -----------------------------------------------
// Tensor Metadata
// Supports strided access in up to 3D
// -----------------------------------------------
typedef struct {
    __global TEST_TENSOR_TYPE* restrict base;
    int row_stride;    // stride in dim-1 (Y)
    int plane_stride;  // stride in dim-2 (Z)
} tensor_access_t;

// -----------------------------------------------
// Affine Loop Body: Matrix Multiplication
// C[i][j] += A[i][k] * B[k][j]
// -----------------------------------------------
void loop_affine_matmul_body(
    loop_affine_t loop,
    tensor_access_t A,
    tensor_access_t B,
    tensor_access_t C)
{
    TTL_layout_t layout_A = TTL_create_layout(A.row_stride, A.plane_stride);
    TTL_layout_t layout_B = TTL_create_layout(B.row_stride, B.plane_stride);
    TTL_layout_t layout_C = TTL_create_layout(C.row_stride, C.plane_stride);

    TTL_offset_t offset_A = TTL_create_offset(loop.x, loop.z, 0); // A[i][k]
    TTL_offset_t offset_B = TTL_create_offset(loop.z, loop.y, 0); // B[k][j]
    TTL_offset_t offset_C = TTL_create_offset(loop.x, loop.y, 0); // C[i][j]

    int idx_A = TTL_linearize(offset_A, layout_A);
    int idx_B = TTL_linearize(offset_B, layout_B);
    int idx_C = TTL_linearize(offset_C, layout_C);

    C.base[idx_C] += A.base[idx_A] * B.base[idx_B];
}

// -----------------------------------------------
// Entry Kernel
// Structured representation only — not executable
// Meant for static lowering into affine.for
// -----------------------------------------------
__kernel void matmul_kernel(
    __global TEST_TENSOR_TYPE* restrict A_base, int A_row_stride, int A_plane_stride,
    __global TEST_TENSOR_TYPE* restrict B_base, int B_row_stride, int B_plane_stride,
    __global TEST_TENSOR_TYPE* restrict C_base, int C_row_stride, int C_plane_stride,
    int M, int N, int K)
{
    
    loop_affine_t loop = {
        .dim = LOOP_3D,
        .x_start = 1, .x_end = M, .x_step = 3, .x = 0,  // i
        .y_start = 2, .y_end = N, .y_step = 2, .y = 0,  // j
        .z_start = 3, .z_end = K, .z_step = 1, .z = 0   // k
    };

    tensor_access_t A = { A_base, A_row_stride, A_plane_stride };
    tensor_access_t B = { B_base, B_row_stride, B_plane_stride };
    tensor_access_t C = { C_base, C_row_stride, C_plane_stride };

    loop_affine_matmul_body(loop, A, B, C);
}
