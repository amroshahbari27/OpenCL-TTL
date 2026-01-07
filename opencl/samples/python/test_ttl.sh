#!/bin/bash

# Path to the MLIR file
MLIR_FILE="test_ttl.mlir"

# Run mlir-opt with the TTL dialect
echo "Testing TTL dialect with mlir-opt..."
~/msc/llvm-project/build/bin/mlir-opt $MLIR_FILE --allow-unregistered-dialect

# If you want to verify the dialect is registered
echo -e "\nVerifying TTL dialect registration..."
~/msc/llvm-project/build/bin/mlir-opt  $MLIR_FILE --allow-unregistered-dialect --verify-diagnostics 