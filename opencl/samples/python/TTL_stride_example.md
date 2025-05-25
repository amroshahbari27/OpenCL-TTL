# TTL Addition Runner with Custom Strides

The enhanced `TTL_addition_runner.py` now supports custom strides for matrices, allowing you to test tensor operations with different memory layouts. This is particularly useful for testing how the TTL library handles non-contiguous memory.

## Usage Examples

### Basic Usage (Default Strides)

Run the addition test with default 9x9 matrices and default strides:

```bash
python TTL_addition_runner.py TTL_simplex_addition.cl
```

### Custom Matrix Dimensions

Specify custom width and height for the matrices:

```bash
python TTL_addition_runner.py TTL_simplex_addition.cl --width 16 --height 8
```

### Custom Strides

Specify different strides for each matrix:

```bash
python TTL_addition_runner.py TTL_simplex_addition.cl --stride-a 12 --stride-b 16 --stride-c 20
```

This creates:
- Matrix A with a stride of 12 (extra padding after each row)
- Matrix B with a stride of 16 (extra padding after each row)
- Matrix C with a stride of 20 (extra padding after each row)

### Combined Custom Dimensions and Strides

Set both dimensions and strides together:

```bash
python TTL_addition_runner.py TTL_simplex_addition.cl --width 10 --height 10 --stride-a 16 --stride-b 16 --stride-c 16
```

## Understanding Strides

The stride represents the number of elements in memory between the start of consecutive rows:

- When stride equals width: Elements are tightly packed with no padding
- When stride is greater than width: There's padding between rows
- Different strides for different matrices: Tests TTL's ability to handle varied memory layouts

## Visualization

For a 4x4 matrix with a stride of 6:

```
Memory layout (x = data, - = padding):
x x x x - -
x x x x - -
x x x x - -
x x x x - -
```

The runner will correctly allocate memory, initialize values, and verify results taking these strides into account.

## Practical Applications

Custom strides are useful for:

1. Testing TTL's performance with non-contiguous memory
2. Simulating real-world scenarios where data alignment is needed
3. Validating TTL's import/export functionality with varied memory layouts
4. Testing edge cases in data movement optimization

## Implementation Details

The runner tracks different strides by:
- Allocating larger memory buffers to accommodate padding
- Using stride-aware read/write functions
- Passing stride values to OpenCL kernels
- Modifying verification logic to compare correct memory locations 