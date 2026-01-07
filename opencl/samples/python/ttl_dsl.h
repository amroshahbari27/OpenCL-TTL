#ifndef TTL_DSL_H
#define TTL_DSL_H

#define TTL_RESTRICT __restrict

// Polygeist mode: pointer to fixed-size array
#define TTL_2D_ARG(name, type, dim0, dim1) type(*TTL_RESTRICT name)[dim0][dim1]
#define TTL_2D_ARG_ACCESS(name, i, j, dim1) (*name)[i][j]

#define TTL_ASSERT_STATIC(expr) _Static_assert((expr), "TTL requires compile-time constant")

#endif  // TTL_DSL_H
