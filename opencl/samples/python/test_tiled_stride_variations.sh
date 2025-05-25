#!/bin/bash

# Test script for TTL_simplex_addition_tiled.cl with various stride and tile configurations
echo "==== TTL Tiled Addition Testing Script ===="
echo ""

# Set the TTL include path
TTL_INCLUDE_PATH=/home/ubuntu/msc

# Change to the script directory
cd $(dirname "$0")

# Test 1: Matrix 24x24 with 8x8 tiles (default configuration)
echo "Test 1: Default 24x24 matrix with 8x8 tiles"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_tiled_addition_runner.py TTL_simplex_addition_tiled.cl
echo ""

# Test 2: Matrix 16x16 with 4x4 tiles and uniform strides
echo "Test 2: 16x16 matrix with 4x4 tiles and padded strides"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_tiled_addition_runner.py TTL_simplex_addition_tiled.cl \
    --width 16 --height 16 --tile-width 4 --tile-height 4 --stride-a 24 --stride-b 24 --stride-c 24
echo ""

# Test 3: Matrix 32x32 with 8x16 rectangular tiles
echo "Test 3: 32x32 matrix with 8x16 rectangular tiles"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_tiled_addition_runner.py TTL_simplex_addition_tiled.cl \
    --width 32 --height 32 --tile-width 8 --tile-height 16
echo ""

# Test 4: Matrix 20x20 with 5x5 tiles and different strides
echo "Test 4: 20x20 matrix with 5x5 tiles and different strides"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_tiled_addition_runner.py TTL_simplex_addition_tiled.cl \
    --width 20 --height 20 --tile-width 5 --tile-height 5 --stride-a 24 --stride-b 28 --stride-c 32
echo ""

# Test 5: Larger 48x48 matrix with 12x16 tiles
echo "Test 5: Larger 48x48 matrix with 12x16 tiles"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_tiled_addition_runner.py TTL_simplex_addition_tiled.cl \
    --width 48 --height 48 --tile-width 12 --tile-height 16
echo ""

# Test 6: Small 12x12 matrix with very small 2x3 tiles
echo "Test 6: Small 12x12 matrix with very small 2x3 tiles"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_tiled_addition_runner.py TTL_simplex_addition_tiled.cl \
    --width 12 --height 12 --tile-width 2 --tile-height 3 --stride-a 16 --stride-b 16 --stride-c 16
echo ""

echo "==== All tests completed ====" 