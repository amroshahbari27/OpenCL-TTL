/*
 * TTL/TTL.h (dual-use shim)
 *
 * Goal:
 * - For OpenCL C compilation (PyOpenCL/clang): DO NOT shadow the real TTL headers.
 *   We forward to the next TTL/TTL.h on the include path using #include_next.
 *
 * - For C++ Polygeist ingestion: Provide a declarations-only C++ surface so
 *   Polygeist can parse code using TTL C++ API.
 *
 * IMPORTANT:
 * - This file lives under opencl/samples/python/TTL/TTL.h because many OpenCL
 *   kernels in this folder do `#include "TTL/TTL.h"` and the compiler searches
 *   the current directory first.
 * - The __OPENCL_C_VERSION__ branch ensures OpenCL compilation still uses the
 *   real TTL implementation headers from TTL_INCLUDE_PATH.
 */

#pragma once

#if defined(__OPENCL_C_VERSION__)
/* OpenCL C: forward to the real TTL header on the include path */
#include_next "TTL/TTL.h"
#elif defined(TTL_INGRESS_C)
/* Polygeist ingress for C/OpenCL-ish sources:
 *
 * Keep this branch self-contained (no libc headers). It only exists so C code
 * can include `TTL/TTL.h` during ingress for thesis purposes.
 */
#ifndef restrict
#define restrict
#endif

typedef unsigned int TTL_dim;
typedef int TTL_offset_dim;

#elif defined(__cplusplus)
/* C++/host: declarations-only shim (same as polygeist_shim version).
 *
 * Keep this header self-contained (avoid libc++/libstdc++ headers) so it can be
 * parsed in minimal Polygeist/Clang setups.
 */

#ifndef restrict
#define restrict
#endif

using TTL_dim = unsigned int;
using TTL_offset_dim = int;

using TTL_overlap_dim = unsigned char;
using TTL_augmented_dim = unsigned char;

template <typename T, typename UNIQUE_ENUM_CLASS>
struct TTL_StrongType {
    using TYPE = T;
    constexpr TTL_StrongType();
    constexpr TTL_StrongType(T value);
    constexpr T Underlying() const;
};

struct TTL_event {
    void *opaque;
};

struct TTL_shape {
    TTL_shape(TTL_dim width = 0, TTL_dim height = 1, TTL_dim depth = 1);
    bool empty() const;
    TTL_dim width;
    TTL_dim height;
    TTL_dim depth;
};

struct TTL_offset {
    TTL_offset(TTL_offset_dim x = 0, TTL_offset_dim y = 0, TTL_offset_dim z = 0);
    TTL_offset_dim x;
    TTL_offset_dim y;
    TTL_offset_dim z;
};

struct TTL_overlap {
    TTL_overlap(TTL_overlap_dim width = 0, TTL_overlap_dim height = 0, TTL_overlap_dim depth = 0);
    TTL_overlap_dim width;
    TTL_overlap_dim height;
    TTL_overlap_dim depth;
};

struct TTL_augmentation {
    TTL_augmentation(TTL_augmented_dim left = 0, TTL_augmented_dim right = 0,
                     TTL_augmented_dim top = 0, TTL_augmented_dim bottom = 0,
                     TTL_augmented_dim front = 0, TTL_augmented_dim back = 0);
    TTL_augmented_dim left;
    TTL_augmented_dim right;
    TTL_augmented_dim top;
    TTL_augmented_dim bottom;
    TTL_augmented_dim front;
    TTL_augmented_dim back;
};

struct TTL_layout {
    TTL_layout(TTL_dim row_spacing = 0, TTL_dim plane_spacing = 0);
    TTL_dim row_spacing;
    TTL_dim plane_spacing;
};

struct TTL_tile {
    TTL_tile();
    bool empty() const;
    TTL_shape shape;
    TTL_offset offset;
};

struct TTL_tiler {
    TTL_tiler(TTL_shape tensor_shape, TTL_shape tile_shape);
    TTL_tiler(TTL_shape tensor_shape, TTL_shape tile_shape, TTL_overlap overlap, TTL_augmentation augmentation);

    int number_of_tiles() const;
    int valid_tile_id(int tile_id) const;
    TTL_dim tiles_in_width() const;
    TTL_dim tiles_in_height() const;
    TTL_dim tiles_in_depth() const;
    TTL_tile create_tile(TTL_dim x, TTL_dim y, TTL_dim z) const;
    TTL_tile get_tile(int tile_id) const;
    TTL_tile get_tile_column_major(int tile_id) const;

    TTL_shape space;
    TTL_shape tile;
    TTL_overlap overlap;
    TTL_augmentation augmentation;

    struct {
        TTL_dim number_of_tiles;
        TTL_dim tiles_in_width;
        TTL_dim tiles_in_height;
        TTL_dim tiles_in_depth;
        TTL_dim tiles_in_plane;
    } cache;
};

template <typename TENSORTYPE>
struct TTL_tensor {
    TTL_tensor();
    TTL_tensor(TENSORTYPE *base, const TTL_shape &shape, const TTL_layout &layout, const TTL_offset &offset, TTL_dim elem_size);
    TTL_tensor(TENSORTYPE *base, const TTL_shape &shape, const TTL_layout &layout, TTL_dim elem_size);
    TTL_tensor(TENSORTYPE *base, const TTL_shape &shape, const TTL_layout &layout);
    TTL_tensor(TENSORTYPE *base, const TTL_shape &shape, TTL_dim elem_size);
    TTL_tensor(TENSORTYPE *base, const TTL_shape &shape);

    const TENSORTYPE &read(unsigned int x, unsigned int y = 0, unsigned int z = 0) const;
    TENSORTYPE write(TENSORTYPE value, unsigned int x, unsigned int y = 0, unsigned int z = 0);
    bool empty() const;
    operator TTL_tensor<const TENSORTYPE>() const;

    TENSORTYPE *base;
    TTL_dim elem_size;
    TTL_layout layout;
    TTL_shape shape;
};

template <typename TENSORTYPE>
struct TTL_sub_tensor {
    TTL_sub_tensor();
    TTL_sub_tensor(TENSORTYPE *base, const TTL_shape &shape, const TTL_layout &layout, TTL_dim elem_size,
                   TTL_offset offset, TTL_shape origin_shape, TTL_offset origin_offset);
    TTL_sub_tensor(TENSORTYPE *base, const TTL_shape &shape, const TTL_layout &layout,
                   const TTL_tensor<TENSORTYPE> &origin_tensor, const TTL_offset &sub_offset);
    TTL_sub_tensor(const TTL_tensor<TENSORTYPE> &origin_tensor);

    const TENSORTYPE &read(unsigned int x, unsigned int y = 0, unsigned int z = 0) const;
    TENSORTYPE write(TENSORTYPE value, unsigned int x, unsigned int y = 0, unsigned int z = 0);
    bool empty();

    struct Origin {
        Origin(TTL_shape shape, TTL_offset sub_offset);
        TTL_shape shape;
        TTL_offset sub_offset;
    };

    TTL_tensor<TENSORTYPE> tensor;
    Origin origin;
};

template <typename TENSORTYPE>
struct TTL_io_tensors {
    TTL_io_tensors(TTL_sub_tensor<TENSORTYPE> imported_to, TTL_sub_tensor<TENSORTYPE> to_export_from);
    bool empty() const;
    TTL_sub_tensor<TENSORTYPE> imported_to;
    TTL_sub_tensor<TENSORTYPE> to_export_from;
};

TTL_event TTL_get_event();
void TTL_wait(int num_events, TTL_event *events);

template <typename TENSORTYPE>
void TTL_import(TTL_tensor<TENSORTYPE> internal_tensor, TTL_tensor<TENSORTYPE> external_tensor, TTL_event *event);

template <typename TENSORTYPE>
void TTL_blocking_import(const TTL_tensor<TENSORTYPE> &internal_tensor, const TTL_tensor<TENSORTYPE> &external_tensor);

template <typename TENSORTYPE>
void TTL_import_sub_tensor(const TTL_sub_tensor<TENSORTYPE> &internal_sub_tensor,
                           TTL_tensor<TENSORTYPE> external_tensor, TTL_event *event);

template <typename TENSORTYPE>
void TTL_export(const TTL_tensor<TENSORTYPE> &internal_tensor, const TTL_tensor<TENSORTYPE> &external_tensor, TTL_event *event);

template <typename TENSORTYPE>
void TTL_blocking_export(const TTL_tensor<TENSORTYPE> &internal_tensor, const TTL_tensor<TENSORTYPE> &external_tensor);

template <typename TENSORTYPE>
struct TTL_import_double_buffering {
    TTL_import_double_buffering(TENSORTYPE *int_base1, TENSORTYPE *int_base2,
                                TTL_tensor<TENSORTYPE> ext_tensor, TTL_event *event, TTL_tile first_tile);
    TTL_sub_tensor<TENSORTYPE> step_buffering(TTL_tile next_tile);
    void finish_buffering();
};

template <typename TENSORTYPE>
struct TTL_export_double_buffering {
    TTL_export_double_buffering(TENSORTYPE *int_base1, TENSORTYPE *int_base2,
                                TTL_tensor<TENSORTYPE> ext_tensor, TTL_event *event);
    TTL_sub_tensor<TENSORTYPE> step_buffering(TTL_tile current_tile);
    void finish_buffering();
};

template <typename TENSORTYPE>
struct TTL_duplex_buffering {
    TTL_duplex_buffering(TTL_tensor<TENSORTYPE> ext_tensor_in, TENSORTYPE *int_base_in,
                         TTL_tensor<TENSORTYPE> ext_tensor_out, TENSORTYPE *int_base_out,
                         TTL_event (*events)[2], TTL_tile first_tile);
    TTL_io_tensors<TENSORTYPE> step_buffering(TTL_tile import_tile, TTL_tile export_tile);
    void finish_buffering();
};

template <typename TENSORTYPE>
struct TTL_simplex_buffering {
    TTL_simplex_buffering(TENSORTYPE *int_base1, TENSORTYPE *int_base2, TENSORTYPE *int_base3,
                          const TTL_tensor<TENSORTYPE> &ext_tensor_in, const TTL_tensor<TENSORTYPE> &ext_tensor_out,
                          TTL_event *event_in, TTL_event *event_out, TTL_tile first_tile);
    TTL_io_tensors<TENSORTYPE> step_buffering(const TTL_tile &tile_next_import, const TTL_tile &tile_current_export);
    void finish_buffering();
};

#else
/* Plain C compilation: minimal typedefs only (no TTL API surface needed here). */
#ifndef restrict
#define restrict
#endif
typedef unsigned int TTL_dim;
typedef int TTL_offset_dim;

#endif /* __OPENCL_C_VERSION__ / TTL_INGRESS_C / __cplusplus / C */