// RUN: mlir-opt %s

// Test module using TTL dialect with copy operation
module {
  // Test function that uses TTL copy operation
  func.func @test_copy(%arg0: memref<10x10xf32>, %arg1: memref<10x10xf32>) {
    // Use the TTL copy operation to copy from arg0 to arg1
    "ttl.copy"(%arg0, %arg1) : (memref<10x10xf32>, memref<10x10xf32>) -> ()
    return
  }

  // Test function for TTL tiler operations
  func.func @test_tiler_ops(%A: memref<128x128xf32>) {
    // Get the tile shape (let's use 32x32 tiles)
    %tile_m = arith.constant 32 : i32
    %tile_n = arith.constant 32 : i32
    %tile_shape = "ttl.tile_shape"(%tile_m, %tile_n) : (i32, i32) -> !ttl.shape

    // Create a tiler for the memref (matrix A)
    %shape_m = arith.constant 128 : i32
    %shape_n = arith.constant 128 : i32
    %matrix_shape = "ttl.tile_shape"(%shape_m, %shape_n) : (i32, i32) -> !ttl.shape
    %tiler = "ttl.create_tiler"(%matrix_shape, %tile_shape) : (!ttl.shape, !ttl.shape) -> !ttl.tiler

    // Get a specific tile (e.g., tile at (0, 0))
    %tile_x = arith.constant 0 : i32
    %tile_y = arith.constant 0 : i32
    %tile = "ttl.get_tile"(%tile_x, %tile_y, %tiler) : (i32, i32, !ttl.tiler) -> !ttl.tile
    return
  }

  // Test function that uses TTL no-op operation
  func.func @test_noop() {
    // Use the TTL no-op operation
    "ttl.noop"() : () -> ()
    return
  }
} 