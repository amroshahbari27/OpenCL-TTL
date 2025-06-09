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
import argparse
import time

def Read(byte_array, i, j, stride, element_size):
    """Read a value from a byte array using the specified stride.
    
    Args:
        byte_array: The source byte array
        i: Row index
        j: Column index
        stride: Number of elements per row
        element_size: Size of each element in bytes
    """
    # For 4-byte integers, read directly as int32
    if element_size == 4:
        index = ((i * stride) + j) * element_size
        return int.from_bytes(byte_array[index:index+4], byteorder='little', signed=True)
    else:
        result = 0
        for byte_index in range(0, element_size):
            result = result + (pow(256, byte_index) * byte_array[(((i * stride) + j) * element_size) + byte_index])
        return result

def Write(byte_array, i, j, stride, value, element_size):
    """Write a value to a byte array using the specified stride.
    
    Args:
        byte_array: The target byte array
        i: Row index
        j: Column index
        stride: Number of elements per row
        value: Value to write
        element_size: Size of each element in bytes
    """
    index = ((i * stride) + j) * element_size
    byte_array[index:index + element_size] = value.to_bytes(element_size, byteorder='little', signed=True)

def PrintMatrix(byte_array, width, height, stride, element_size, name="Matrix"):
    """Print a matrix with the specified stride.
    
    Args:
        byte_array: The source byte array
        width: Width of the visible matrix
        height: Height of the visible matrix
        stride: Number of elements per row
        element_size: Size of each element in bytes
        name: Name of the matrix for display
    """
    print(f"\n{name}:")
    for i in range(height):
        row = []
        for j in range(width):
            row.append(str(Read(byte_array, i, j, stride, element_size)))
        print(" ".join(row))

def TestTTL(program_name, width=9, height=9, stride_a=None, stride_b=None, stride_c=None):
    """Test a TTL program with custom strides.
    
    Args:
        program_name: Name of the OpenCL program file
        width: Width of the matrix (default: 9)
        height: Height of the matrix (default: 9)
        stride_a: Stride for matrix A (default: width)
        stride_b: Stride for matrix B (default: width)
        stride_c: Stride for output matrix C (default: width)
    """
    os.environ['PYOPENCL_COMPILER_OUTPUT'] = '1'
    os.environ["PYOPENCL_NO_CACHE"] = "1"

    # Set default strides if not specified
    stride_a = width if stride_a is None else stride_a
    stride_b = width if stride_b is None else stride_b
    stride_c = width if stride_c is None else stride_c

    # Allow an environment variable to provide the TTL_INCLUDE_PATH, if not defined regular paths used.
    if "TTL_INCLUDE_PATH" in os.environ:
        ttl_include_path = "-I" + os.environ["TTL_INCLUDE_PATH"]
    else:
        ttl_include_path = "-I /usr/local/include/"

    # Allow an environment variable to provide the TTL_EXTRA_DEFINES, if not defined regular paths used.
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

        print(f"Testing {program_name} with {test_tensor_type} Tensors")
        print(f"Matrix dimensions: {width}x{height}")
        print(f"Strides: A={stride_a}, B={stride_b}, C={stride_c}")
        
        # Create input buffers with space for strides
        # Calculate buffer sizes based on strides
        buffer_size_a = stride_a * height * test_tensor_size
        buffer_size_b = stride_b * height * test_tensor_size
        buffer_size_c = stride_c * height * test_tensor_size
        
        input_data_a = bytearray(buffer_size_a)
        input_data_b = bytearray(buffer_size_b)
        output_data = bytearray(buffer_size_c)

        # Initialize input data with simple values
        for i in range(height):
            for j in range(width):
                # For A, use column index
                value_a = j
                Write(input_data_a, i, j, stride_a, value_a, test_tensor_size)
                
                # For B, use row index
                value_b = i
                Write(input_data_b, i, j, stride_b, value_b, test_tensor_size)

        # Print input matrices for debugging
        if width <= 16 and height <= 16:  # Only print for smaller matrices
            PrintMatrix(input_data_a, width, height, stride_a, test_tensor_size, "Input Matrix A (column indices)")
            PrintMatrix(input_data_b, width, height, stride_b, test_tensor_size, "Input Matrix B (row indices)")

        # Create OpenCL buffers
        input_buffer_a = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=input_data_a)
        input_buffer_b = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=input_data_b)
        output_buffer = cl.Buffer(context, cl.mem_flags.READ_WRITE, len(output_data))

        # Use tile size equal to tensor size for simplicity
        tile_width = width
        tile_height = height

      

        # Start timing
        start_time = time.time()

        # Call the kernel with the specified strides
        getattr(program, program_name)(
            queue,
            (1,),
            None,
            input_buffer_a,
            numpy.int32(stride_a),
            input_buffer_b,
            numpy.int32(stride_b),
            output_buffer,
            numpy.int32(stride_c),
            numpy.int32(width),
            numpy.int32(height))

        queue.finish()  # Ensure the kernel is completed

        # End timing
        end_time = time.time()
        execution_time = (end_time - start_time) * 1000  # Convert to milliseconds

        #print(f"\nTested Tensor size [{width}, {height}] Tile size [{tile_width}, {tile_height}] Type {test_tensor_type}")

        cl.enqueue_copy(queue, output_data, output_buffer)

        # Print output matrix for debugging
        if width <= 16 and height <= 16:  # Only print for smaller matrices
            PrintMatrix(output_data, width, height, stride_c, test_tensor_size, "Output Matrix (A + B)")

        # Verify results
        error = False
        for i in range(height):
            for j in range(width):
                expected = Read(input_data_a, i, j, stride_a, test_tensor_size) + \
                           Read(input_data_b, i, j, stride_b, test_tensor_size)
                actual = Read(output_data, i, j, stride_c, test_tensor_size)

                if actual != expected:
                    print(
                        "%s Failed at [%d, %d] %s != %s Tensor size [%d, %d], Strides [A=%d, B=%d, C=%d], Type %s"
                        % (
                            program_name,
                            j,
                            i,
                            hex(actual),
                            hex(expected),
                            width,
                            height,
                            stride_a,
                            stride_b,
                            stride_c,
                            test_tensor_type,
                        )
                    )
                    error = True

        if error:
            exit(-1)

        print(f"{program_name} Passed with dimensions [{width}, {height}] and strides [A={stride_a}, B={stride_b}, C={stride_c}]")
        print(f"Execution time: {execution_time:.4f} ms")
        
        return execution_time  # Return the execution time for benchmarking

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run TTL addition tests with custom strides')
    parser.add_argument('program', nargs='+', help='OpenCL program file(s) to test')
    parser.add_argument('--width', type=int, default=9, help='Width of the matrices (default: 9)')
    parser.add_argument('--height', type=int, default=9, help='Height of the matrices (default: 9)')
    parser.add_argument('--stride-a', type=int, help='Stride for matrix A (default: width)')
    parser.add_argument('--stride-b', type=int, help='Stride for matrix B (default: width)')
    parser.add_argument('--stride-c', type=int, help='Stride for output matrix C (default: width)')
    
    args = parser.parse_args()
    
    for program_name in args.program:
        TestTTL(
            program_name, 
            width=args.width, 
            height=args.height, 
            stride_a=args.stride_a, 
            stride_b=args.stride_b, 
            stride_c=args.stride_c
        )
