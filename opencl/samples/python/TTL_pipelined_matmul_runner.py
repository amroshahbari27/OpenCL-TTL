#!/usr/bin/env python3
"""
TTL_pipelined_matmul_runner.py

Builds and runs the three OpenCL matmul kernels in TTL_pipelined_matmul.cl:
  1) matmul_naive            - No tiling at all, raw global memory.
  2) matmul_tiled_blocking   - TTL tiled but blocking imports (no DMA overlap).
  3) matmul_tiled_pipelined  - TTL double-buffered import + export (full overlap).

Correctness is verified against numpy's matmul (exact for int32).
Performance is measured with OpenCL kernel profiling.

Environment variables:
  TTL_INCLUDE_PATH  - Path containing TTL/ directory (default: /home/ubuntu/msc)
  TILE_M/N/K        - Tile dimensions (default: 64)
  M_CHECK/N/K       - Dimensions for correctness run (default: 128)
  M_PERF/N/K        - Dimensions for performance run (default: 512)
  ITERS             - Number of performance iterations (default: 5)
"""

import os
import sys
import time
import numpy as np
import pyopencl as cl


def build_program(ctx, filename, tile_m, tile_n, tile_k):
    """Compile the OpenCL kernel file with TTL includes and tile-size defines."""
    os.environ["PYOPENCL_COMPILER_OUTPUT"] = "1"
    os.environ["PYOPENCL_NO_CACHE"] = "1"

    ttl_include = os.environ.get("TTL_INCLUDE_PATH", "/home/ubuntu/msc")

    local_mem = min(
        d.get_info(cl.device_info.LOCAL_MEM_SIZE) for d in ctx.devices
    )

    extra = os.environ.get("TTL_EXTRA_DEFINES", "")

    # Verify tile sizes fit in local memory:
    # pipelined needs 2*(M*K + K*N + M*N) * elem_size bytes
    elem_size = np.dtype(np.int32).itemsize
    needed = elem_size * 2 * (tile_m * tile_k + tile_k * tile_n + tile_m * tile_n)
    if needed > int(local_mem):
        # Reduce tile size to fit
        old = (tile_m, tile_n, tile_k)
        tile_m = tile_n = tile_k = 32
        print(f"WARNING: tile size {old} needs {needed} bytes but LOCAL_MEM_SIZE={local_mem},"
              f" falling back to ({tile_m},{tile_n},{tile_k})")

    opts = (
        f"-I{ttl_include} {extra} "
        f"-DTTL_COPY_3D "
        f"-DTEST_TENSOR_TYPE=int "
        f"-DLOCAL_MEMORY_SIZE={int(local_mem)} "
        f"-DTILE_M={tile_m} -DTILE_N={tile_n} -DTILE_K={tile_k}"
    )

    src = open(filename, "r", encoding="utf-8").read()
    prg = cl.Program(ctx, src).build(options=opts)
    return prg, tile_m, tile_n, tile_k


def run_kernel(queue, kernel, A_buf, B_buf, C_buf, M, N, K, lda, ldb, ldc):
    """Execute a kernel once and return elapsed time in ms (from profiling)."""
    evt = kernel(
        queue, (1,), None,
        A_buf, np.int32(lda),
        B_buf, np.int32(ldb),
        C_buf, np.int32(ldc),
        np.int32(M), np.int32(N), np.int32(K),
    )
    evt.wait()
    return (evt.profile.end - evt.profile.start) * 1e-6  # ns -> ms


def verify_kernel(queue, kernel, ctx, A, B, ref, name, M, N, K, lda, ldb, ldc):
    """Run one kernel, read back C, compare to reference. Returns True if ok."""
    mf = cl.mem_flags
    A_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=A)
    B_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=B)
    C = np.zeros((M, N), dtype=np.int32)
    C_buf = cl.Buffer(ctx, mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf=C)

    kernel(
        queue, (1,), None,
        A_buf, np.int32(lda),
        B_buf, np.int32(ldb),
        C_buf, np.int32(ldc),
        np.int32(M), np.int32(N), np.int32(K),
    ).wait()

    cl.enqueue_copy(queue, C, C_buf).wait()
    max_err = int(np.max(np.abs(C.astype(np.int64) - ref.astype(np.int64))))
    ok = max_err == 0
    status = "PASS" if ok else "FAIL"
    print(f"  {name:30s} max|err| = {max_err}  [{status}]")
    if not ok:
        # Show first mismatch for debugging
        diff = np.abs(C.astype(np.int64) - ref.astype(np.int64))
        idx = np.unravel_index(np.argmax(diff), diff.shape)
        print(f"    First mismatch at {idx}: got {C[idx]}, expected {ref[idx]}")
    return ok


def benchmark_kernel(queue, kernel, ctx, A, B, M, N, K, lda, ldb, ldc, iters):
    """Run a kernel `iters` times, return (mean_ms, min_ms, max_ms)."""
    mf = cl.mem_flags
    A_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=A)
    B_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=B)
    C = np.zeros((M, N), dtype=np.int32)
    C_buf = cl.Buffer(ctx, mf.READ_WRITE, size=C.nbytes)

    times = []
    for _ in range(iters):
        # Zero C each iteration
        cl.enqueue_copy(queue, C_buf, C).wait()
        t = run_kernel(queue, kernel, A_buf, B_buf, C_buf, M, N, K, lda, ldb, ldc)
        times.append(t)

    return np.mean(times), np.min(times), np.max(times)


def main():
    # ---- Setup OpenCL ----
    platforms = cl.get_platforms()
    ctx = cl.Context(
        dev_type=cl.device_type.ALL,
        properties=[(cl.context_properties.PLATFORM, platforms[0])],
    )
    queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
    dev = ctx.devices[0]

    print("=" * 70)
    print("TTL Pipelined Matmul Benchmark")
    print("=" * 70)
    print(f"Device:         {dev.name}")
    print(f"LOCAL_MEM_SIZE: {dev.get_info(cl.device_info.LOCAL_MEM_SIZE)} bytes")

    # ---- Parameters ----
    tile_m = int(os.environ.get("TILE_M", "64"))
    tile_n = int(os.environ.get("TILE_N", str(tile_m)))
    tile_k = int(os.environ.get("TILE_K", str(tile_m)))

    Mc = int(os.environ.get("M_CHECK", "128"))
    Nc = int(os.environ.get("N_CHECK", str(Mc)))
    Kc = int(os.environ.get("K_CHECK", str(Mc)))

    Mp = int(os.environ.get("M_PERF", "512"))
    Np = int(os.environ.get("N_PERF", str(Mp)))
    Kp = int(os.environ.get("K_PERF", str(Mp)))

    iters = int(os.environ.get("ITERS", "5"))

    # ---- Build ----
    kernel_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                               "TTL_pipelined_matmul.cl")
    prg, tile_m, tile_n, tile_k = build_program(ctx, kernel_path, tile_m, tile_n, tile_k)

    print(f"Tile size:      {tile_m} x {tile_n} x {tile_k}")
    print()

    # ---- Correctness ----
    print(f"--- Correctness check ({Mc} x {Nc} x {Kc}) ---")
    rng = np.random.default_rng(42)
    A = rng.integers(-3, 4, size=(Mc, Kc), dtype=np.int32)
    B = rng.integers(-3, 4, size=(Kc, Nc), dtype=np.int32)
    ref = (A.astype(np.int64) @ B.astype(np.int64)).astype(np.int32)

    lda, ldb, ldc = Kc, Nc, Nc

    kernels = [
        ("matmul_naive", prg.matmul_naive),
        ("matmul_tiled_blocking", prg.matmul_tiled_blocking),
        ("matmul_tiled_pipelined", prg.matmul_tiled_pipelined),
    ]

    all_ok = True
    for name, kern in kernels:
        ok = verify_kernel(queue, kern, ctx, A, B, ref, name, Mc, Nc, Kc, lda, ldb, ldc)
        all_ok = all_ok and ok

    if not all_ok:
        print("\nFAIL: correctness errors detected!")
        sys.exit(1)

    # Also test non-square to catch edge-case tiling bugs
    print(f"\n--- Correctness check (non-square: {Mc+7} x {Nc+13} x {Kc+3}) ---")
    M2, N2, K2 = Mc + 7, Nc + 13, Kc + 3
    A2 = rng.integers(-3, 4, size=(M2, K2), dtype=np.int32)
    B2 = rng.integers(-3, 4, size=(K2, N2), dtype=np.int32)
    ref2 = (A2.astype(np.int64) @ B2.astype(np.int64)).astype(np.int32)

    for name, kern in kernels:
        ok = verify_kernel(queue, kern, ctx, A2, B2, ref2, name, M2, N2, K2, K2, N2, N2)
        all_ok = all_ok and ok

    if not all_ok:
        print("\nFAIL: correctness errors on non-square!")
        sys.exit(1)

    print("\nAll correctness checks PASSED!")

    # ---- Performance ----
    print(f"\n--- Performance benchmark ({Mp} x {Np} x {Kp}, {iters} iterations) ---")
    A_p = rng.integers(-3, 4, size=(Mp, Kp), dtype=np.int32)
    B_p = rng.integers(-3, 4, size=(Kp, Np), dtype=np.int32)
    lda_p, ldb_p, ldc_p = Kp, Np, Np

    # Warmup
    mf = cl.mem_flags
    A_buf_w = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=A_p)
    B_buf_w = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=B_p)
    C_w = np.zeros((Mp, Np), dtype=np.int32)
    C_buf_w = cl.Buffer(ctx, mf.READ_WRITE, size=C_w.nbytes)
    for _, kern in kernels:
        cl.enqueue_copy(queue, C_buf_w, C_w).wait()
        run_kernel(queue, kern, A_buf_w, B_buf_w, C_buf_w, Mp, Np, Kp, lda_p, ldb_p, ldc_p)

    # Also time numpy for reference
    np_times = []
    for _ in range(iters):
        t0 = time.perf_counter()
        _ = A_p @ B_p
        np_times.append((time.perf_counter() - t0) * 1000.0)

    results = {}
    for name, kern in kernels:
        mean, mn, mx = benchmark_kernel(
            queue, kern, ctx, A_p, B_p, Mp, Np, Kp, lda_p, ldb_p, ldc_p, iters
        )
        results[name] = (mean, mn, mx)

    # ---- Print results ----
    flops = 2.0 * Mp * Np * Kp  # multiply-add = 2 flops per element
    print()
    print(f"{'Kernel':30s} {'Mean ms':>10s} {'Min ms':>10s} {'Max ms':>10s} {'MFLOPS':>10s} {'Speedup':>10s}")
    print("-" * 82)

    np_mean = np.mean(np_times)
    print(f"{'numpy (host)':30s} {np_mean:10.3f} {np.min(np_times):10.3f} {np.max(np_times):10.3f} "
          f"{flops / np_mean / 1e3:10.1f} {'(ref)':>10s}")

    naive_mean = results["matmul_naive"][0]
    for name in ["matmul_naive", "matmul_tiled_blocking", "matmul_tiled_pipelined"]:
        mean, mn, mx = results[name]
        mflops = flops / mean / 1e3  # ms -> s
        speedup = naive_mean / mean
        print(f"{name:30s} {mean:10.3f} {mn:10.3f} {mx:10.3f} {mflops:10.1f} {speedup:10.2f}x")

    print()
    speedup_pipe_vs_naive = naive_mean / results["matmul_tiled_pipelined"][0]
    speedup_pipe_vs_blocking = results["matmul_tiled_blocking"][0] / results["matmul_tiled_pipelined"][0]
    print(f"Pipelined vs naive:    {speedup_pipe_vs_naive:.2f}x speedup")
    print(f"Pipelined vs blocking: {speedup_pipe_vs_blocking:.2f}x speedup")
    print()
    print("PASS")


if __name__ == "__main__":
    main()
