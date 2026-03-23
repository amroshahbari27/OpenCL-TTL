/*
 * run_test_ttl_pseudo.cpp
 *
 * Host runner for test_ttl_pseudo.cpp using real TTL headers.
 *
 * Build & run (host/CPU):
 *   clang++ -std=c++17 -O0 -g -I/home/ubuntu/msc -DTTL_TARGET=c \
 *     /home/ubuntu/msc/TTL/opencl/samples/python/run_test_ttl_pseudo.cpp \
 *     /home/ubuntu/msc/TTL/opencl/samples/python/test_ttl_pseudo.cpp \
 *     -o /tmp/run_test_ttl_pseudo && /tmp/run_test_ttl_pseudo
 */

#include <cstdint>
#include <iostream>
#include <chrono>
#include <vector>

/* Ensure we use the real TTL umbrella header, not the shim. */
#ifndef TTL_TARGET
#define TTL_TARGET c
#endif
#include <TTL/TTL.h>

#ifndef TEST_TENSOR_TYPE
#define TEST_TENSOR_TYPE float
#endif

/* From test_ttl_pseudo.cpp */
void ttl_matmul_kernel_pipelined(TEST_TENSOR_TYPE *restrict A, int lda,
                                 TEST_TENSOR_TYPE *restrict B, int ldb,
                                 TEST_TENSOR_TYPE *restrict C, int ldc,
                                 TTL_dim M, TTL_dim N, TTL_dim K,
                                 TTL_dim Mt, TTL_dim Nt, TTL_dim Kt);

void ttl_matmul_kernel_non_pipelined(TEST_TENSOR_TYPE *restrict A, int lda,
                                     TEST_TENSOR_TYPE *restrict B, int ldb,
                                     TEST_TENSOR_TYPE *restrict C, int ldc,
                                     TTL_dim M, TTL_dim N, TTL_dim K,
                                     TTL_dim Mt, TTL_dim Nt, TTL_dim Kt);

int main() {
    /* Use a bigger size so runtime is measurable on CPU. */
    constexpr TTL_dim M = 256;
    constexpr TTL_dim N = 256;
    constexpr TTL_dim K = 256;

    constexpr TTL_dim Mt = 32;
    constexpr TTL_dim Nt = 32;
    constexpr TTL_dim Kt = 32;

    const int lda = (int)K; /* A: MxK row-major */
    const int ldb = (int)N; /* B: KxN row-major */
    const int ldc = (int)N; /* C: MxN row-major */

    std::vector<TEST_TENSOR_TYPE> A((size_t)M * (size_t)K);
    std::vector<TEST_TENSOR_TYPE> B((size_t)K * (size_t)N);
    std::vector<TEST_TENSOR_TYPE> C((size_t)M * (size_t)N);
    std::vector<TEST_TENSOR_TYPE> Ref((size_t)M * (size_t)N);

    for (TTL_dim i = 0; i < M; ++i) {
        for (TTL_dim k = 0; k < K; ++k) {
            A[(size_t)i * (size_t)K + (size_t)k] = (TEST_TENSOR_TYPE)(1 + (i % 7) - (k % 5));
        }
    }
    for (TTL_dim k = 0; k < K; ++k) {
        for (TTL_dim j = 0; j < N; ++j) {
            B[(size_t)k * (size_t)N + (size_t)j] = (TEST_TENSOR_TYPE)(2 + (j % 11) - (k % 3));
        }
    }
    for (TTL_dim i = 0; i < M; ++i) {
        for (TTL_dim j = 0; j < N; ++j) {
            C[(size_t)i * (size_t)N + (size_t)j] = (TEST_TENSOR_TYPE)0;
            TEST_TENSOR_TYPE acc = 0;
            for (TTL_dim k = 0; k < K; ++k) {
                acc = (TEST_TENSOR_TYPE)(acc + A[(size_t)i * (size_t)K + (size_t)k] * B[(size_t)k * (size_t)N + (size_t)j]);
            }
            Ref[(size_t)i * (size_t)N + (size_t)j] = acc;
        }
    }

    auto run_once = [&](auto fn) {
        std::fill(C.begin(), C.end(), (TEST_TENSOR_TYPE)0);
        fn(A.data(), lda, B.data(), ldb, C.data(), ldc, M, N, K, Mt, Nt, Kt);
    };

    /* Correctness check (pipelined). */
    run_once(ttl_matmul_kernel_pipelined);

    bool ok = true;
    for (TTL_dim i = 0; i < M; ++i) {
        for (TTL_dim j = 0; j < N; ++j) {
            const auto expected = Ref[(size_t)i * (size_t)N + (size_t)j];
            const auto got = C[(size_t)i * (size_t)N + (size_t)j];
            if (got != expected) {
                std::cout << "Mismatch at (" << i << "," << j << "): got=" << got << " expected=" << expected << "\n";
                ok = false;
                goto done;
            }
        }
    }

done:
    if (!ok) {
        std::cout << "FAIL" << std::endl;
        return 1;
    }

    /* Benchmark */
    constexpr int iters = 3;
    auto time_fn = [&](const char *name, auto fn) {
        using clock = std::chrono::high_resolution_clock;
        std::chrono::duration<double> total{0};
        for (int it = 0; it < iters; ++it) {
            std::fill(C.begin(), C.end(), (TEST_TENSOR_TYPE)0);
            auto t0 = clock::now();
            fn(A.data(), lda, B.data(), ldb, C.data(), ldc, M, N, K, Mt, Nt, Kt);
            auto t1 = clock::now();
            total += (t1 - t0);
        }
        std::cout << name << ": " << (total.count() / iters) << " s (avg over " << iters << ")\n";
    };

    time_fn("non_pipelined", ttl_matmul_kernel_non_pipelined);
    time_fn("pipelined", ttl_matmul_kernel_pipelined);

    std::cout << "PASS" << std::endl;
    return 0;
}

