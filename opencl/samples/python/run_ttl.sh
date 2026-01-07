#!/bin/bash

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input_c_file>"
    exit 1
fi

INPUT_FILE=$1
BASE_NAME=$(basename "$INPUT_FILE" .c)

echo "Step 1: Converting C to MLIR..."
~/msc/Polygeist/build/bin/cgeist "$INPUT_FILE" -function=sigmoid -S -memref-fullrank -o "${BASE_NAME}.mlir"

if [ $? -ne 0 ]; then
    echo "Error: C to MLIR conversion failed"
    exit 1
fi

echo "Step 2: Running TTL pipeline optimization..."
~/msc/llvm-project/build/bin/mlir-opt --ttl-pipeline "${BASE_NAME}.mlir" -o "${BASE_NAME}_optimized.mlir"

if [ $? -ne 0 ]; then
    echo "Error: TTL pipeline optimization failed"
    exit 1
fi

echo "Step 3: Converting to C..."
~/msc/llvm-project/build/bin/mlir-translate --mlir-to-cpp "${BASE_NAME}_optimized.mlir" -o "${BASE_NAME}_optimized.c"

if [ $? -ne 0 ]; then
    echo "Error: MLIR to C++ conversion failed"
    exit 1
fi

echo "Pipeline completed successfully!"
echo "Output files:"
echo "- MLIR: ${BASE_NAME}.mlir"
echo "- Optimized MLIR: ${BASE_NAME}_optimized.mlir"
echo "- C: ${BASE_NAME}.c"