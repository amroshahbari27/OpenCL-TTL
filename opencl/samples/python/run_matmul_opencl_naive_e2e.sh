#!/usr/bin/env bash
set -euo pipefail

# End-to-end demo (naive OpenCL-ish matmul input -> MLIR tiling -> TTL-style OpenCL kernel):
# - Input: `matmul_opencl_naive.c` (includes TTL/TTL.h shim + `#pragma TTLtile`)
# - Ingress: Polygeist (cgeist)
# - Transform/Egress: mlir-opt --ttl-pipeline=backend=opencl + mlir-translate --mlir-to-cpp
# - Run: PyOpenCL correctness check

ROOT="/home/ubuntu/msc"
SAMPLES="${ROOT}/TTL/opencl/samples/python"

CGIEST="${ROOT}/Polygeist/build/bin/cgeist"
MLIR_OPT="${ROOT}/llvm-project/build/bin/mlir-opt"
MLIR_TRANSLATE="${ROOT}/llvm-project/build/bin/mlir-translate"

IN_C="${SAMPLES}/matmul_opencl_naive.c"
OUT_MLIR_INGRESS="/tmp/matmul_opencl_naive_ingress.mlir"
OUT_MLIR_OPENCL="/tmp/matmul_opencl_naive_opencl.mlir"
OUT_CL="/tmp/matmul_opencl_naive_opencl.cl"

echo "[1/4] Ingress (C/OpenCL-ish -> MLIR via Polygeist)"
# Force the TTL/TTL.h shim into a self-contained ingress mode (no libc headers).
"${CGIEST}" -DTTL_INGRESS_C=1 -I"${SAMPLES}" -O0 -S "${IN_C}" -o "${OUT_MLIR_INGRESS}"

echo "[2/4] Tile + OpenCL backend (MLIR -> MLIR)"
"${MLIR_OPT}" "${OUT_MLIR_INGRESS}" --ttl-pipeline=backend=opencl --verify-each=false -o "${OUT_MLIR_OPENCL}"

echo "[3/4] Emit OpenCL C (MLIR -> C/OpenCL-like C)"
"${MLIR_TRANSLATE}" --mlir-to-cpp "${OUT_MLIR_OPENCL}" -o "${OUT_CL}"

echo "[4/4] Build+run (PyOpenCL)"
export TTL_MATMUL_OPENCL_NAIVE_CL="${OUT_CL}"
python3 "${SAMPLES}/matmul_opencl_naive_runner.py"

