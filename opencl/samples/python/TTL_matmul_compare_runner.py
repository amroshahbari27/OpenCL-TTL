#!/usr/bin/python3
"""
TTL_matmul_compare_runner.py

Builds and runs the OpenCL kernels in TTL_matmul_compare.cl using PyOpenCL and
prints runtime for:
  - TTL_matmul_non_pipelined
  - TTL_matmul_pipelined

This environment uses PoCL (CPU OpenCL). You should still see the structure,
but DMA overlap benefits may be limited on CPU devices.
"""

import os
import numpy as np
import pyopencl as cl


def build_program(ctx, filename: str) -> cl.Program:
    os.environ["PYOPENCL_COMPILER_OUTPUT"] = "1"
    os.environ["PYOPENCL_NO_CACHE"] = "1"

    ttl_include = os.environ.get("TTL_INCLUDE_PATH", "/home/ubuntu/msc")
    include_opt = f"-I{ttl_include}"

    # local mem size for TTL scripts
    local_mem = min(d.get_info(cl.device_info.LOCAL_MEM_SIZE) for d in ctx.devices)

    extra = os.environ.get("TTL_EXTRA_DEFINES", "")

    # Tile-size heuristics / overrides
    tile_m = int(os.environ.get("TILE_M", "64"))
    tile_n = int(os.environ.get("TILE_N", str(tile_m)))
    tile_k = int(os.environ.get("TILE_K", str(tile_m)))

    # Estimate local memory use (bytes) for pipelined kernel:
    # A0/A1 + B0/B1 + C0/C1
    elem_size = np.dtype(np.int32).itemsize
    est_bytes = elem_size * (
        2 * tile_m * tile_k +
        2 * tile_k * tile_n +
        2 * tile_m * tile_n
    )
    if est_bytes > int(local_mem):
        # Fall back conservatively if overrides are too large.
        tile_m = tile_n = tile_k = 32

    opts = (
        f"{include_opt} {extra} "
        f"-DTTL_COPY_3D "
        f"-DTEST_TENSOR_TYPE=int "
        f"-DLOCAL_MEMORY_SIZE={int(local_mem)} "
        f"-DTILE_M={tile_m} -DTILE_N={tile_n} -DTILE_K={tile_k}"
    )

    src = open(filename, "r", encoding="utf-8").read()
    return cl.Program(ctx, src).build(options=opts)


def gemm_ref(A: np.ndarray, B: np.ndarray) -> np.ndarray:
    # A: MxK, B: KxN
    return A @ B


def run_kernel(queue, kernel, A_buf, B_buf, C_buf, M, N, K, lda, ldb, ldc):
    evt = kernel(
        queue,
        (1,),
        None,
        A_buf,
        np.int32(lda),
        B_buf,
        np.int32(ldb),
        C_buf,
        np.int32(ldc),
        np.int32(M),
        np.int32(N),
        np.int32(K),
    )
    evt.wait()
    # profiling in ns
    return (evt.profile.end - evt.profile.start) * 1e-6  # ms


def main():
    platforms = cl.get_platforms()
    ctx = cl.Context(dev_type=cl.device_type.ALL, properties=[(cl.context_properties.PLATFORM, platforms[0])])
    queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)

    program_path = os.path.join(os.path.dirname(__file__), "TTL_matmul_compare.cl")
    prg = build_program(ctx, program_path)

    # Sizes:
    # - Correctness: smaller (full numpy ref)
    # - Performance: bigger (subset check only, for speed)
    Mc = int(os.environ.get("M_CHECK", "128"))
    Nc = int(os.environ.get("N_CHECK", str(Mc)))
    Kc = int(os.environ.get("K_CHECK", str(Mc)))

    Mp = int(os.environ.get("M_PERF", "768"))
    Np = int(os.environ.get("N_PERF", str(Mp)))
    Kp = int(os.environ.get("K_PERF", str(Mp)))

    print("OpenCL device:", ctx.devices[0].name)
    print("LOCAL_MEM_SIZE:", int(ctx.devices[0].get_info(cl.device_info.LOCAL_MEM_SIZE)))

    rng = np.random.default_rng(0)
    # -------- Correctness run --------
    M, N, K = Mc, Nc, Kc
    lda, ldb, ldc = K, N, N

    A = rng.integers(low=-3, high=4, size=(M, K), dtype=np.int32)
    B = rng.integers(low=-3, high=4, size=(K, N), dtype=np.int32)
    C = np.zeros((M, N), dtype=np.int32)

    # Reference
    ref = gemm_ref(A, B)

    mf = cl.mem_flags
    A_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=A)
    B_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=B)
    C_buf = cl.Buffer(ctx, mf.READ_WRITE, size=C.nbytes)

    # Warmup
    cl.enqueue_copy(queue, C_buf, C)
    prg.matmul_naive(queue, (1,), None, A_buf, np.int32(lda), B_buf, np.int32(ldb), C_buf, np.int32(ldc),
                     np.int32(M), np.int32(N), np.int32(K)).wait()

    # Correctness (non_pipelined)
    cl.enqueue_copy(queue, C_buf, C)
    prg.TTL_matmul_non_pipelined(queue, (1,), None, A_buf, np.int32(lda), B_buf, np.int32(ldb), C_buf, np.int32(ldc),
                                 np.int32(M), np.int32(N), np.int32(K)).wait()
    cl.enqueue_copy(queue, C, C_buf).wait()
    max_err = np.max(np.abs(C - ref))
    print("non_pipelined max|err|:", int(max_err))

    # Correctness (pipelined)
    C.fill(0)
    cl.enqueue_copy(queue, C_buf, C)
    prg.TTL_matmul_pipelined(queue, (1,), None, A_buf, np.int32(lda), B_buf, np.int32(ldb), C_buf, np.int32(ldc),
                             np.int32(M), np.int32(N), np.int32(K)).wait()
    cl.enqueue_copy(queue, C, C_buf).wait()
    max_err2 = np.max(np.abs(C - ref))
    print("pipelined max|err|:", int(max_err2))

    if not (max_err == 0 and max_err2 == 0):
        raise SystemExit("FAIL: incorrect result")

    # -------- Performance run --------
    M, N, K = Mp, Np, Kp
    lda, ldb, ldc = K, N, N

    A = rng.integers(low=-3, high=4, size=(M, K), dtype=np.int32)
    B = rng.integers(low=-3, high=4, size=(K, N), dtype=np.int32)
    C = np.zeros((M, N), dtype=np.int32)

    A_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=A)
    B_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=B)
    C_buf = cl.Buffer(ctx, mf.READ_WRITE, size=C.nbytes)

    iters = int(os.environ.get("ITERS", "3"))
    times_naive = []
    times_np = []
    times_p = []

    for _ in range(iters):
        C.fill(0)
        cl.enqueue_copy(queue, C_buf, C).wait()
        times_naive.append(run_kernel(queue, prg.matmul_naive, A_buf, B_buf, C_buf, M, N, K, lda, ldb, ldc))

        C.fill(0)
        cl.enqueue_copy(queue, C_buf, C).wait()
        times_np.append(run_kernel(queue, prg.TTL_matmul_non_pipelined, A_buf, B_buf, C_buf, M, N, K, lda, ldb, ldc))

        C.fill(0)
        cl.enqueue_copy(queue, C_buf, C).wait()
        times_p.append(run_kernel(queue, prg.TTL_matmul_pipelined, A_buf, B_buf, C_buf, M, N, K, lda, ldb, ldc))

    print(f"naive:          {np.mean(times_naive):.3f} ms (avg {iters})")
    print(f"non_pipelined: {np.mean(times_np):.3f} ms (avg {iters})")
    print(f"pipelined:     {np.mean(times_p):.3f} ms (avg {iters})")

    print("PASS")


if __name__ == "__main__":
    main()

