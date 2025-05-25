# Tensor Tiling Library (TTL) Project Index

## Overview
The Tensor Tiling Library (TTL) is an open-source library for efficient tiling and computing with tensors. It provides a standardized way of tiling tensors to optimize performance in heterogeneous computing environments.

## Core Components

### Header Files
- **TTL.h** - Main include header
- **TTL_core.h** - Core functionality
- **TTL_create_type.h** - Type creation utilities
- **TTL_create_types.h** - Multiple type creation utilities
- **TTL_debug.h** - Debugging functionality
- **TTL_import_export.h** - Import/export functionality wrapper
- **TTL_macros.h** - Common macros
- **TTL_tensors.h** - Tensor handling
- **TTL_tiles.h** - Tiling functionality
- **TTL_trace_macros.h** - Tracing macros
- **TTL_types.h** - Type definitions
- **TTL_pipeline_schemes.h** - Pipeline mechanisms

### Tensor Components (`tensors/`)
- **TTL_tensors_common.h** - Common tensor functionality
- **TTL_ext_tensors.h** - External tensor definitions
- **TTL_int_tensors.h** - Internal tensor definitions
- **TTL_tensor_rw.h** - Tensor read/write operations
- **TTL_int_ext_typed_tensors.h** - Typed tensors for internal/external use
- **TTL_types.h** - Type definitions for tensors

### Import/Export Components (`import_export/`)
- **TTL_typed_import_export.h** - Typed import/export functions

### Pipeline Mechanisms (`pipelines/`)
- **TTL_double_scheme.h** - Double buffering scheme
- **TTL_double_scheme_template.h** - Templates for double buffering
- **TTL_duplex_scheme.h** - Duplex buffering scheme
- **TTL_schemes_common.h** - Common functionality for schemes
- **TTL_simplex_scheme.h** - Simplex buffering scheme

## Target Platform Support

### OpenCL Implementation (`opencl/`)
- **TTL_async_work_group_copy_3D3D.h** - 3D async work group copy
- **TTL_import_export.h** - OpenCL specific import/export
- **TTL_types.h** - OpenCL specific types

#### OpenCL Samples (`opencl/samples/`)
- **python/** - Python-based samples
  - **TTL_simplex_addition.cl** - Simplex addition sample
  - **TTL_matmul.cl** - Matrix multiplication sample
  - **TTL_matmul_tiled.cl** - Tiled matrix multiplication
  - **TTL_double_buffering.cl** - Double buffering sample
  - **TTL_duplex_buffering.cl** - Duplex buffering sample
  - **TTL_simplex_buffering.cl** - Simplex buffering sample
  - **TTL_sample_runner.py** - Generic runner for testing OpenCL kernels with different tensor types and sizes
  - **TTL_addition_runner.py** - Runner specifically for addition examples
  - **TTL_matmul_runner.py** - Runner specifically for matrix multiplication examples
- **cpp/** - C++ based samples

### C Implementation (`c/`)
- **TTL_import_export.h** - C specific import/export
- **TTL_types.h** - C specific types
- **samples/** - C specific samples

## Build System
- **CMakeLists.txt** - CMake build configuration
- **INSTALL** - Installation instructions

## Documentation
- **README.md** - Main readme with usage examples
- **doc/** - Documentation directory

## Miscellaneous
- **scripts/** - Utility scripts
- **gh-pages/** - GitHub pages content
- **.github/** - GitHub configuration
- **LICENSE/** - License information
- **license.txt** - License file

## Sample Code Analysis

### TTL_simplex_addition.cl 
This file demonstrates the basic tensor addition operation using TTL's simplex buffering scheme.

Key components:
1. **Memory Allocation**:
   - Allocates local memory for tensors (local_A, local_B, local_C)
   - Memory size defined by MEMSZ (81 elements, suitable for 9x9 matrices)

2. **Tensor Types**:
   - Uses TTL_INT_TENSOR_TYPE and TTL_EXT_TENSOR_TYPE macros to define tensor types
   - TEST_TENSOR_TYPE determines the data type for tensor elements

3. **Computation Function**:
   - `compute_2D()` - Performs element-wise addition on 2D tensors
   - Reads values from tensors A and B, adds them, and writes to tensor C

4. **OpenCL Kernel**:
   - `TTL_simplex_addition` - Main kernel function
   - Creates tensor shapes, layouts, and external/internal tensors
   - Uses asynchronous import/export with events for synchronization
   - Imports external data, performs computation, exports results back

5. **Data Movement Pattern**:
   - Follows the simplex buffering scheme for data movement
   - Uses TTL events for synchronization of data transfers
   - Demonstrates the import → compute → export workflow

This sample showcases TTL's ability to handle tensor operations with managed data movement between external (global) and internal (local) memory spaces.

### TTL_sample_runner.py
The Python runner framework for testing TTL OpenCL kernels:

1. **Testing Framework**:
   - Tests each OpenCL kernel with multiple tensor types (char, uchar, short, ushort, int, uint, long, ulong)
   - Runs tests with various tensor dimensions and tile sizes
   - Uses PyOpenCL for interfacing with OpenCL

2. **Testing Procedure**:
   - Creates random tensor data
   - Passes data to OpenCL kernel
   - Verifies correct results after kernel execution
   - Tests different combinations of tensor and tile sizes

3. **Compilation Process**:
   - Compiles OpenCL kernel with appropriate TTL include paths
   - Defines TEST_TENSOR_TYPE to specify data type for the test
   - Sets other compilation options like LOCAL_MEMORY_SIZE based on device capabilities

4. **Error Handling**:
   - Provides detailed error messages for test failures
   - Reports exact tensor coordinates where mismatches occur

This runner enables comprehensive testing of TTL kernels across various data types and tensor configurations. 