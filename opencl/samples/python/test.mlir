module {
  func.func private @sigmoid_TTL_optimized(%arg0: memref<64x128xf32> {llvm.noalias}, %arg1: memref<64x128xf32> {llvm.noalias}) {
    %cst = arith.constant 1.000000e+00 : f64
    affine.for %arg2 = 0 to 64 {
      affine.for %arg3 = 0 to 128 {
        %0 = affine.load %arg0[%arg2, %arg3] : memref<64x128xf32>
        %1 = arith.negf %0 : f32
        %2 = arith.extf %1 : f32 to f64
        %3 = math.exp %2 : f64
        %4 = arith.addf %3, %cst : f64
        %5 = arith.divf %cst, %4 : f64
        %6 = arith.truncf %5 : f64 to f32
        affine.store %6, %arg1[%arg2, %arg3] : memref<64x128xf32>
      } {ttl.tile = [4, 4]}
    } {ttl.tile = [4, 4]}
    return
  }
}
