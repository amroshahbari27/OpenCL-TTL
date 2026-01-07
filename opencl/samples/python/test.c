#include "ttl_dsl.h"
#include <math.h>
#define M 64U
#define N 128U

TTL_ASSERT_STATIC(M > 0);
TTL_ASSERT_STATIC(N > 0);

void sigmoid(
  TTL_2D_ARG(tensor_in, float, M, N),
  TTL_2D_ARG(tensor_out, float, M, N)
) {
#if !TTL_MODE
  #pragma TTLtile(4, 4)
#endif
  for (unsigned i = 0; i < M; ++i) {
    for (unsigned j = 0; j < N; ++j) {
      TTL_2D_ARG_ACCESS(tensor_out, i, j, N) =
        1.0f / (1.0f + exp(-TTL_2D_ARG_ACCESS(tensor_in, i, j, N)));
    }
  }
#if !TTL_MODE
  #pragma endTTLtile
#endif
}
