#include "TTL/TTL.h"

// Define a larger MEMSZ to accommodate various matrix sizes and strides
// This should be enough for matrices up to 32x32 with stride up to 64
#define MEMSZ 2048

// Tensor type definitions
#undef TTL_EXT_TENSOR_TYPE
#define TTL_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, , ext_, TEST_TENSOR_TYPE, , _t)

#undef TTL_INT_TENSOR_TYPE
#define TTL_INT_TENSOR_TYPE __TTL_tensor_name(TTL_, , int_, TEST_TENSOR_TYPE, , _t)

// External function for 2D computation
void compute_2D(TTL_INT_TENSOR_TYPE int_tensor_A, TTL_INT_TENSOR_TYPE int_tensor_B, TTL_INT_TENSOR_TYPE int_tensor_C, int width, int height) {
    for (int i = 0; i < height; ++i) {
        for (int j = 0; j < width; ++j) {
            TEST_TENSOR_TYPE a_val = TTL_read_tensor(int_tensor_A, j, i);
            TEST_TENSOR_TYPE b_val = TTL_read_tensor(int_tensor_B, j, i);
            TTL_write_tensor(int_tensor_C, a_val + b_val, j, i);
        }
    }
}

__kernel void TTL_simplex_addition(__global TEST_TENSOR_TYPE *restrict ext_base_A, int external_stride_A,
                                   __global TEST_TENSOR_TYPE *restrict ext_base_B, int external_stride_B,
                                   __global TEST_TENSOR_TYPE *restrict ext_base_C, int external_stride_C,
                                   int width, int height) {
    // Validate that local memory is sufficient for the requested dimensions
    const int required_memory = width * height * sizeof(TEST_TENSOR_TYPE);
    if (required_memory > MEMSZ * sizeof(TEST_TENSOR_TYPE)) {
        // In a real application, we'd want to handle this error more gracefully
        return;
    }
    
    // Allocate local memory for internal tensors
    __local TEST_TENSOR_TYPE local_A[MEMSZ];
    __local TEST_TENSOR_TYPE local_B[MEMSZ];
    __local TEST_TENSOR_TYPE local_C[MEMSZ];

    // Logical shapes for the visible portion of the matrices
    const TTL_shape_t tensor_shape = TTL_create_shape(width, height);

    // External layouts with custom strides
    const TTL_layout_t ext_layout_A = TTL_create_layout(external_stride_A);
    const TTL_layout_t ext_layout_B = TTL_create_layout(external_stride_B);
    const TTL_layout_t ext_layout_C = TTL_create_layout(external_stride_C);

    // Internal layouts - we use width as the stride for internal tensors
    // This ensures dense packing in local memory
    const TTL_layout_t int_layout = TTL_create_layout(width);

    // External tensors with custom strides
    const TTL_EXT_TENSOR_TYPE ext_tensor_A = TTL_create_ext_tensor(ext_base_A, tensor_shape, ext_layout_A);
    const TTL_EXT_TENSOR_TYPE ext_tensor_B = TTL_create_ext_tensor(ext_base_B, tensor_shape, ext_layout_B);
    const TTL_EXT_TENSOR_TYPE ext_tensor_C = TTL_create_ext_tensor(ext_base_C, tensor_shape, ext_layout_C);

    // Internal tensors with explicit layouts
    TTL_INT_TENSOR_TYPE int_tensor_A = TTL_create_int_tensor(local_A, tensor_shape, int_layout);
    TTL_INT_TENSOR_TYPE int_tensor_B = TTL_create_int_tensor(local_B, tensor_shape, int_layout);
    TTL_INT_TENSOR_TYPE int_tensor_C = TTL_create_int_tensor(local_C, tensor_shape, int_layout);

    // Import external tensors to internal memory
    TTL_event_t event_A = TTL_get_event();
    TTL_event_t event_B = TTL_get_event();
    
    // Start asynchronous imports
    TTL_import(int_tensor_A, ext_tensor_A, &event_A);
    TTL_import(int_tensor_B, ext_tensor_B, &event_B);
    
    // Wait for imports to complete
    TTL_wait(1, &event_A);
    TTL_wait(1, &event_B);

    // Perform computation using internal tensors
    compute_2D(int_tensor_A, int_tensor_B, int_tensor_C, width, height);

    // Export result back to external memory
    TTL_event_t event_C = TTL_get_event();
    TTL_export(int_tensor_C, ext_tensor_C, &event_C);
    TTL_wait(1, &event_C);
}