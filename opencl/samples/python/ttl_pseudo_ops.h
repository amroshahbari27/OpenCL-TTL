/*
 * ttl_pseudo_ops.h
 *
 * Declarations-only TTL shim for Polygeist/Clang parsing.
 *
 * Goal:
 * - Provide TTL types and function signatures so Polygeist can ingest C/C++ that
 *   uses TTL and produce MLIR with external calls (no implementations here).
 *
 * Non-goals:
 * - No functional behavior. Do not define inline bodies for TTL operations.
 * - No dependency on the real TTL headers.
 *
 * How to use:
 * - Include this header instead of "TTL/TTL.h" when compiling with Polygeist.
 * - Link against real TTL later (or treat calls as external symbols in MLIR).
 */

#ifndef TTL_PSEUDO_OPS_H
#define TTL_PSEUDO_OPS_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*==============================================================================
 * Optional: annotate calls so later passes can identify them.
 *============================================================================*/
#if defined(__clang__)
#define TTL_ANNOTATE(op_name) __attribute__((annotate(op_name)))
#else
#define TTL_ANNOTATE(op_name)
#endif

/*==============================================================================
 * Basic scalar types (match TTL intent, not necessarily exact ABI).
 *============================================================================*/
typedef uint32_t TTL_dim;            /* dimension size (elements) */
typedef int32_t TTL_offset_dim;      /* signed offset/origin (elements) */
typedef unsigned char TTL_overlap_dim;
typedef unsigned char TTL_augmented_dim;

/*==============================================================================
 * Event type (opaque in the shim)
 *============================================================================*/
typedef struct TTL_event_s {
    uintptr_t opaque;
} TTL_event;
typedef TTL_event TTL_event_t;

/*==============================================================================
 * Core value types
 *============================================================================*/
typedef struct TTL_shape {
    TTL_dim width;
    TTL_dim height;
    TTL_dim depth;
} TTL_shape;
typedef TTL_shape TTL_shape_t;

typedef struct TTL_offset {
    TTL_offset_dim x;
    TTL_offset_dim y;
    TTL_offset_dim z;
} TTL_offset;
typedef TTL_offset TTL_offset_t;

typedef struct TTL_overlap {
    TTL_overlap_dim width;
    TTL_overlap_dim height;
    TTL_overlap_dim depth;
} TTL_overlap;
typedef TTL_overlap TTL_overlap_t;

typedef struct TTL_augmentation {
    TTL_augmented_dim left;
    TTL_augmented_dim right;
    TTL_augmented_dim top;
    TTL_augmented_dim bottom;
    TTL_augmented_dim front;
    TTL_augmented_dim back;
} TTL_augmentation;
typedef TTL_augmentation TTL_augmentation_t;

typedef struct TTL_layout {
    TTL_dim row_spacing;
    TTL_dim plane_spacing;
} TTL_layout;
typedef TTL_layout TTL_layout_t;

typedef struct TTL_tile {
    TTL_shape shape;
    TTL_offset offset;
} TTL_tile;
typedef TTL_tile TTL_tile_t;

/*==============================================================================
 * Tiler (keep fields available for analysis/debug, but no behavior here)
 *============================================================================*/
typedef struct TTL_tiler_cache {
    TTL_dim number_of_tiles;
    TTL_dim tiles_in_width;
    TTL_dim tiles_in_height;
    TTL_dim tiles_in_depth;
    TTL_dim tiles_in_plane;
} TTL_tiler_cache;

typedef struct TTL_tiler {
    TTL_shape space;
    TTL_shape tile;
    TTL_overlap overlap;
    TTL_augmentation augmentation;
    TTL_tiler_cache cache;
} TTL_tiler;
typedef TTL_tiler TTL_tiler_t;

/*==============================================================================
 * Tensor/sub-tensor: keep enough structure for client code to access shape/layout
 *============================================================================*/
typedef struct TTL_tensor {
    void *base;
    TTL_dim elem_size;
    TTL_layout layout;
    TTL_shape shape;
} TTL_tensor;
typedef TTL_tensor TTL_tensor_t;

typedef struct TTL_sub_tensor_origin {
    TTL_shape shape;
    TTL_offset sub_offset;
} TTL_sub_tensor_origin;

typedef struct TTL_sub_tensor {
    TTL_tensor tensor;
    TTL_sub_tensor_origin origin;
} TTL_sub_tensor;
typedef TTL_sub_tensor TTL_sub_tensor_t;

typedef struct TTL_io_tensors {
    TTL_sub_tensor imported_to;
    TTL_sub_tensor to_export_from;
} TTL_io_tensors;
typedef TTL_io_tensors TTL_io_tensors_t;

/*==============================================================================
 * Constructors / creators (decl only)
 *============================================================================*/
TTL_shape_t TTL_create_shape(TTL_dim width, TTL_dim height, TTL_dim depth) TTL_ANNOTATE("ttl.create_shape");
TTL_offset_t TTL_create_offset(TTL_offset_dim x, TTL_offset_dim y, TTL_offset_dim z) TTL_ANNOTATE("ttl.create_offset");
TTL_overlap_t TTL_create_overlap(TTL_overlap_dim width, TTL_overlap_dim height, TTL_overlap_dim depth)
    TTL_ANNOTATE("ttl.create_overlap");
TTL_augmentation_t TTL_create_augmentation(TTL_augmented_dim left, TTL_augmented_dim right,
                                           TTL_augmented_dim top, TTL_augmented_dim bottom,
                                           TTL_augmented_dim front, TTL_augmented_dim back)
    TTL_ANNOTATE("ttl.create_augmentation");
TTL_layout_t TTL_create_layout(TTL_dim row_spacing, TTL_dim plane_spacing) TTL_ANNOTATE("ttl.create_layout");

TTL_tile_t TTL_create_tile(TTL_shape_t shape, TTL_offset_t offset) TTL_ANNOTATE("ttl.create_tile");

TTL_tiler_t TTL_create_tiler(TTL_shape_t tensor_shape, TTL_shape_t tile_shape) TTL_ANNOTATE("ttl.create_tiler");
TTL_tiler_t TTL_create_overlap_tiler(TTL_shape_t tensor_shape, TTL_shape_t tile_shape,
                                     TTL_overlap_t overlap, TTL_augmentation_t augmentation)
    TTL_ANNOTATE("ttl.create_overlap_tiler");

TTL_tensor_t TTL_create_tensor(void *base, TTL_shape_t shape, TTL_layout_t layout, TTL_offset_t offset, TTL_dim elem_size)
    TTL_ANNOTATE("ttl.create_tensor");

TTL_sub_tensor_t TTL_create_sub_tensor(void *base, TTL_shape_t shape, TTL_layout_t layout, TTL_dim elem_size,
                                       TTL_shape_t origin_shape, TTL_offset_t origin_sub_offset)
    TTL_ANNOTATE("ttl.create_sub_tensor");

TTL_io_tensors_t TTL_create_io_tensors(TTL_sub_tensor_t imported_to, TTL_sub_tensor_t to_export_from)
    TTL_ANNOTATE("ttl.create_io_tensors");

/*==============================================================================
 * Query / indexing ops (decl only)
 *============================================================================*/
int TTL_shape_empty(TTL_shape_t s) TTL_ANNOTATE("ttl.shape_empty");
int TTL_tile_empty(TTL_tile_t t) TTL_ANNOTATE("ttl.tile_empty");
int TTL_tensor_empty(TTL_tensor_t t) TTL_ANNOTATE("ttl.tensor_empty");
int TTL_sub_tensor_empty(TTL_sub_tensor_t t) TTL_ANNOTATE("ttl.sub_tensor_empty");

TTL_dim TTL_number_of_tiles(TTL_tiler_t tiler) TTL_ANNOTATE("ttl.number_of_tiles");
int TTL_valid_tile_id(TTL_tiler_t tiler, int tile_id) TTL_ANNOTATE("ttl.valid_tile_id");
TTL_tile_t TTL_get_tile(int tile_id, TTL_tiler_t tiler) TTL_ANNOTATE("ttl.get_tile");
TTL_tile_t TTL_get_tile_column_major(int tile_id, TTL_tiler_t tiler) TTL_ANNOTATE("ttl.get_tile_column_major");

/*==============================================================================
 * Events / sync (decl only)
 *============================================================================*/
TTL_event_t TTL_get_event(void) TTL_ANNOTATE("ttl.get_event");
void TTL_wait(int num_events, TTL_event_t *events) TTL_ANNOTATE("ttl.wait");

/*==============================================================================
 * DMA ops (decl only)
 *============================================================================*/
void TTL_import(TTL_tensor_t internal_tensor, TTL_tensor_t external_tensor, TTL_event_t *event) TTL_ANNOTATE("ttl.import");
void TTL_export(TTL_tensor_t internal_tensor, TTL_tensor_t external_tensor, TTL_event_t *event) TTL_ANNOTATE("ttl.export");
void TTL_blocking_import(TTL_tensor_t internal_tensor, TTL_tensor_t external_tensor) TTL_ANNOTATE("ttl.blocking_import");
void TTL_blocking_export(TTL_tensor_t internal_tensor, TTL_tensor_t external_tensor) TTL_ANNOTATE("ttl.blocking_export");
void TTL_import_sub_tensor(TTL_sub_tensor_t internal_sub_tensor, TTL_tensor_t external_tensor, TTL_event_t *event)
    TTL_ANNOTATE("ttl.import_sub_tensor");

/*==============================================================================
 * Buffering schemes (structs + decl-only API)
 *
 * We keep these as concrete structs so code can hold them by value, as in TTL C.
 * No bodies are provided here.
 *============================================================================*/
typedef struct TTL_import_double_buffering {
    void *opaque[8];
} TTL_import_double_buffering;
typedef TTL_import_double_buffering TTL_import_double_buffering_t;

typedef struct TTL_export_double_buffering {
    void *opaque[8];
} TTL_export_double_buffering;
typedef TTL_export_double_buffering TTL_export_double_buffering_t;

typedef struct TTL_duplex_buffering {
    void *opaque[8];
} TTL_duplex_buffering;
typedef TTL_duplex_buffering TTL_duplex_buffering_t;

typedef struct TTL_simplex_buffering {
    void *opaque[8];
} TTL_simplex_buffering;
typedef TTL_simplex_buffering TTL_simplex_buffering_t;

TTL_import_double_buffering_t TTL_start_import_double_buffering(void *buf1, void *buf2,
                                                                TTL_tensor_t ext_tensor, TTL_event_t *event,
                                                                TTL_tile_t first_tile)
    TTL_ANNOTATE("ttl.start_import_double_buffering");
TTL_sub_tensor_t TTL_step_import_double_buffering(TTL_import_double_buffering_t *scheme, TTL_tile_t next_tile)
    TTL_ANNOTATE("ttl.step_import_double_buffering");
void TTL_finish_import_double_buffering(TTL_import_double_buffering_t *scheme)
    TTL_ANNOTATE("ttl.finish_import_double_buffering");

TTL_export_double_buffering_t TTL_start_export_double_buffering(void *buf1, void *buf2,
                                                                TTL_tensor_t ext_tensor, TTL_event_t *event)
    TTL_ANNOTATE("ttl.start_export_double_buffering");
TTL_sub_tensor_t TTL_step_export_double_buffering(TTL_export_double_buffering_t *scheme, TTL_tile_t current_tile)
    TTL_ANNOTATE("ttl.step_export_double_buffering");
void TTL_finish_export_double_buffering(TTL_export_double_buffering_t *scheme)
    TTL_ANNOTATE("ttl.finish_export_double_buffering");

TTL_duplex_buffering_t TTL_start_duplex_buffering(TTL_tensor_t ext_tensor_in, void *int_base_in,
                                                 TTL_tensor_t ext_tensor_out, void *int_base_out,
                                                 TTL_event_t (*events)[2], TTL_tile_t first_tile)
    TTL_ANNOTATE("ttl.start_duplex_buffering");
TTL_io_tensors_t TTL_step_duplex_buffering(TTL_duplex_buffering_t *scheme, TTL_tile_t import_tile, TTL_tile_t export_tile)
    TTL_ANNOTATE("ttl.step_duplex_buffering");
void TTL_finish_duplex_buffering(TTL_duplex_buffering_t *scheme) TTL_ANNOTATE("ttl.finish_duplex_buffering");

TTL_simplex_buffering_t TTL_start_simplex_buffering(void *buf1, void *buf2, void *buf3,
                                                   TTL_tensor_t ext_tensor_in, TTL_tensor_t ext_tensor_out,
                                                   TTL_event_t *event_in, TTL_event_t *event_out,
                                                   TTL_tile_t first_tile)
    TTL_ANNOTATE("ttl.start_simplex_buffering");
TTL_io_tensors_t TTL_step_simplex_buffering(TTL_simplex_buffering_t *scheme, TTL_tile_t import_tile, TTL_tile_t export_tile)
    TTL_ANNOTATE("ttl.step_simplex_buffering");
void TTL_finish_simplex_buffering(TTL_simplex_buffering_t *scheme) TTL_ANNOTATE("ttl.finish_simplex_buffering");

/* Convenience overloads in C11 (decl-only dispatch macro). */
#if !defined(__cplusplus) && defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
#define TTL_step_buffering(scheme_ptr, ...)                                                                  \
    _Generic((scheme_ptr),                                                                                   \
        TTL_import_double_buffering_t *: TTL_step_import_double_buffering,                                   \
        TTL_export_double_buffering_t *: TTL_step_export_double_buffering,                                   \
        TTL_duplex_buffering_t *: TTL_step_duplex_buffering,                                                  \
        TTL_simplex_buffering_t *: TTL_step_simplex_buffering                                                 \
    )((scheme_ptr), __VA_ARGS__)

#define TTL_finish_buffering(scheme_ptr)                                                                     \
    _Generic((scheme_ptr),                                                                                   \
        TTL_import_double_buffering_t *: TTL_finish_import_double_buffering,                                  \
        TTL_export_double_buffering_t *: TTL_finish_export_double_buffering,                                  \
        TTL_duplex_buffering_t *: TTL_finish_duplex_buffering,                                                \
        TTL_simplex_buffering_t *: TTL_finish_simplex_buffering                                               \
    )((scheme_ptr))
#endif

/*==============================================================================
 * Utility
 *============================================================================*/
TTL_offset_dim TTL_linearize(TTL_offset_t offset, TTL_layout_t layout) TTL_ANNOTATE("ttl.linearize");

/*==============================================================================
 * Keep your small Polygeist helper macros here (from ttl_dsl.h)
 *============================================================================*/
#ifndef TTL_DSL_H
#define TTL_DSL_H

#define TTL_RESTRICT __restrict

/* Polygeist mode: pointer to fixed-size array */
#define TTL_2D_ARG(name, type, dim0, dim1) type(*TTL_RESTRICT name)[dim0][dim1]
#define TTL_2D_ARG_ACCESS(name, i, j, dim1) (*name)[i][j]

#define TTL_ASSERT_STATIC(expr) _Static_assert((expr), "TTL requires compile-time constant")

#endif /* TTL_DSL_H */

#ifndef TTL_MODE
#define TTL_MODE 0
#endif

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* TTL_PSEUDO_OPS_H */

