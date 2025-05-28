#!/bin/bash

# Check if filename argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    echo "Example: $0 simple_add"
    exit 1
fi

# Get the filename without extension
filename=$1
base_name=$(basename "$filename" .cl)

# Run clang to generate LLVM IR
echo "Generating LLVM IR..."
clang-18 -cl-std=CL2.0 -Xclang -cl-std=CL2.0 \
    -Dcl_clang_storage_class_specifiers \
    -DTEST_TENSOR_TYPE=int \
    -DTTL_COPY_3D \
    -target spir64-unknown-unknown \
    -fno-inline \
    -emit-llvm -S \
    "${filename}" \
    -o "${base_name}.ll" \
    -I/home/ubuntu/msc

# Check if clang succeeded
if [ $? -ne 0 ]; then
    echo "Error: clang failed to generate LLVM IR"
    exit 1
fi

# Run mlir-translate to convert LLVM IR to MLIR
echo "Converting to MLIR..."
~/msc/llvm-project/build/bin/mlir-translate \
    --import-llvm "${base_name}.ll" \
    -o "${base_name}.mlir"

# Check if mlir-translate succeeded
if [ $? -ne 0 ]; then
    echo "Error: mlir-translate failed"
    exit 1
fi

# Run mlir-opt with ttl-ops pass
echo "Running TTL analysis..."
~/msc/llvm-project/install/bin/mlir-opt \
    --ttl-ops "${base_name}.mlir" \
    &> dump.mlir

# Check if mlir-opt succeeded
if [ $? -ne 0 ]; then
    echo "Error: mlir-opt failed"
    exit 1
fi

echo "Analysis complete! Results are in dump.mlir" 