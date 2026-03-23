import os
import numpy as np
import pyopencl as cl


def main() -> None:
    base = os.path.dirname(__file__)
    src_path = os.environ.get(
        "TTL_MATMUL_OPENCL_NAIVE_CL",
        os.path.join(base, "matmul_opencl_naive_opencl.cl"),
    )
    src = open(src_path, "r", encoding="utf-8").read()

    ctx = cl.create_some_context(interactive=False)
    queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
    dev = ctx.devices[0]
    print("Device:", dev.name)
    print("OpenCL C:", dev.opencl_c_version)

    # TTL headers are pulled via `#include_next "TTL/TTL.h"` during OpenCL compilation.
    opts = "-I/home/ubuntu/msc -DTTL_COPY_3D"
    prg = cl.Program(ctx, src).build(options=opts)

    # Use non-square sizes to match the TTL_matmul_compare story.
    M, N, K = 64, 128, 64
    lda, ldb, ldc = K, N, N

    rng = np.random.default_rng(0)
    A = rng.integers(-3, 4, size=(M, K), dtype=np.int32)
    B = rng.integers(-3, 4, size=(K, N), dtype=np.int32)
    C = np.zeros((M, N), dtype=np.int32)

    mf = cl.mem_flags
    A_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=A)
    B_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=B)
    C_buf = cl.Buffer(ctx, mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf=C)

    # The backend should rewrite `matmul_naive` into `TTL_matmul_non_pipelined`.
    # (single-work-item kernel that loops internally)
    evt = prg.TTL_matmul_non_pipelined(queue, (1,), (1,),
                                       A_buf, np.int32(lda),
                                       B_buf, np.int32(ldb),
                                       C_buf, np.int32(ldc),
                                       np.int32(M), np.int32(N), np.int32(K))
    evt.wait()
    cl.enqueue_copy(queue, C, C_buf).wait()

    C_ref = (A.astype(np.int64) @ B.astype(np.int64)).astype(np.int32)
    if not np.array_equal(C, C_ref):
        diff = np.max(np.abs(C.astype(np.int64) - C_ref.astype(np.int64)))
        raise SystemExit(f"FAIL: mismatch vs reference (max abs diff={diff})")

    t_ms = (evt.profile.end - evt.profile.start) / 1e6
    print("kernel_time_ms:", t_ms)
    print("PASS")


if __name__ == "__main__":
    main()

