# Tensor Tiling Library (TTL) - Detailed Analysis

## Overview

The Tensor Tiling Library (TTL) is an open-source library for efficient tensor operations in heterogeneous computing environments. It provides a standardized approach to tiling tensors for performance optimization by managing data movement between different memory spaces (e.g., global to local memory in OpenCL).

## Core Architecture

### 1. Core Data Types

The TTL architecture is built around several key data structures:

- **TTL_shape_t**: Describes the dimensions of tensors (width, height, depth)
  ```c
  typedef struct {
      TTL_dim_t width;   ///< Number of elements along dimension x.
      TTL_dim_t height;  ///< Number of rows along dimension y
      TTL_dim_t depth;   ///< Number of planes along dimension z
  } TTL_shape_t;
  ```

- **TTL_offset_t**: Describes 3D offsets of objects
  ```c
  typedef struct {
      TTL_offset_dim_t x;  ///< Offset in dimension x.
      TTL_offset_dim_t y;  ///< Offset in dimension y.
      TTL_offset_dim_t z;  ///< Offset in dimension z.
  } TTL_offset_t;
  ```

- **TTL_layout_t**: Describes the memory layout of tensors
  ```c
  typedef struct {
      TTL_dim_t row_spacing;    ///< Distance between consecutive rows
      TTL_dim_t plane_spacing;  ///< Distance between consecutive planes
  } TTL_layout_t;
  ```

- **TTL_overlap_t**: Describes the overlap between adjacent tiles
  ```c
  typedef struct {
      TTL_overlap_dim_t width;   ///< width overlap in elements
      TTL_overlap_dim_t height;  ///< height overlap in elements
      TTL_overlap_dim_t depth;   ///< depth overlap in elements
  } TTL_overlap_t;
  ```

### 2. Tensor Types

TTL implements two main categories of tensors:

- **External Tensors** (`TTL_EXT_TENSOR_TYPE`): Tensors located in global/external memory (e.g., device global memory in OpenCL)
- **Internal Tensors** (`TTL_INT_TENSOR_TYPE`): Tensors located in local/internal memory (e.g., workgroup local memory in OpenCL)

Each tensor type stores:
- Base pointer
- Element size
- Shape information
- Memory layout

### 3. Memory Management

TTL provides mechanisms for efficient data movement between external and internal memory:

- **Import**: Transfers data from external to internal memory
- **Export**: Transfers data from internal to external memory

These operations can be synchronous or asynchronous using events:

```c
TTL_import(int_tensor_A, ext_tensor_A, &event_A);
TTL_wait(1, &event_A);
```

## Buffering Schemes

TTL implements several buffering schemes for efficient data movement and computation overlap:

### 1. Simplex Buffering

Uses three internal buffers in rotation, where each buffer interchangeably serves as input and output buffer. This scheme allows:
- DMA transactions to run in parallel with computation
- Sequential transfers between buffers
- Overlap of exporting from and importing to the same buffer

Key components:
```c
typedef struct {
    TTL_common_buffering_t(TTL_TENSOR_TYPE *, TTL_EXT_TENSOR_TYPE, TTL_EXT_TENSOR_TYPE, 3) common;
    TTL_event_t *event_in;
    TTL_event_t *event_out;
    TTL_tile_t next_exported_tile;
    TTL_INT_SUB_TENSOR_TYPE int_prev_imported;
} TTL_SIMPLEX_BUFFERING_TYPE;
```

### 2. Double Buffering

Uses two sets of buffers, one for input and one for output, allowing:
- Continuous data transfer and computation
- Separate handling of import and export operations
- Parallel processing of different tiles

Components:
```c
// Import double buffering
TTL_IMPORT_DOUBLE_BUFFERING_TYPE import_db = TTL_start_import_double_buffering(
    input_buffer_1, input_buffer_2, ext_input_tensor, &import_DB_e, TTL_get_tile(0, input_tiler));

// Export double buffering
TTL_EXPORT_DOUBLE_BUFFERING_TYPE export_db =
    TTL_start_export_double_buffering(output_buffer_1, output_buffer_2, ext_output_tensor, &export_DB_e);
```

### 3. Duplex Buffering (Advanced)

A more complex scheme available for specialized use cases.

## Usage Pattern

The general pattern for using TTL involves:

1. **Setup phase**:
   - Define tensor shapes and layouts
   - Create external tensors (pointing to global memory)
   - Create internal tensors (in local memory)
   - Setup buffering scheme

2. **Processing loop**:
   - Get next tile to process
   - Import data from external to internal memory
   - Perform computation on internal tensors
   - Export results from internal to external memory

3. **Cleanup phase**:
   - Finish any pending buffer operations

Example from `TTL_simplex_addition.cl`:
```c
// Setup phase
const TTL_shape_t tensor_shape = TTL_create_shape(width, height);
const TTL_layout_t ext_layout_A = TTL_create_layout(external_stride_A);
const TTL_EXT_TENSOR_TYPE ext_tensor_A = TTL_create_ext_tensor(ext_base_A, tensor_shape, ext_layout_A);
TTL_INT_TENSOR_TYPE int_tensor_A = TTL_create_int_tensor(local_A, tensor_shape);

// Import/Export with event synchronization
TTL_event_t event_A = TTL_get_event();
TTL_import(int_tensor_A, ext_tensor_A, &event_A);
TTL_wait(1, &event_A);

// Computation
compute_2D(int_tensor_A, int_tensor_B, int_tensor_C, width, height);

// Export results
TTL_event_t event_C = TTL_get_event();
TTL_export(int_tensor_C, ext_tensor_C, &event_C);
TTL_wait(1, &event_C);
```

## Implementation Details

### Memory Layout & Linearization

TTL handles the complex mapping between logical tensor indices and physical memory addresses:

```c
static inline TTL_offset_dim_t TTL_linearize(const TTL_offset_t offset, const TTL_layout_t layout) {
    return ((offset.z * layout.plane_spacing) + (offset.y * layout.row_spacing) + offset.x);
}
```

### Type Generation System

TTL uses an extensive macro system to generate type-specific implementations:

```c
#define TTL_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, , ext_, TEST_TENSOR_TYPE, , _t)
#define TTL_INT_TENSOR_TYPE __TTL_tensor_name(TTL_, , int_, TEST_TENSOR_TYPE, , _t)
```

This allows TTL to work with different data types (char, uchar, short, int, float, etc.) without code duplication.

### Cross-Platform Support

TTL supports multiple targets:
- OpenCL (default)
- C
- Potentially other platforms via extension

## Performance Considerations

1. **Memory Transfer Optimization**:
   - Asynchronous transfers allow overlap of computation and data movement
   - Different buffering schemes optimize for different workload patterns

2. **Tiling Strategy**:
   - Proper tile sizing is crucial for performance
   - Tile size must balance local memory limitations with compute efficiency

3. **Overlap Handling**:
   - Support for overlapping tiles enables algorithms that require neighbor data
   - Configurable overlap regions (left, right, top, bottom)

## Testing Framework

The project includes a comprehensive testing framework:

- Tests multiple tensor types (char, uchar, short, ushort, int, uint, long, ulong)
- Tests various tensor and tile dimensions
- Verifies correct results across different configurations
- Provides detailed error reporting

## Summary

TTL provides a powerful abstraction for efficient tensor operations in heterogeneous computing environments. By managing the complex details of tiling, memory transfers, and synchronization, it allows developers to focus on the algorithmic aspects of their tensor operations while achieving high performance through optimized data movement patterns. 