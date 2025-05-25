#include "TTL/TTL.h"

// Define constants for local memory allocation
// This will be used to determine the maximum tile size
#ifndef LOCAL_MEMORY_SIZE
#define LOCAL_MEMORY_SIZE 32768  // Default value if not provided
#endif

// Define optional tile overlaps - for simple addition, these are all 0
#define TILE_OVERLAP_LEFT 0
#define TILE_OVERLAP_RIGHT 0
#define TILE_OVERLAP_TOP 0
#define TILE_OVERLAP_BOTTOM 0

// Tensor type definitions
#undef TTL_EXT_TENSOR_TYPE
#define TTL_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, , ext_, TEST_TENSOR_TYPE, , _t)

#undef TTL_INT_TENSOR_TYPE
#define TTL_INT_TENSOR_TYPE __TTL_tensor_name(TTL_, , int_, TEST_TENSOR_TYPE, , _t)

#undef TTL_IO_TENSORS_TYPE
#define TTL_IO_TENSORS_TYPE __TTL_tensor_name(TTL_io_, , , TEST_TENSOR_TYPE, , _t)

#undef TTL_SIMPLEX_BUFFERING_TYPE
#define TTL_SIMPLEX_BUFFERING_TYPE __TTL_tensor_name(TTL_simplex_, const_, , TEST_TENSOR_TYPE, , _buffering_t)

// Compute function for tile addition
void compute_addition(TTL_INT_TENSOR_TYPE int_tensor_A, TTL_INT_TENSOR_TYPE int_tensor_B, 
                     TTL_INT_TENSOR_TYPE int_tensor_C, int width, int height) {
    for (int i = 0; i < height; ++i) {
        for (int j = 0; j < width; ++j) {
            TEST_TENSOR_TYPE a_val = TTL_read_tensor(int_tensor_A, j, i);
            TEST_TENSOR_TYPE b_val = TTL_read_tensor(int_tensor_B, j, i);
            TTL_write_tensor(int_tensor_C, a_val + b_val, j, i);
        }
    }
}

__kernel void TTL_simplex_addition_tiled(__global TEST_TENSOR_TYPE *restrict ext_base_A, int external_stride_A,
                                        __global TEST_TENSOR_TYPE *restrict ext_base_B, int external_stride_B,
                                        __global TEST_TENSOR_TYPE *restrict ext_base_C, int external_stride_C,
                                        int width, int height, int tile_width, int tile_height) {
    // Check if tile size fits in local memory
    int tile_size = tile_width * tile_height;
    int local_mem_per_tensor = (LOCAL_MEMORY_SIZE / sizeof(TEST_TENSOR_TYPE)) / 3;
    
    if (tile_size > local_mem_per_tensor) {
        printf("Tile too large: %d elements > %d available per tensor\n", 
               tile_size, local_mem_per_tensor);
        return;
    }
    
    // Allocate local memory for internal tensors
    __local TEST_TENSOR_TYPE local_A[LOCAL_MEMORY_SIZE / sizeof(TEST_TENSOR_TYPE) / 3];
    __local TEST_TENSOR_TYPE local_B[LOCAL_MEMORY_SIZE / sizeof(TEST_TENSOR_TYPE) / 3];
    __local TEST_TENSOR_TYPE local_C[LOCAL_MEMORY_SIZE / sizeof(TEST_TENSOR_TYPE) / 3];

    // Create shapes for tensors and tiles
    const TTL_shape_t tensor_shape = TTL_create_shape(width, height);
    const TTL_shape_t tile_shape = TTL_create_shape(tile_width, tile_height);
    
    // External tensor layouts with strides
    const TTL_layout_t ext_layout_A = TTL_create_layout(external_stride_A);
    const TTL_layout_t ext_layout_B = TTL_create_layout(external_stride_B);
    const TTL_layout_t ext_layout_C = TTL_create_layout(external_stride_C);
    
    // Create tiler for tile-based processing
    const TTL_tiler_t tiler = TTL_create_tiler(tensor_shape, tile_shape);
    
    // Process each tile 
    for (int tile_idx = 0; tile_idx < TTL_number_of_tiles(tiler); ++tile_idx) {
        // Get the current tile position
        TTL_tile_t current_tile = TTL_get_tile(tile_idx, tiler);
        
        // Create internal tensors for the current tile
        TTL_INT_TENSOR_TYPE int_tensor_A = TTL_create_int_tensor(local_A, current_tile.shape);
        TTL_INT_TENSOR_TYPE int_tensor_B = TTL_create_int_tensor(local_B, current_tile.shape);
        TTL_INT_TENSOR_TYPE int_tensor_C = TTL_create_int_tensor(local_C, current_tile.shape);
        
        // Calculate offsets into external memory for this tile
        __global TEST_TENSOR_TYPE *tile_base_A = ext_base_A + (current_tile.offset.y * external_stride_A) + current_tile.offset.x;
        __global TEST_TENSOR_TYPE *tile_base_B = ext_base_B + (current_tile.offset.y * external_stride_B) + current_tile.offset.x;
        __global TEST_TENSOR_TYPE *tile_base_C = ext_base_C + (current_tile.offset.y * external_stride_C) + current_tile.offset.x;
        
        // Create external tensors for the current tile
        TTL_EXT_TENSOR_TYPE ext_tensor_A = TTL_create_ext_tensor(tile_base_A, current_tile.shape, ext_layout_A);
        TTL_EXT_TENSOR_TYPE ext_tensor_B = TTL_create_ext_tensor(tile_base_B, current_tile.shape, ext_layout_B);
        TTL_EXT_TENSOR_TYPE ext_tensor_C = TTL_create_ext_tensor(tile_base_C, current_tile.shape, ext_layout_C);
        
        // Import tile data from external memory to local memory
        TTL_event_t event_A = TTL_get_event();
        TTL_event_t event_B = TTL_get_event();
        
        TTL_import(int_tensor_A, ext_tensor_A, &event_A);
        TTL_import(int_tensor_B, ext_tensor_B, &event_B);
        
        // Wait for imports to complete
        TTL_wait(1, &event_A);
        TTL_wait(1, &event_B);
        
        // Perform computation on this tile
        compute_addition(int_tensor_A, int_tensor_B, int_tensor_C, 
                       current_tile.shape.width, current_tile.shape.height);
        
        // Export result for this tile back to external memory
        TTL_event_t event_C = TTL_get_event();
        TTL_export(int_tensor_C, ext_tensor_C, &event_C);
        TTL_wait(1, &event_C);
    }
} 