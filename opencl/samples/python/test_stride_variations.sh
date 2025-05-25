#!/bin/bash

# Test script for TTL_simplex_addition.cl with various stride configurations
echo "==== TTL Stride Testing Script ===="
echo ""

# Set the TTL include path
TTL_INCLUDE_PATH=/home/ubuntu/msc

# Basic test with default strides (strides equal width)
echo "Test 1: Default 9x9 matrix with default strides"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_addition_runner.py TTL_simplex_addition.cl
echo ""

# Test with equal custom strides
echo "Test 2: 8x8 matrix with all strides = 16 (padding at end of each row)"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_addition_runner.py TTL_simplex_addition.cl --width 8 --height 8 --stride-a 16 --stride-b 16 --stride-c 16
echo ""

# Test with different strides for each matrix
echo "Test 3: 10x10 matrix with different strides (A=12, B=16, C=20)"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_addition_runner.py TTL_simplex_addition.cl --width 10 --height 10 --stride-a 12 --stride-b 16 --stride-c 20
echo ""

# Test with rectangular matrix
echo "Test 4: Rectangular 16x8 matrix with custom strides"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_addition_runner.py TTL_simplex_addition.cl --width 16 --height 8 --stride-a 20 --stride-b 24 --stride-c 32
echo ""

# Test larger matrix to verify memory allocation
echo "Test 5: Larger 24x24 matrix with minimal strides"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_addition_runner.py TTL_simplex_addition.cl --width 24 --height 24
echo ""

# Test with strides smaller than width - this should still work if tensors are properly set up
echo "Test 6: Alternative case - C stride wider than A and B"
TTL_INCLUDE_PATH=$TTL_INCLUDE_PATH python3 TTL_addition_runner.py TTL_simplex_addition.cl --width 12 --height 12 --stride-a 12 --stride-b 12 --stride-c 24
echo ""

echo "==== All tests completed ====" 