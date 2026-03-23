# TTL × Polygeist × MLIR — Thesis Verification Notes (OpenCL/Python Samples)

This README explains **why** the additional files in `opencl/samples/python/` were created, **what** each file is for, and **how** to verify that the workflow is correct. It is written in the context of the thesis:

> **Leveraging Structured OpenCL C Extensions and MLIR to Optimize Multi-Dimensional Data with Tiling**

The thesis motivation is that **C/OpenCL C lose high-level structure** when lowered to LLVM IR, and that **TTL expresses tiling/DMA structure** but is still manual. We want:

- **Ingress**: bring C/C++ code into MLIR using **Polygeist**, while **preserving TTL intent** as explicit operations/calls we can analyze/transform.
- **Execution sanity**: ensure the “same logic” can still **compile and run** against the real TTL implementation.
- **Performance sanity**: demonstrate the performance difference between:
  - **naive** (no tiling, no pipelining)
  - **tiled non-pipelined**
  - **tiled pipelined**

---

## Files Added/Modified and Why They Exist

### `opencl/samples/python/TTL/TTL.h`
**Purpose**: a **dual-use header** that makes the project work for both:

- **OpenCL C compilation** of `.cl` kernels in this folder, and
- **C++ Polygeist parsing** of TTL-style C++ code.

**How it works**:

- **When compiling OpenCL C** (`__OPENCL_C_VERSION__` is defined): this header uses:
  - `#include_next "TTL/TTL.h"`
  so the OpenCL compiler pulls in the **real TTL headers** from `TTL_INCLUDE_PATH` (not the shim).

- **When compiling C++ (Polygeist ingress)**: it provides a **declarations-only C++ shim** for the TTL C++ API (types + function declarations, no implementations). This allows Polygeist/Clang to parse TTL constructs and emit them as calls/structured IR.

**Why this matters for the thesis**:
- This is the core “bridge” that makes TTL **expressible and preserved** at the MLIR ingress boundary without requiring full TTL compilation during Polygeist.

---

### `opencl/samples/python/test_ttl_pseudo.cpp`
**Purpose**: a **C++ matmul** example that:

- is rich enough to represent **tile-based IO + compute**,
- can **run** on host using TTL’s C backend (`TTL_TARGET=c`) for correctness sanity,
- can be **parsed by Polygeist** using the shim header to produce MLIR with explicit TTL calls.

**Kernels implemented**:
- **`ttl_matmul_kernel_pipelined`**: tiled GEMM with **double-buffered import** of A/B and **export double buffering** for C.
- **`ttl_matmul_kernel_non_pipelined`**: tiled GEMM with **blocking imports/exports** (no overlap).

**Why this matters for the thesis**:
- This is the primary “ingress artifact”: Polygeist should see explicit tiling/pipelining structure that MLIR passes can analyze and optimize.

---

### `opencl/samples/python/run_test_ttl_pseudo.cpp`
**Purpose**: host runner for `test_ttl_pseudo.cpp` that:

- checks correctness against a reference GEMM, and
- times **non_pipelined vs pipelined** for `TTL_TARGET=c`.

**Why this matters**:
- This validates the logic and provides a baseline timing on a CPU backend. It does not prove real DMA overlap (see note below), but it ensures the code is correct and structured.

---

### `opencl/samples/python/TTL_matmul_compare.cl`
**Purpose**: OpenCL C kernel file that **runs on an OpenCL runtime** (PyOpenCL), and contains three versions:

- **`matmul_naive`**: *no tiling, no pipelining* (baseline).
- **`TTL_matmul_non_pipelined`**: *tiled, but import/export are waited each step* (no buffering overlap).
- **`TTL_matmul_pipelined`**: *tiled + pipelined* (double buffering for A/B imports + export double buffering for C).

**Important**:
- This file uses `TEST_TENSOR_TYPE=int` because TTL’s generated typed tensors include `int` (and many other integer types) by default.

**Why this matters for the thesis**:
- This is the closest artifact to “real OpenCL-side semantics”: events, async copies, and local memory. It helps validate the “DMA/pipeline” story in an execution environment.

---

### `opencl/samples/python/TTL_matmul_compare_runner.py`
**Purpose**: build/run/benchmark the OpenCL kernels in `TTL_matmul_compare.cl` using PyOpenCL.

It:
- builds with TTL headers via `TTL_INCLUDE_PATH`,
- validates correctness against NumPy `A @ B`,
- reports profiling-based timings for the three kernels.

---

### `opencl/samples/python/ttl_pseudo_ops.h`
**Purpose**: a **C-style declarations-only TTL shim** (types + function prototypes) useful for alternate experiments where you want the TTL C API (not C++) to be parseable without pulling real TTL headers.

**Status**: not strictly required for the current “C++ Polygeist ingress” flow (since `TTL/TTL.h` dual-use shim covers that), but kept as a useful tool for future DSL experiments.

---

## Verification Checklist (Commands + What They Prove)

These checks ensure correctness of the “shim + real TTL + OpenCL runtime” story.

### 0) End-to-end: OpenCL-ish naive matmul (with `#pragma TTLtile`) → MLIR tiling → TTL non-pipelined OpenCL kernel
**Input**: `opencl/samples/python/matmul_opencl_naive.c`

**Command**:

```bash
cd /home/ubuntu/msc/TTL/opencl/samples/python
./run_matmul_opencl_naive_e2e.sh
```

**What it proves**:
- **Ingress**: Polygeist ingresses a kernel-like C file that includes `opencl/samples/python/TTL/TTL.h` (shim) and uses `#pragma TTLtile`.
- **Transform**: the MLIR pipeline rewrites the naive matmul into a **TTL-style tiled kernel** (non-pipelined) using:
  - `TTL_create_shape`, `TTL_create_layout`, `TTL_create_tiler`, `TTL_create_tile` / `TTL_get_tile`
  - `TTL_import` + `TTL_wait` (A/B)
  - local buffers (`__local`) and `TTL_read_tensor` / `TTL_write_tensor` for compute
  - `TTL_export` + `TTL_wait` (C)
- **Egress + Run**: the generated OpenCL C builds and runs under PyOpenCL and matches NumPy reference.

**Expected structure**:
- The generated kernel is intended to match the non‑pipelined reference structure shown in `opencl/samples/python/TTL_matmul_compare.cl` (`TTL_matmul_non_pipelined`).

### 1) Polygeist-style parse (C++)
**Command**:

```bash
clang++ -std=c++17 \
  -I/home/ubuntu/msc/TTL/opencl/samples/python \
  -DTEST_TENSOR_TYPE=float \
  -fsyntax-only /home/ubuntu/msc/TTL/opencl/samples/python/test_ttl_pseudo.cpp
```

**What it proves**:
- The shim header `opencl/samples/python/TTL/TTL.h` is sufficient for C++ parsing (Polygeist ingress).

---

### 2) Real TTL parse (host, TTL_TARGET=c)
**Command**:

```bash
clang++ -std=c++17 \
  -I/home/ubuntu/msc \
  -DTTL_TARGET=c \
  -DTEST_TENSOR_TYPE=float \
  -fsyntax-only /home/ubuntu/msc/TTL/opencl/samples/python/test_ttl_pseudo.cpp
```

**What it proves**:
- The same C++ code can be compiled against the real TTL umbrella header `TTL.h` (which picks `TTL_cpp`), using the host-friendly `TTL_TARGET=c`.

---

### 3) Real TTL host run (benchmark runner)
**Command**:

```bash
clang++ -std=c++17 -O3 -march=native \
  -I/home/ubuntu/msc \
  -DTTL_TARGET=c \
  /home/ubuntu/msc/TTL/opencl/samples/python/run_test_ttl_pseudo.cpp \
  /home/ubuntu/msc/TTL/opencl/samples/python/test_ttl_pseudo.cpp \
  -o /tmp/run_test_ttl_pseudo && /tmp/run_test_ttl_pseudo
```

**What it proves**:
- Correctness (matches reference).
- Timings for pipelined vs non-pipelined exist and are comparable.

**Note**:
- On `TTL_TARGET=c`, “events/DMA” are modeled by CPU copies; overlap benefits can be small. This is expected.

---

### 4) OpenCL runner (PyOpenCL build+run)
**Command**:

```bash
cd /home/ubuntu/msc/TTL/opencl/samples/python
TTL_INCLUDE_PATH=/home/ubuntu/msc python3 TTL_matmul_compare_runner.py
```

**What it proves**:
- The OpenCL C kernels compile against real TTL headers (the shim does not break OpenCL compilation because it uses `#include_next` under `__OPENCL_C_VERSION__`).
- Correctness vs NumPy `@`.
- Timings for:
  - **naive**
  - **tiled non-pipelined**
  - **tiled pipelined**

**Note**:
- In this environment the OpenCL device is **PoCL CPU**, so DMA overlap benefits are limited; a GPU OpenCL device would typically show a larger gap.

---

### 5) Extra check: original TTL C++ sample still parses with shim include path
**Command**:

```bash
clang++ -std=c++17 \
  -I/home/ubuntu/msc/TTL/opencl/samples/python \
  -I/home/ubuntu/msc/TTL/cpp/samples \
  -DTEST_TENSOR_TYPE=float \
  -DTEST_COMPUTE_TYPE=CROSS \
  -DKERNEL_NAME=TTL_double_buffering_kernel \
  -fsyntax-only /home/ubuntu/msc/TTL/cpp/samples/TTL_double_buffering.cpp
```

**What it proves**:
- The shim is sufficiently faithful to parse existing TTL C++ sample code (important for ingesting real-world TTL usage patterns).

---

## How This Fits the Thesis Pipeline

- **TTL expresses tiling + DMA/pipelining** at the source level.
- **Polygeist** is the practical ingress path from C/C++ to MLIR.
- The **dual-use shim** ensures TTL constructs remain visible at ingress as **explicit operations/calls** instead of being erased.
- The OpenCL kernel comparison validates the **execution-side effect** of tiling/pipelining under an OpenCL runtime.

