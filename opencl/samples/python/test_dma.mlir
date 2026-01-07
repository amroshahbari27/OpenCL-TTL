module {
  emitc.func private @sigmoid(%arg0: !emitc.array<64x128xf32> {llvm.noalias}, %arg1: !emitc.array<64x128xf32> {llvm.noalias}) attributes {specifiers = ["static"]} {
    %0 = "emitc.constant"() <{value = 1.000000e+00 : f64}> : () -> f64
    %1 = "emitc.constant"() <{value = 0 : index}> : () -> !emitc.size_t
    %2 = "emitc.constant"() <{value = 64 : index}> : () -> !emitc.size_t
    %3 = "emitc.constant"() <{value = 4 : index}> : () -> !emitc.size_t
    for %arg2 = %1 to %2 step %3  : !emitc.size_t {
      %4 = "emitc.constant"() <{value = 0 : index}> : () -> !emitc.size_t
      %5 = "emitc.constant"() <{value = 128 : index}> : () -> !emitc.size_t
      %6 = "emitc.constant"() <{value = 4 : index}> : () -> !emitc.size_t
      for %arg3 = %4 to %5 step %6  : !emitc.size_t {
        %7 = "emitc.constant"() <{value = 4 : index}> : () -> !emitc.size_t
        %8 = add %arg2, %7 : (!emitc.size_t, !emitc.size_t) -> !emitc.size_t
        %9 = "emitc.constant"() <{value = 1 : index}> : () -> !emitc.size_t
        for %arg4 = %arg2 to %8 step %9  : !emitc.size_t {
          %10 = "emitc.constant"() <{value = 4 : index}> : () -> !emitc.size_t
          %11 = add %arg3, %10 : (!emitc.size_t, !emitc.size_t) -> !emitc.size_t
          %12 = "emitc.constant"() <{value = 1 : index}> : () -> !emitc.size_t
          for %arg5 = %arg3 to %11 step %12  : !emitc.size_t {
            %13 = subscript %arg0[%arg4, %arg5] : (!emitc.array<64x128xf32>, !emitc.size_t, !emitc.size_t) -> !emitc.lvalue<f32>
            %14 = load %13 : <f32>
            %15 = unary_minus %14 : (f32) -> f32
            %16 = cast %15 : f32 to f64
            %17 = call_opaque "exp"(%16) : (f64) -> f64
            %18 = add %17, %0 : (f64, f64) -> f64
            %19 = div %0, %18 : (f64, f64) -> f64
            %20 = cast %19 : f64 to f32
            %21 = subscript %arg1[%arg4, %arg5] : (!emitc.array<64x128xf32>, !emitc.size_t, !emitc.size_t) -> !emitc.lvalue<f32>
            assign %20 : f32 to %21 : <f32>
          }
        }
      }
    }
    return
  }
}

