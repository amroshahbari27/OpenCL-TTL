#!/usr/bin/python3

# simple_add_runner.py
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

def Read(byte_array, i, j, tensor_width, element_size):
    result = 0
    for byte_index in range(0, element_size):
        result = result + (pow(256, byte_index) * byte_array[(((i * tensor_width) + j) * element_size) + byte_index])
    return result

def Write(byte_array, i, j, tensor_width, element_size, value):
    for byte_index in range(0, element_size):
        byte_array[(((i * tensor_width) + j) * element_size) + byte_index] = (value >> (8 * byte_index)) & 0xFF

def TestSimpleAdd(program_name):
    os.environ['PYOPENCL_COMPILER_OUTPUT'] = '1'
    os.environ["PYOPENCL_NO_CACHE"] = "1"

    # Allow an environment variable to provide the TTL_INCLUDE_PATH, if not defined regular paths used.
    if "TTL_INCLUDE_PATH" in os.environ:
        ttl_include_path = "-I" + os.environ["TTL_INCLUDE_PATH"]
    else:
        ttl_include_path = "-I /usr/local/include/"

    # Allow an environment variable to provide the TTL_EXTRA_DEFINES, if not defined regular definitions used.
    if "TTL_EXTRA_DEFINES" in os.environ:
        ttl_extra_defines = " " + os.environ["TTL_EXTRA_DEFINES"] + " "
    else:
        ttl_extra_defines = ""

    # Use int type for testing
    test_tensor_type = 'int'
    test_tensor_size = 4

    # Fixed tensor size for simple testing
    tensor_width = 8
    tensor_height = 8

    platforms = cl.get_platforms()
    context = cl.Context(dev_type=cl.device_type.ALL,
                         properties=[(cl.context_properties.PLATFORM, platforms[0])])
    queue = cl.CommandQueue(context)

    ttl_local_memory_size = 0xfffffffff
    for device in context.get_info(cl.context_info.DEVICES):
        ttl_local_memory_size = min(device.get_info(cl.device_info.LOCAL_MEM_SIZE), ttl_local_memory_size)

    # Build the program
    program_name = os.path.splitext(program_name)[0]
    program = cl.Program(context, open(program_name+'.cl').read()).build(options=ttl_include_path + ttl_extra_defines +
                                                                         " -DTTL_COPY_3D -DTEST_TENSOR_TYPE=" + test_tensor_type +
                                                                         " -DLOCAL_MEMORY_SIZE=" + str(ttl_local_memory_size))

    print("Testing %s with %s Tensors" % (program_name, test_tensor_type))

    # Create input and output buffers
    output_data = bytearray(os.urandom(tensor_width * tensor_height * test_tensor_size))
    input_data1 = bytearray(os.urandom(tensor_width * tensor_height * test_tensor_size))
    input_data2 = bytearray(os.urandom(tensor_width * tensor_height * test_tensor_size))

    # Initialize input data with test values
    for i in range(0, tensor_height):
        for j in range(0, tensor_width):
            Write(input_data1, i, j, tensor_width, test_tensor_size, i * tensor_width + j)
            Write(input_data2, i, j, tensor_width, test_tensor_size, (i * tensor_width + j) * 2)

    # Create OpenCL buffers
    input_buffer1 = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=input_data1)
    input_buffer2 = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=input_data2)
    output_buffer = cl.Buffer(context, cl.mem_flags.READ_WRITE, len(output_data))

    # Run the kernel
    getattr(program, program_name)(
        queue,
        (1,),
        None,
        input_buffer1,
        numpy.int32(tensor_width),
        input_buffer2,
        numpy.int32(tensor_width),
        output_buffer,
        numpy.int32(tensor_width),
        numpy.int32(tensor_width),
        numpy.int32(tensor_height))

    print("Running with Tensor size [%d, %d]" % (tensor_width, tensor_height))

    # Copy results back
    cl.enqueue_copy(queue, output_data, output_buffer)

    # Print results and verify
    print("\nResults:")
    print("Input1 + Input2 = Output")
    error = False
    for i in range(0, tensor_height):
        for j in range(0, tensor_width):
            val1 = Read(input_data1, i, j, tensor_width, test_tensor_size)
            val2 = Read(input_data2, i, j, tensor_width, test_tensor_size)
            actual = Read(output_data, i, j, tensor_width, test_tensor_size)
            expected = val1 + val2
            print("[%d,%d]: %d + %d = %d" % (i, j, val1, val2, actual))
            
            if actual != expected:
                print("Failed at [%d, %d] %d != %d" % (i, j, actual, expected))
                error = True

    if error:
        exit(-1)
    else:
        print("\nAll tests passed!")

if __name__ == '__main__':
    for program_name in sys.argv[1:]:
        TestSimpleAdd(program_name) 