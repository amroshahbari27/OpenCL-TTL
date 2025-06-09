module {
  func.func private @sigmoid(%arg0: memref<64x128xf32>, %arg1: memref<64x128xf32>) {
    %cst = arith.constant 1.000000e+00 : f32
    affine.for %arg2 = 0 to 64 {
      affine.for %arg3 = 0 to 128 {
        %0 = affine.load %arg0[%arg2, %arg3] : memref<64x128xf32>
        %1 = arith.negf %0 : f32
        %2 = math.exp %1 : f32
        %3 = arith.addf %2, %cst : f32
        %4 = arith.divf %cst, %3 : f32
        affine.store %4, %arg1[%arg2, %arg3] : memref<64x128xf32>
      }
    }
    return
  }
}
