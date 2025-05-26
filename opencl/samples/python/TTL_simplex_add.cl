/*
 * TTL_simplex_add.cl
 *
 * Copyright (c) 2023 Mobileye
 *
 * Licensed under the Apache License, Version 2.0 (the License);
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "TTL/TTL.h"
#include "compute_cross.h"

#undef TTL_IO_TENSORS_TYPE
#define TTL_IO_TENSORS_TYPE __TTL_tensor_name(TTL_io_, , , TEST_TENSOR_TYPE, , _t)
#undef TTL_SIMPLEX_BUFFERING_TYPE
#define TTL_SIMPLEX_BUFFERING_TYPE __TTL_tensor_name(TTL_simplex_, const_, , TEST_TENSOR_TYPE, , _buffering_t)
#undef TTL_EXT_TENSOR_TYPE
#define TTL_EXT_TENSOR_TYPE __TTL_tensor_name(TTL_, , ext_, TEST_TENSOR_TYPE, , _t)

#define LOCAL_TILE_SIZE (LOCAL_MEMORY_SIZE / sizeof(TEST_TENSOR_TYPE) / 9)  // Divided by 9 since we need 3 sets of 3 buffers

__kernel void TTL_simplex_add(__global TEST_TENSOR_TYPE *restrict ext_base_in1, int external_stride_in1,
                             __global TEST_TENSOR_TYPE *restrict ext_base_in2, int external_stride_in2,
                             __global TEST_TENSOR_TYPE *restrict ext_base_out, int external_stride_out,
                             int width, int height, int tile_width, int tile_height) {
    // Buffers for first input
    __local TEST_TENSOR_TYPE l_buff1_in1[LOCAL_TILE_SIZE];
    __local TEST_TENSOR_TYPE l_buff2_in1[LOCAL_TILE_SIZE];
    __local TEST_TENSOR_TYPE l_buff3_in1[LOCAL_TILE_SIZE];

    // Buffers for second input
    __local TEST_TENSOR_TYPE l_buff1_in2[LOCAL_TILE_SIZE];
    __local TEST_TENSOR_TYPE l_buff2_in2[LOCAL_TILE_SIZE];
    __local TEST_TENSOR_TYPE l_buff3_in2[LOCAL_TILE_SIZE];

    // Buffers for output
    __local TEST_TENSOR_TYPE l_buff1_out[LOCAL_TILE_SIZE];
    __local TEST_TENSOR_TYPE l_buff2_out[LOCAL_TILE_SIZE];
    __local TEST_TENSOR_TYPE l_buff3_out[LOCAL_TILE_SIZE];

    if (((TILE_OVERLAP_LEFT + TILE_OVERLAP_RIGHT + tile_width) *
         (TILE_OVERLAP_TOP + TILE_OVERLAP_BOTTOM + tile_height)) > LOCAL_TILE_SIZE) {
        printf("Tile too large %d > %lu\n",
               ((TILE_OVERLAP_LEFT + TILE_OVERLAP_RIGHT + tile_width) *
                (TILE_OVERLAP_TOP + TILE_OVERLAP_BOTTOM + tile_height)),
               LOCAL_TILE_SIZE);
        return;
    }

    // Logical input tiling for first input
    const TTL_shape_t tensor_shape_in1 = TTL_create_shape(width, height);
    const TTL_shape_t tile_shape_in1 = TTL_create_shape(tile_width + (TILE_OVERLAP_LEFT + TILE_OVERLAP_RIGHT),
                                                       tile_height + (TILE_OVERLAP_TOP + TILE_OVERLAP_BOTTOM));
    const TTL_overlap_t overlap_in1 =
        TTL_create_overlap(TILE_OVERLAP_LEFT + TILE_OVERLAP_RIGHT, TILE_OVERLAP_TOP + TILE_OVERLAP_BOTTOM);
    const TTL_augmentation_t augmentation_in1 =
        TTL_create_augmentation(TILE_OVERLAP_LEFT, TILE_OVERLAP_RIGHT, TILE_OVERLAP_TOP, TILE_OVERLAP_BOTTOM);
    const TTL_tiler_t input_tiler1 =
        TTL_create_overlap_tiler(tensor_shape_in1, tile_shape_in1, overlap_in1, augmentation_in1);

    // Logical input tiling for second input
    const TTL_shape_t tensor_shape_in2 = TTL_create_shape(width, height);
    const TTL_shape_t tile_shape_in2 = TTL_create_shape(tile_width + (TILE_OVERLAP_LEFT + TILE_OVERLAP_RIGHT),
                                                       tile_height + (TILE_OVERLAP_TOP + TILE_OVERLAP_BOTTOM));
    const TTL_overlap_t overlap_in2 =
        TTL_create_overlap(TILE_OVERLAP_LEFT + TILE_OVERLAP_RIGHT, TILE_OVERLAP_TOP + TILE_OVERLAP_BOTTOM);
    const TTL_augmentation_t augmentation_in2 =
        TTL_create_augmentation(TILE_OVERLAP_LEFT, TILE_OVERLAP_RIGHT, TILE_OVERLAP_TOP, TILE_OVERLAP_BOTTOM);
    const TTL_tiler_t input_tiler2 =
        TTL_create_overlap_tiler(tensor_shape_in2, tile_shape_in2, overlap_in2, augmentation_in2);

    // Logical output tiling
    const TTL_shape_t tensor_shape_out = TTL_create_shape(width, height);
    const TTL_tiler_t output_tiler = TTL_create_tiler(tensor_shape_out, TTL_create_shape(tile_width, tile_height));

    // External layouts
    const TTL_layout_t ext_layout_in1 = TTL_create_layout(external_stride_in1);
    const TTL_layout_t ext_layout_in2 = TTL_create_layout(external_stride_in2);
    const TTL_layout_t ext_layout_out = TTL_create_layout(external_stride_out);

    const TTL_EXT_TENSOR_TYPE ext_input_tensor1 = TTL_create_ext_tensor(ext_base_in1, tensor_shape_in1, ext_layout_in1);
    const TTL_EXT_TENSOR_TYPE ext_input_tensor2 = TTL_create_ext_tensor(ext_base_in2, tensor_shape_in2, ext_layout_in2);
    const TTL_EXT_TENSOR_TYPE ext_output_tensor = TTL_create_ext_tensor(ext_base_out, tensor_shape_out, ext_layout_out);

    TTL_event_t tb_e_in1 = TTL_get_event();
    TTL_event_t tb_e_in2 = TTL_get_event();
    TTL_event_t tb_e_out = TTL_get_event();

    // Start simplex buffering for first input
    TTL_SIMPLEX_BUFFERING_TYPE simplex_scheme1 = TTL_start_simplex_buffering(l_buff1_in1,
                                                                             l_buff2_in1,
                                                                             l_buff3_in1,
                                                                             ext_input_tensor1,
                                                                             ext_output_tensor,
                                                                             &tb_e_in1,
                                                                             &tb_e_out,
                                                                             TTL_get_tile(0, input_tiler1));

    // Start simplex buffering for second input with dummy output tensor
    TTL_SIMPLEX_BUFFERING_TYPE simplex_scheme2 = TTL_start_simplex_buffering(l_buff1_in2,
                                                                             l_buff2_in2,
                                                                             l_buff3_in2,
                                                                             ext_input_tensor2,
                                                                             ext_output_tensor,  // Use output tensor as dummy
                                                                             &tb_e_in2,
                                                                             &tb_e_out,  // Use output event as dummy
                                                                             TTL_get_tile(0, input_tiler2));

    for (int i = 0; i < TTL_number_of_tiles(input_tiler1); ++i) {
        TTL_tile_t tile_next_import1 = TTL_get_tile(i + 1, input_tiler1);
        TTL_tile_t tile_next_import2 = TTL_get_tile(i + 1, input_tiler2);
        TTL_tile_t tile_current_export = TTL_get_tile(i, output_tiler);

        // Step buffering for both inputs
        TTL_IO_TENSORS_TYPE tensors1 = TTL_step_buffering(&simplex_scheme1, tile_next_import1, tile_current_export);
        TTL_IO_TENSORS_TYPE tensors2 = TTL_step_buffering(&simplex_scheme2, tile_next_import2, tile_current_export);

        // Add the tensors
        for (int y = 0; y < tile_height; ++y) {
            for (int x = 0; x < tile_width; ++x) {
                const int x_in = x + TILE_OVERLAP_LEFT;
                const int y_in = y + TILE_OVERLAP_TOP;
                const TEST_TENSOR_TYPE val1 = TTL_read_tensor(tensors1.imported_to, x_in, y_in);
                const TEST_TENSOR_TYPE val2 = TTL_read_tensor(tensors2.imported_to, x_in, y_in);
                TTL_write_tensor(tensors1.to_export_from, val1 + val2, x, y);
                TTL_write_tensor(tensors2.to_export_from, val1 + val2, x, y);
            }
        }
    }

    TTL_finish_buffering(&simplex_scheme1);
    TTL_finish_buffering(&simplex_scheme2);
} 