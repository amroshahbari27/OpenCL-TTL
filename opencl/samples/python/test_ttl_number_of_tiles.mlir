// RUN: mlir-opt %s -o /dev/null

func.func @test_number_of_tiles() {
  // Test that number_of_tiles returns i32
  %tiler = arith.constant 42 : index
  %N = ttl.number_of_tiles %tiler : i32
  return
} 