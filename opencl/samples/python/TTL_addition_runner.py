#!/usr/bin/python3

# ttl_sample_runner.py
#
# Copyright (c) 2023 Mobileye
#
# Licensed under the Apache License, Version 2.0 (the License);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an AS IS BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import numpy
import pyopencl as cl
import os
import sys
import random

def Read(byte_array, i, j, tensor_width, element_size):
    # For 4-byte integers, read directly as int32
    if element_size == 4:
        index = ((i * tensor_width) + j) * element_size
        return int.from_bytes(byte_array[index:index+4], byteorder='little', signed=True)
    else:
        result = 0
        for byte_index in range(0, element_size):
            result = result + (pow(256, byte_index) * byte_array[(((i * tensor_width) + j) * element_size) + byte_index])
        return result

def TestTTL(program_name):
    os.environ['PYOPENCL_COMPILER_OUTPUT'] = '1'
    os.environ["PYOPENCL_NO_CACHE"] = "1"

    # Allow an environment variable to provide the TTL_INCLUDE_PATH, if not defined regular paths used.
    if "TTL_INCLUDE_PATH" in os.environ:
        ttl_include_path = "-I" + os.environ["TTL_INCLUDE_PATH"]
    else:
        ttl_include_path = "-I /usr/local/include/"

    # Allow an environment variable to provide the TTL_INCLUDE_PATH, if not defined regular paths used.
    if "TTL_EXTRA_DEFINES" in os.environ:
        ttl_extra_defines =  " " + os.environ["TTL_EXTRA_DEFINES"] + " "
    else:
        ttl_extra_defines = ""

    for test_tensor_type, test_tensor_size in list([('int',4)]):
        platforms = cl.get_platforms()
        context = cl.Context(dev_type=cl.device_type.ALL,
                             properties=[(cl.context_properties.PLATFORM, platforms[0])])
        queue = cl.CommandQueue(context)

        ttl_local_memory_size = 0xfffffffff

        # Provide the local memory size.
        for device in context.get_info(cl.context_info.DEVICES):
            ttl_local_memory_size = min(device.get_info(cl.device_info.LOCAL_MEM_SIZE), ttl_local_memory_size)

        # For convenience remove the .cl extension if it included.
        program_name = os.path.splitext(program_name)[0]
        program = cl.Program(context, open(program_name+'.cl').read()).build(options=ttl_include_path + ttl_extra_defines +
                                                                             " -DTTL_COPY_3D -DTEST_TENSOR_TYPE=" + test_tensor_type +
                                                                             " -DLOCAL_MEMORY_SIZE=" + str(ttl_local_memory_size))

        print("Testing %s with %s Tensors" % (program_name, test_tensor_type))

        # Use fixed 9x9 tensor size
        tensor_width = 9
        tensor_height = 9
        
        # Create input buffers with known values
        input_data_A = bytearray(tensor_width * tensor_height * test_tensor_size)
        input_data_B = bytearray(tensor_width * tensor_height * test_tensor_size)
        output_data = bytearray(tensor_width * tensor_height * test_tensor_size)

        # Initialize input data with simple values
        for i in range(0, tensor_height):
            for j in range(0, tensor_width):
                # For A, use column index
                value_A = j
                input_data_A[((i * tensor_width) + j) * test_tensor_size:((i * tensor_width) + j + 1) * test_tensor_size] = \
                    value_A.to_bytes(test_tensor_size, byteorder='little', signed=True)
                
                # For B, use row index
                value_B = i
                input_data_B[((i * tensor_width) + j) * test_tensor_size:((i * tensor_width) + j + 1) * test_tensor_size] = \
                    value_B.to_bytes(test_tensor_size, byteorder='little', signed=True)

        # Print input matrices for debugging
        print("\nInput Matrix A (column indices):")
        for i in range(tensor_height):
            row = []
            for j in range(tensor_width):
                row.append(str(Read(input_data_A, i, j, tensor_width, test_tensor_size)))
            print(" ".join(row))

        print("\nInput Matrix B (row indices):")
        for i in range(tensor_height):
            row = []
            for j in range(tensor_width):
                row.append(str(Read(input_data_B, i, j, tensor_width, test_tensor_size)))
            print(" ".join(row))

        # Create OpenCL buffers
        input_buffer_A = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=input_data_A)
        input_buffer_B = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=input_data_B)
        output_buffer = cl.Buffer(context, cl.mem_flags.READ_WRITE, len(output_data))

        # Use tile size equal to tensor size for simplicity
        tile_width = tensor_width
        tile_height = tensor_height

        getattr(program, program_name)(
            queue,
            (1,),
            None,
            input_buffer_A,
            numpy.int32(tensor_width),
            input_buffer_B,
            numpy.int32(tensor_width),
            output_buffer,
            numpy.int32(tensor_width),
            numpy.int32(tensor_width),
            numpy.int32(tensor_height))

        print("\nTested Tensor size [%d, %d] Tile size [%d, %d] Type %s" %(tensor_width, tensor_height, tile_width, tile_height, test_tensor_type))

        cl.enqueue_copy(queue, output_data, output_buffer)

        # Print output matrix for debugging
        print("\nOutput Matrix (A + B):")
        for i in range(tensor_height):
            row = []
            for j in range(tensor_width):
                row.append(str(Read(output_data, i, j, tensor_width, test_tensor_size)))
            print(" ".join(row))

        # Verify results
        error = False
        for i in range(0, tensor_height):
            for j in range(0, tensor_width):
                expected = Read(input_data_A, i, j, tensor_width, test_tensor_size) + \
                         Read(input_data_B, i, j, tensor_width, test_tensor_size)
                actual = Read(output_data, i, j, tensor_width, test_tensor_size)

                if actual != expected:
                    print(
                        "%s Failed at [%d, %d] %s != %s Tensor size [%d, %d], Tile size [%d, %d], Tensor type %s"
                        % (
                            program_name,
                            j,
                            i,
                            hex(actual),
                            hex(expected),
                            tensor_width,
                            tensor_height,
                            tile_width,
                            tile_height,
                            test_tensor_type,
                        )
                    )
                    error = True

        if error:
            exit(-1)

        print("%s Passed Tensor size [%d, %d] Tile size [%d, %d] Type %s" %(program_name, tensor_width, tensor_height, tile_width, tile_height, test_tensor_type))

if __name__ == '__main__':
    for program_name in sys.argv[1:]:
        TestTTL(program_name)
