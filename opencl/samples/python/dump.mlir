Analyzing TTL_matmul_kernel:
x.start = 0 (constant)
x.end = dynamic
x.step = 2 (constant)
x.current = 0 (constant)
y.start = 0 (constant)
y.end = dynamic
y.step = 3 (constant)
y.current = 1 (constant)
z.start = 0 (constant)
z.end = dynamic
z.step = 4 (constant)
z.current = 2 (constant)

Analyzing Tensor1 tensor access:
rank = 2D
x_stride = 1 (constant)
y_stride = dynamic
z_stride = 0 (constant)
x_index = x (loop var)
y_index = z (loop var)
z_index = 0 (constant)

Analyzing Tensor2 tensor access:
rank = 2D
x_stride = 1 (constant)
y_stride = dynamic
z_stride = 0 (constant)
x_index = z (loop var)
y_index = y (loop var)
z_index = 0 (constant)

Analyzing Tensor3 tensor access:
rank = 2D
x_stride = 1 (constant)
y_stride = dynamic
z_stride = 0 (constant)
x_index = x (loop var)
y_index = y (loop var)
z_index = 0 (constant)
#tbaa_root = #llvm.tbaa_root<id = "Simple C/C++ TBAA">
#tbaa_type_desc = #llvm.tbaa_type_desc<id = "omnipotent char", members = {<#tbaa_root, 0>}>
#tbaa_type_desc1 = #llvm.tbaa_type_desc<id = "any pointer", members = {<#tbaa_type_desc, 0>}>
#tbaa_type_desc2 = #llvm.tbaa_type_desc<id = "int", members = {<#tbaa_type_desc, 0>}>
#tbaa_tag = #llvm.tbaa_tag<base_type = #tbaa_type_desc2, access_type = #tbaa_type_desc2, offset = 0>
#tbaa_type_desc3 = #llvm.tbaa_type_desc<id = "", members = {<#tbaa_type_desc2, 0>, <#tbaa_type_desc2, 4>}>
#tbaa_type_desc4 = #llvm.tbaa_type_desc<id = "", members = {<#tbaa_type_desc2, 0>, <#tbaa_type_desc2, 4>, <#tbaa_type_desc2, 8>}>
#tbaa_type_desc5 = #llvm.tbaa_type_desc<id = "", members = {<#tbaa_type_desc1, 0>, <#tbaa_type_desc2, 8>, <#tbaa_type_desc2, 12>, <#tbaa_type_desc2, 16>, <#tbaa_type_desc2, 20>, <#tbaa_type_desc2, 24>, <#tbaa_type_desc2, 28>, <#tbaa_type_desc2, 32>}>
#tbaa_type_desc6 = #llvm.tbaa_type_desc<id = "", members = {<#tbaa_type_desc2, 0>, <#tbaa_type_desc2, 4>, <#tbaa_type_desc2, 8>, <#tbaa_type_desc2, 12>, <#tbaa_type_desc2, 16>, <#tbaa_type_desc2, 20>, <#tbaa_type_desc2, 24>, <#tbaa_type_desc2, 28>, <#tbaa_type_desc2, 32>, <#tbaa_type_desc2, 36>, <#tbaa_type_desc2, 40>, <#tbaa_type_desc2, 44>, <#tbaa_type_desc2, 48>}>
#tbaa_tag1 = #llvm.tbaa_tag<base_type = #tbaa_type_desc5, access_type = #tbaa_type_desc2, offset = 24>
#tbaa_tag2 = #llvm.tbaa_tag<base_type = #tbaa_type_desc5, access_type = #tbaa_type_desc2, offset = 12>
#tbaa_tag3 = #llvm.tbaa_tag<base_type = #tbaa_type_desc5, access_type = #tbaa_type_desc2, offset = 28>
#tbaa_tag4 = #llvm.tbaa_tag<base_type = #tbaa_type_desc5, access_type = #tbaa_type_desc2, offset = 16>
#tbaa_tag5 = #llvm.tbaa_tag<base_type = #tbaa_type_desc5, access_type = #tbaa_type_desc2, offset = 32>
#tbaa_tag6 = #llvm.tbaa_tag<base_type = #tbaa_type_desc5, access_type = #tbaa_type_desc2, offset = 20>
#tbaa_tag7 = #llvm.tbaa_tag<base_type = #tbaa_type_desc5, access_type = #tbaa_type_desc1, offset = 0>
#tbaa_tag8 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 0>
#tbaa_tag9 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 4>
#tbaa_tag10 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 8>
#tbaa_tag11 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 12>
#tbaa_tag12 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 16>
#tbaa_tag13 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 20>
#tbaa_tag14 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 24>
#tbaa_tag15 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 28>
#tbaa_tag16 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 32>
#tbaa_tag17 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 36>
#tbaa_tag18 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 40>
#tbaa_tag19 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 44>
#tbaa_tag20 = #llvm.tbaa_tag<base_type = #tbaa_type_desc6, access_type = #tbaa_type_desc2, offset = 48>
#tbaa_tag21 = #llvm.tbaa_tag<base_type = #tbaa_type_desc5, access_type = #tbaa_type_desc2, offset = 8>
#tbaa_type_desc7 = #llvm.tbaa_type_desc<id = "", members = {<#tbaa_type_desc1, 0>, <#tbaa_type_desc2, 8>, <#tbaa_type_desc3, 12>, <#tbaa_type_desc4, 20>}>
#tbaa_type_desc8 = #llvm.tbaa_type_desc<id = "", members = {<#tbaa_type_desc4, 0>, <#tbaa_type_desc4, 12>}>
#tbaa_tag22 = #llvm.tbaa_tag<base_type = #tbaa_type_desc7, access_type = #tbaa_type_desc1, offset = 0>
#tbaa_tag23 = #llvm.tbaa_tag<base_type = #tbaa_type_desc7, access_type = #tbaa_type_desc2, offset = 12>
#tbaa_type_desc9 = #llvm.tbaa_type_desc<id = "", members = {<#tbaa_type_desc7, 0>, <#tbaa_type_desc8, 32>}>
#tbaa_tag24 = #llvm.tbaa_tag<base_type = #tbaa_type_desc9, access_type = #tbaa_type_desc2, offset = 24>
#tbaa_tag25 = #llvm.tbaa_tag<base_type = #tbaa_type_desc9, access_type = #tbaa_type_desc2, offset = 20>
module attributes {dlti.dl_spec = #dlti.dl_spec<#dlti.dl_entry<f128, dense<128> : vector<2xi64>>, #dlti.dl_entry<f64, dense<64> : vector<2xi64>>, #dlti.dl_entry<f16, dense<16> : vector<2xi64>>, #dlti.dl_entry<i32, dense<32> : vector<2xi64>>, #dlti.dl_entry<i16, dense<16> : vector<2xi64>>, #dlti.dl_entry<i8, dense<8> : vector<2xi64>>, #dlti.dl_entry<i1, dense<8> : vector<2xi64>>, #dlti.dl_entry<!llvm.ptr, dense<64> : vector<4xi64>>, #dlti.dl_entry<i64, dense<64> : vector<2xi64>>, #dlti.dl_entry<"dlti.endianness", "little">>} {
  llvm.func local_unnamed_addr spir_funccc @_Z26async_work_group_copy_3D3DPU3AS3vmPU3AS1Kvmmmmmmmmm9ocl_event(%arg0: !llvm.ptr<3> {llvm.noundef}, %arg1: i64 {llvm.noundef}, %arg2: !llvm.ptr<1> {llvm.noundef}, %arg3: i64 {llvm.noundef}, %arg4: i64 {llvm.noundef}, %arg5: i64 {llvm.noundef}, %arg6: i64 {llvm.noundef}, %arg7: i64 {llvm.noundef}, %arg8: i64 {llvm.noundef}, %arg9: i64 {llvm.noundef}, %arg10: i64 {llvm.noundef}, %arg11: i64 {llvm.noundef}, %arg12: !llvm.target<"spirv.Event"> {llvm.returned}) -> !llvm.target<"spirv.Event"> attributes {frame_pointer = #llvm.framePointerKind<all>, passthrough = ["convergent", "noinline", "norecurse", "nounwind", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]} {
    %0 = llvm.mlir.constant(0 : i64) : i64
    %1 = llvm.mlir.constant(1 : i64) : i64
    %2 = llvm.icmp "eq" %arg7, %0 : i64
    llvm.cond_br %2, ^bb2, ^bb1
  ^bb1:  // pred: ^bb0
    %3 = llvm.icmp "eq" %arg6, %0 : i64
    %4 = llvm.mul %arg5, %arg4  : i64
    %5 = llvm.mul %arg8, %arg4  : i64
    %6 = llvm.mul %arg10, %arg4  : i64
    llvm.br ^bb3(%0 : i64)
  ^bb2:  // 2 preds: ^bb0, ^bb5
    llvm.return %arg12 : !llvm.target<"spirv.Event">
  ^bb3(%7: i64):  // 2 preds: ^bb1, ^bb5
    llvm.cond_br %3, ^bb5, ^bb4
  ^bb4:  // pred: ^bb3
    %8 = llvm.mul %7, %arg11  : i64
    %9 = llvm.add %8, %arg1  : i64
    %10 = llvm.mul %9, %arg4  : i64
    %11 = llvm.getelementptr inbounds %arg0[%10] : (!llvm.ptr<3>, i64) -> !llvm.ptr<3>, i8
    %12 = llvm.mul %7, %arg9  : i64
    %13 = llvm.add %12, %arg3  : i64
    %14 = llvm.mul %13, %arg4  : i64
    %15 = llvm.getelementptr inbounds %arg2[%14] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
    llvm.br ^bb6(%0, %11, %15 : i64, !llvm.ptr<3>, !llvm.ptr<1>)
  ^bb5:  // 2 preds: ^bb3, ^bb6
    %16 = llvm.add %7, %1 overflow<nuw>  : i64
    %17 = llvm.icmp "ult" %16, %arg7 : i64
    llvm.cond_br %17, ^bb3(%16 : i64), ^bb2
  ^bb6(%18: i64, %19: !llvm.ptr<3>, %20: !llvm.ptr<1>):  // 2 preds: ^bb4, ^bb6
    %21 = llvm.call spir_funccc @_Z21async_work_group_copyPU3AS3hPU3AS1Khm9ocl_event(%19, %20, %4, %arg12) : (!llvm.ptr<3>, !llvm.ptr<1>, i64, !llvm.target<"spirv.Event">) -> !llvm.target<"spirv.Event">
    %22 = llvm.getelementptr inbounds %20[%5] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
    %23 = llvm.getelementptr inbounds %19[%6] : (!llvm.ptr<3>, i64) -> !llvm.ptr<3>, i8
    %24 = llvm.add %18, %1 overflow<nuw>  : i64
    %25 = llvm.icmp "ult" %24, %arg6 : i64
    llvm.cond_br %25, ^bb6(%24, %23, %22 : i64, !llvm.ptr<3>, !llvm.ptr<1>), ^bb5
  }
  llvm.func local_unnamed_addr spir_funccc @_Z21async_work_group_copyPU3AS3hPU3AS1Khm9ocl_event(!llvm.ptr<3> {llvm.noundef}, !llvm.ptr<1> {llvm.noundef}, i64 {llvm.noundef}, !llvm.target<"spirv.Event">) -> !llvm.target<"spirv.Event"> attributes {frame_pointer = #llvm.framePointerKind<all>, passthrough = ["convergent", "nounwind", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]}
  llvm.func local_unnamed_addr spir_funccc @_Z26async_work_group_copy_3D3DPU3AS1vmPU3AS3Kvmmmmmmmmm9ocl_event(%arg0: !llvm.ptr<1> {llvm.noundef}, %arg1: i64 {llvm.noundef}, %arg2: !llvm.ptr<3> {llvm.noundef}, %arg3: i64 {llvm.noundef}, %arg4: i64 {llvm.noundef}, %arg5: i64 {llvm.noundef}, %arg6: i64 {llvm.noundef}, %arg7: i64 {llvm.noundef}, %arg8: i64 {llvm.noundef}, %arg9: i64 {llvm.noundef}, %arg10: i64 {llvm.noundef}, %arg11: i64 {llvm.noundef}, %arg12: !llvm.target<"spirv.Event"> {llvm.returned}) -> !llvm.target<"spirv.Event"> attributes {frame_pointer = #llvm.framePointerKind<all>, passthrough = ["convergent", "noinline", "norecurse", "nounwind", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]} {
    %0 = llvm.mlir.constant(0 : i64) : i64
    %1 = llvm.mlir.constant(1 : i64) : i64
    %2 = llvm.icmp "eq" %arg7, %0 : i64
    llvm.cond_br %2, ^bb2, ^bb1
  ^bb1:  // pred: ^bb0
    %3 = llvm.icmp "eq" %arg6, %0 : i64
    %4 = llvm.mul %arg5, %arg4  : i64
    %5 = llvm.mul %arg8, %arg4  : i64
    %6 = llvm.mul %arg10, %arg4  : i64
    llvm.br ^bb3(%0 : i64)
  ^bb2:  // 2 preds: ^bb0, ^bb5
    llvm.return %arg12 : !llvm.target<"spirv.Event">
  ^bb3(%7: i64):  // 2 preds: ^bb1, ^bb5
    llvm.cond_br %3, ^bb5, ^bb4
  ^bb4:  // pred: ^bb3
    %8 = llvm.mul %7, %arg11  : i64
    %9 = llvm.add %8, %arg1  : i64
    %10 = llvm.mul %9, %arg4  : i64
    %11 = llvm.getelementptr inbounds %arg0[%10] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
    %12 = llvm.mul %7, %arg9  : i64
    %13 = llvm.add %12, %arg3  : i64
    %14 = llvm.mul %13, %arg4  : i64
    %15 = llvm.getelementptr inbounds %arg2[%14] : (!llvm.ptr<3>, i64) -> !llvm.ptr<3>, i8
    llvm.br ^bb6(%0, %11, %15 : i64, !llvm.ptr<1>, !llvm.ptr<3>)
  ^bb5:  // 2 preds: ^bb3, ^bb6
    %16 = llvm.add %7, %1 overflow<nuw>  : i64
    %17 = llvm.icmp "ult" %16, %arg7 : i64
    llvm.cond_br %17, ^bb3(%16 : i64), ^bb2
  ^bb6(%18: i64, %19: !llvm.ptr<1>, %20: !llvm.ptr<3>):  // 2 preds: ^bb4, ^bb6
    %21 = llvm.call spir_funccc @_Z21async_work_group_copyPU3AS1hPU3AS3Khm9ocl_event(%19, %20, %4, %arg12) : (!llvm.ptr<1>, !llvm.ptr<3>, i64, !llvm.target<"spirv.Event">) -> !llvm.target<"spirv.Event">
    %22 = llvm.getelementptr inbounds %20[%5] : (!llvm.ptr<3>, i64) -> !llvm.ptr<3>, i8
    %23 = llvm.getelementptr inbounds %19[%6] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
    %24 = llvm.add %18, %1 overflow<nuw>  : i64
    %25 = llvm.icmp "ult" %24, %arg6 : i64
    llvm.cond_br %25, ^bb6(%24, %23, %22 : i64, !llvm.ptr<1>, !llvm.ptr<3>), ^bb5
  }
  llvm.func local_unnamed_addr spir_funccc @_Z21async_work_group_copyPU3AS1hPU3AS3Khm9ocl_event(!llvm.ptr<1> {llvm.noundef}, !llvm.ptr<3> {llvm.noundef}, i64 {llvm.noundef}, !llvm.target<"spirv.Event">) -> !llvm.target<"spirv.Event"> attributes {frame_pointer = #llvm.framePointerKind<all>, passthrough = ["convergent", "nounwind", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]}
  llvm.func local_unnamed_addr spir_funccc @compute(%arg0: !llvm.ptr {llvm.align = 8 : i64, llvm.byval = !llvm.struct<"struct.TTL_int_int_sub_tensor_t", (struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>, struct<"struct.anon", (struct<"struct.TTL_shape_t", (i32, i32, i32)>, struct<"struct.TTL_offset_t", (i32, i32, i32)>)>)>, llvm.nocapture, llvm.noundef, llvm.readonly}, %arg1: !llvm.ptr {llvm.align = 8 : i64, llvm.byval = !llvm.struct<"struct.TTL_int_int_sub_tensor_t", (struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>, struct<"struct.anon", (struct<"struct.TTL_shape_t", (i32, i32, i32)>, struct<"struct.TTL_offset_t", (i32, i32, i32)>)>)>, llvm.nocapture, llvm.noundef, llvm.readonly}) attributes {frame_pointer = #llvm.framePointerKind<all>, memory = #llvm.memory_effects<other = readwrite, argMem = readwrite, inaccessibleMem = none>, passthrough = ["nofree", "noinline", "norecurse", "nosync", "nounwind", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]} {
    %0 = llvm.mlir.constant(0 : i64) : i64
    %1 = llvm.mlir.constant(3 : i32) : i32
    %2 = llvm.mlir.constant(1 : i32) : i32
    %3 = llvm.mlir.constant(0 : i32) : i32
    %4 = llvm.mlir.constant(10 : i32) : i32
    %5 = llvm.mlir.constant(9 : i32) : i32
    %6 = llvm.mlir.constant(11 : i32) : i32
    %7 = llvm.getelementptr inbounds %arg1[%0, 3, 1] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>
    %8 = llvm.load %7 {alignment = 8 : i64, tbaa = [#tbaa_tag24]} : !llvm.ptr -> i32
    %9 = llvm.icmp "eq" %8, %3 : i32
    llvm.cond_br %9, ^bb4, ^bb1
  ^bb1:  // pred: ^bb0
    %10 = llvm.getelementptr inbounds %arg1[%0, 3] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>
    %11 = llvm.load %10 {alignment = 4 : i64, tbaa = [#tbaa_tag25]} : !llvm.ptr -> i32
    %12 = llvm.icmp "eq" %11, %3 : i32
    llvm.br ^bb2(%3 : i32)
  ^bb2(%13: i32):  // 2 preds: ^bb1, ^bb5
    llvm.cond_br %12, ^bb5, ^bb3
  ^bb3:  // pred: ^bb2
    %14 = llvm.add %13, %4 overflow<nsw, nuw>  : i32
    %15 = llvm.add %13, %5 overflow<nsw, nuw>  : i32
    %16 = llvm.add %13, %6 overflow<nsw, nuw>  : i32
    llvm.br ^bb6(%3 : i32)
  ^bb4:  // 2 preds: ^bb0, ^bb5
    llvm.return
  ^bb5:  // 2 preds: ^bb2, ^bb6
    %17 = llvm.add %13, %2 overflow<nsw, nuw>  : i32
    %18 = llvm.icmp "ult" %17, %8 : i32
    llvm.cond_br %18, ^bb2(%17 : i32), ^bb4
  ^bb6(%19: i32):  // 2 preds: ^bb3, ^bb6
    %20 = llvm.add %19, %4 overflow<nsw, nuw>  : i32
    %21 = llvm.add %19, %5 overflow<nsw, nuw>  : i32
    %22 = llvm.call spir_funccc @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(%arg0, %21, %14) : (!llvm.ptr, i32, i32) -> i32
    %23 = llvm.call spir_funccc @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(%arg0, %20, %15) : (!llvm.ptr, i32, i32) -> i32
    %24 = llvm.call spir_funccc @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(%arg0, %20, %14) : (!llvm.ptr, i32, i32) -> i32
    %25 = llvm.add %19, %6 overflow<nsw, nuw>  : i32
    %26 = llvm.call spir_funccc @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(%arg0, %25, %14) : (!llvm.ptr, i32, i32) -> i32
    %27 = llvm.call spir_funccc @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(%arg0, %20, %16) : (!llvm.ptr, i32, i32) -> i32
    %28 = llvm.add %23, %22 overflow<nsw>  : i32
    %29 = llvm.add %28, %24 overflow<nsw>  : i32
    %30 = llvm.add %29, %26 overflow<nsw>  : i32
    %31 = llvm.add %30, %27 overflow<nsw>  : i32
    llvm.call spir_funccc @_ZL16TTL_write_tensor24TTL_int_int_sub_tensor_tijj(%arg1, %31, %19, %13) : (!llvm.ptr, i32, i32, i32) -> ()
    %32 = llvm.add %19, %2 overflow<nsw, nuw>  : i32
    %33 = llvm.icmp "ult" %32, %11 : i32
    llvm.cond_br %33, ^bb6(%32 : i32), ^bb5
  }
  llvm.func internal unnamed_addr spir_funccc @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(%arg0: !llvm.ptr {llvm.align = 8 : i64, llvm.byval = !llvm.struct<"struct.TTL_int_int_sub_tensor_t", (struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>, struct<"struct.anon", (struct<"struct.TTL_shape_t", (i32, i32, i32)>, struct<"struct.TTL_offset_t", (i32, i32, i32)>)>)>, llvm.nocapture, llvm.noundef, llvm.readonly}, %arg1: i32 {llvm.noundef}, %arg2: i32 {llvm.noundef}) -> i32 attributes {dso_local, frame_pointer = #llvm.framePointerKind<all>, memory = #llvm.memory_effects<other = read, argMem = read, inaccessibleMem = none>, passthrough = ["mustprogress", "nofree", "noinline", "norecurse", "nosync", "nounwind", "willreturn", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]} {
    %0 = llvm.call spir_funccc @_ZL15TTL_read_tensor20TTL_int_int_tensor_tjjj(%arg0, %arg1, %arg2) : (!llvm.ptr, i32, i32) -> i32
    llvm.return %0 : i32
  }
  llvm.func internal unnamed_addr spir_funccc @_ZL16TTL_write_tensor24TTL_int_int_sub_tensor_tijj(%arg0: !llvm.ptr {llvm.align = 8 : i64, llvm.byval = !llvm.struct<"struct.TTL_int_int_sub_tensor_t", (struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>, struct<"struct.anon", (struct<"struct.TTL_shape_t", (i32, i32, i32)>, struct<"struct.TTL_offset_t", (i32, i32, i32)>)>)>, llvm.nocapture, llvm.noundef, llvm.readonly}, %arg1: i32 {llvm.noundef}, %arg2: i32 {llvm.noundef}, %arg3: i32 {llvm.noundef}) attributes {dso_local, frame_pointer = #llvm.framePointerKind<all>, memory = #llvm.memory_effects<other = write, argMem = readwrite, inaccessibleMem = none>, passthrough = ["mustprogress", "nofree", "noinline", "norecurse", "nosync", "nounwind", "willreturn", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]} {
    llvm.call spir_funccc @_ZL16TTL_write_tensor20TTL_int_int_tensor_tijjj(%arg0, %arg1, %arg2, %arg3) : (!llvm.ptr, i32, i32, i32) -> ()
    llvm.return
  }
  llvm.func local_unnamed_addr spir_funccc @TTL_affine_compute_index(%arg0: !llvm.ptr<4> {llvm.nocapture, llvm.noundef, llvm.readonly}) -> i32 attributes {frame_pointer = #llvm.framePointerKind<all>, memory = #llvm.memory_effects<other = none, argMem = read, inaccessibleMem = none>, passthrough = ["mustprogress", "nofree", "noinline", "norecurse", "nosync", "nounwind", "willreturn", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]} {
    %0 = llvm.mlir.constant(0 : i64) : i64
    %1 = llvm.mlir.constant(5 : i32) : i32
    %2 = llvm.mlir.constant(2 : i32) : i32
    %3 = llvm.mlir.constant(6 : i32) : i32
    %4 = llvm.mlir.constant(3 : i32) : i32
    %5 = llvm.mlir.constant(7 : i32) : i32
    %6 = llvm.mlir.constant(4 : i32) : i32
    %7 = llvm.getelementptr inbounds %arg0[%0, 5] : (!llvm.ptr<4>, i64) -> !llvm.ptr<4>, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %8 = llvm.load %7 {alignment = 8 : i64, tbaa = [#tbaa_tag1]} : !llvm.ptr<4> -> i32
    %9 = llvm.getelementptr inbounds %arg0[%0, 2] : (!llvm.ptr<4>, i64) -> !llvm.ptr<4>, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %10 = llvm.load %9 {alignment = 4 : i64, tbaa = [#tbaa_tag2]} : !llvm.ptr<4> -> i32
    %11 = llvm.mul %10, %8 overflow<nsw>  : i32
    %12 = llvm.getelementptr inbounds %arg0[%0, 6] : (!llvm.ptr<4>, i64) -> !llvm.ptr<4>, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %13 = llvm.load %12 {alignment = 4 : i64, tbaa = [#tbaa_tag3]} : !llvm.ptr<4> -> i32
    %14 = llvm.getelementptr inbounds %arg0[%0, 3] : (!llvm.ptr<4>, i64) -> !llvm.ptr<4>, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %15 = llvm.load %14 {alignment = 8 : i64, tbaa = [#tbaa_tag4]} : !llvm.ptr<4> -> i32
    %16 = llvm.mul %15, %13 overflow<nsw>  : i32
    %17 = llvm.add %16, %11 overflow<nsw>  : i32
    %18 = llvm.getelementptr inbounds %arg0[%0, 7] : (!llvm.ptr<4>, i64) -> !llvm.ptr<4>, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %19 = llvm.load %18 {alignment = 8 : i64, tbaa = [#tbaa_tag5]} : !llvm.ptr<4> -> i32
    %20 = llvm.getelementptr inbounds %arg0[%0, 4] : (!llvm.ptr<4>, i64) -> !llvm.ptr<4>, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %21 = llvm.load %20 {alignment = 4 : i64, tbaa = [#tbaa_tag6]} : !llvm.ptr<4> -> i32
    %22 = llvm.mul %21, %19 overflow<nsw>  : i32
    %23 = llvm.add %17, %22 overflow<nsw>  : i32
    llvm.return %23 : i32
  }
  llvm.func local_unnamed_addr spir_funccc @TTL_loop_affine_matmul_body(%arg0: !llvm.ptr {llvm.align = 4 : i64, llvm.byval = !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>, llvm.nocapture, llvm.noundef, llvm.readnone}, %arg1: !llvm.ptr {llvm.align = 8 : i64, llvm.byval = !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>, llvm.nocapture, llvm.noundef, llvm.readonly}, %arg2: !llvm.ptr {llvm.align = 8 : i64, llvm.byval = !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>, llvm.nocapture, llvm.noundef, llvm.readonly}, %arg3: !llvm.ptr {llvm.align = 8 : i64, llvm.byval = !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>, llvm.nocapture, llvm.noundef, llvm.readonly}) attributes {frame_pointer = #llvm.framePointerKind<all>, memory = #llvm.memory_effects<other = readwrite, argMem = readwrite, inaccessibleMem = none>, passthrough = ["mustprogress", "nofree", "noinline", "norecurse", "nosync", "nounwind", "willreturn", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]} {
    %0 = llvm.addrspacecast %arg1 : !llvm.ptr to !llvm.ptr<4>
    %1 = llvm.call spir_funccc @TTL_affine_compute_index(%0) : (!llvm.ptr<4>) -> i32
    %2 = llvm.addrspacecast %arg2 : !llvm.ptr to !llvm.ptr<4>
    %3 = llvm.call spir_funccc @TTL_affine_compute_index(%2) : (!llvm.ptr<4>) -> i32
    %4 = llvm.addrspacecast %arg3 : !llvm.ptr to !llvm.ptr<4>
    %5 = llvm.call spir_funccc @TTL_affine_compute_index(%4) : (!llvm.ptr<4>) -> i32
    %6 = llvm.load %arg1 {alignment = 8 : i64, tbaa = [#tbaa_tag7]} : !llvm.ptr -> !llvm.ptr<1>
    %7 = llvm.sext %1 : i32 to i64
    %8 = llvm.getelementptr inbounds %6[%7] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i32
    %9 = llvm.load %8 {alignment = 4 : i64, tbaa = [#tbaa_tag]} : !llvm.ptr<1> -> i32
    %10 = llvm.load %arg2 {alignment = 8 : i64, tbaa = [#tbaa_tag7]} : !llvm.ptr -> !llvm.ptr<1>
    %11 = llvm.sext %3 : i32 to i64
    %12 = llvm.getelementptr inbounds %10[%11] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i32
    %13 = llvm.load %12 {alignment = 4 : i64, tbaa = [#tbaa_tag]} : !llvm.ptr<1> -> i32
    %14 = llvm.mul %13, %9 overflow<nsw>  : i32
    %15 = llvm.load %arg3 {alignment = 8 : i64, tbaa = [#tbaa_tag7]} : !llvm.ptr -> !llvm.ptr<1>
    %16 = llvm.sext %5 : i32 to i64
    %17 = llvm.getelementptr inbounds %15[%16] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i32
    %18 = llvm.load %17 {alignment = 4 : i64, tbaa = [#tbaa_tag]} : !llvm.ptr<1> -> i32
    %19 = llvm.add %18, %14 overflow<nsw>  : i32
    llvm.store %19, %17 {alignment = 4 : i64, tbaa = [#tbaa_tag]} : i32, !llvm.ptr<1>
    llvm.return
  }
  llvm.func local_unnamed_addr spir_kernelcc @TTL_matmul_kernel(%arg0: !llvm.ptr<1> {llvm.align = 4 : i64, llvm.noalias, llvm.noundef}, %arg1: i32 {llvm.noundef}, %arg2: i32 {llvm.noundef}, %arg3: !llvm.ptr<1> {llvm.align = 4 : i64, llvm.noalias, llvm.noundef}, %arg4: i32 {llvm.noundef}, %arg5: i32 {llvm.noundef}, %arg6: !llvm.ptr<1> {llvm.align = 4 : i64, llvm.noalias, llvm.noundef}, %arg7: i32 {llvm.noundef}, %arg8: i32 {llvm.noundef}, %arg9: i32 {llvm.noundef}, %arg10: i32 {llvm.noundef}, %arg11: i32 {llvm.noundef}) attributes {frame_pointer = #llvm.framePointerKind<all>, passthrough = ["nofree", "noinline", "norecurse", "nounwind", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"], ["uniform-work-group-size", "false"]]} {
    %0 = llvm.mlir.constant(1 : i32) : i32
    %1 = llvm.mlir.constant(3 : i32) : i32
    %2 = llvm.mlir.constant(0 : i64) : i64
    %3 = llvm.mlir.constant(0 : i32) : i32
    %4 = llvm.mlir.constant(2 : i32) : i32
    %5 = llvm.mlir.constant(4 : i32) : i32
    %6 = llvm.mlir.constant(5 : i32) : i32
    %7 = llvm.mlir.constant(6 : i32) : i32
    %8 = llvm.mlir.constant(7 : i32) : i32
    %9 = llvm.mlir.constant(8 : i32) : i32
    %10 = llvm.mlir.constant(9 : i32) : i32
    %11 = llvm.mlir.constant(10 : i32) : i32
    %12 = llvm.mlir.constant(11 : i32) : i32
    %13 = llvm.mlir.constant(12 : i32) : i32
    %14 = llvm.alloca %0 x !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)> {alignment = 4 : i64} : (i32) -> !llvm.ptr
    %15 = llvm.alloca %0 x !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)> {alignment = 8 : i64} : (i32) -> !llvm.ptr
    %16 = llvm.alloca %0 x !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)> {alignment = 8 : i64} : (i32) -> !llvm.ptr
    %17 = llvm.alloca %0 x !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)> {alignment = 8 : i64} : (i32) -> !llvm.ptr
    llvm.intr.lifetime.start 52, %14 : !llvm.ptr
    llvm.store %1, %14 {alignment = 4 : i64, tbaa = [#tbaa_tag8]} : i32, !llvm.ptr
    %18 = llvm.getelementptr inbounds %14[%2, 1] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %3, %18 {alignment = 4 : i64, tbaa = [#tbaa_tag9]} : i32, !llvm.ptr
    %19 = llvm.getelementptr inbounds %14[%2, 2] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %arg9, %19 {alignment = 4 : i64, tbaa = [#tbaa_tag10]} : i32, !llvm.ptr
    %20 = llvm.getelementptr inbounds %14[%2, 3] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %4, %20 {alignment = 4 : i64, tbaa = [#tbaa_tag11]} : i32, !llvm.ptr
    %21 = llvm.getelementptr inbounds %14[%2, 4] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %3, %21 {alignment = 4 : i64, tbaa = [#tbaa_tag12]} : i32, !llvm.ptr
    %22 = llvm.getelementptr inbounds %14[%2, 5] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %3, %22 {alignment = 4 : i64, tbaa = [#tbaa_tag13]} : i32, !llvm.ptr
    %23 = llvm.getelementptr inbounds %14[%2, 6] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %arg10, %23 {alignment = 4 : i64, tbaa = [#tbaa_tag14]} : i32, !llvm.ptr
    %24 = llvm.getelementptr inbounds %14[%2, 7] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %1, %24 {alignment = 4 : i64, tbaa = [#tbaa_tag15]} : i32, !llvm.ptr
    %25 = llvm.getelementptr inbounds %14[%2, 8] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %0, %25 {alignment = 4 : i64, tbaa = [#tbaa_tag16]} : i32, !llvm.ptr
    %26 = llvm.getelementptr inbounds %14[%2, 9] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %3, %26 {alignment = 4 : i64, tbaa = [#tbaa_tag17]} : i32, !llvm.ptr
    %27 = llvm.getelementptr inbounds %14[%2, 10] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %arg11, %27 {alignment = 4 : i64, tbaa = [#tbaa_tag18]} : i32, !llvm.ptr
    %28 = llvm.getelementptr inbounds %14[%2, 11] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %5, %28 {alignment = 4 : i64, tbaa = [#tbaa_tag19]} : i32, !llvm.ptr
    %29 = llvm.getelementptr inbounds %14[%2, 12] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_loop_affine_t", (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store volatile %4, %29 {alignment = 4 : i64, tbaa = [#tbaa_tag20]} : i32, !llvm.ptr
    llvm.intr.lifetime.start 40, %15 : !llvm.ptr
    llvm.store %arg0, %15 {alignment = 8 : i64, tbaa = [#tbaa_tag7]} : !llvm.ptr<1>, !llvm.ptr
    %30 = llvm.getelementptr inbounds %15[%2, 1] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %4, %30 {alignment = 8 : i64, tbaa = [#tbaa_tag21]} : i32, !llvm.ptr
    %31 = llvm.getelementptr inbounds %15[%2, 2] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %0, %31 {alignment = 4 : i64, tbaa = [#tbaa_tag2]} : i32, !llvm.ptr
    %32 = llvm.getelementptr inbounds %15[%2, 3] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %arg1, %32 {alignment = 8 : i64, tbaa = [#tbaa_tag4]} : i32, !llvm.ptr
    %33 = llvm.getelementptr inbounds %15[%2, 4] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %3, %33 {alignment = 4 : i64, tbaa = [#tbaa_tag6]} : i32, !llvm.ptr
    %34 = llvm.getelementptr inbounds %15[%2, 5] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %35 = llvm.load volatile %21 {alignment = 4 : i64, tbaa = [#tbaa_tag12]} : !llvm.ptr -> i32
    llvm.store %35, %34 {alignment = 8 : i64, tbaa = [#tbaa_tag1]} : i32, !llvm.ptr
    %36 = llvm.getelementptr inbounds %15[%2, 6] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %37 = llvm.load volatile %29 {alignment = 4 : i64, tbaa = [#tbaa_tag20]} : !llvm.ptr -> i32
    llvm.store %37, %36 {alignment = 4 : i64, tbaa = [#tbaa_tag3]} : i32, !llvm.ptr
    %38 = llvm.getelementptr inbounds %15[%2, 7] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %3, %38 {alignment = 8 : i64, tbaa = [#tbaa_tag5]} : i32, !llvm.ptr
    llvm.intr.lifetime.start 40, %16 : !llvm.ptr
    llvm.store %arg3, %16 {alignment = 8 : i64, tbaa = [#tbaa_tag7]} : !llvm.ptr<1>, !llvm.ptr
    %39 = llvm.getelementptr inbounds %16[%2, 1] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %4, %39 {alignment = 8 : i64, tbaa = [#tbaa_tag21]} : i32, !llvm.ptr
    %40 = llvm.getelementptr inbounds %16[%2, 2] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %0, %40 {alignment = 4 : i64, tbaa = [#tbaa_tag2]} : i32, !llvm.ptr
    %41 = llvm.getelementptr inbounds %16[%2, 3] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %arg4, %41 {alignment = 8 : i64, tbaa = [#tbaa_tag4]} : i32, !llvm.ptr
    %42 = llvm.getelementptr inbounds %16[%2, 4] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %3, %42 {alignment = 4 : i64, tbaa = [#tbaa_tag6]} : i32, !llvm.ptr
    %43 = llvm.getelementptr inbounds %16[%2, 5] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %44 = llvm.load volatile %29 {alignment = 4 : i64, tbaa = [#tbaa_tag20]} : !llvm.ptr -> i32
    llvm.store %44, %43 {alignment = 8 : i64, tbaa = [#tbaa_tag1]} : i32, !llvm.ptr
    %45 = llvm.getelementptr inbounds %16[%2, 6] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %46 = llvm.load volatile %25 {alignment = 4 : i64, tbaa = [#tbaa_tag16]} : !llvm.ptr -> i32
    llvm.store %46, %45 {alignment = 4 : i64, tbaa = [#tbaa_tag3]} : i32, !llvm.ptr
    %47 = llvm.getelementptr inbounds %16[%2, 7] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %3, %47 {alignment = 8 : i64, tbaa = [#tbaa_tag5]} : i32, !llvm.ptr
    llvm.intr.lifetime.start 40, %17 : !llvm.ptr
    llvm.store %arg6, %17 {alignment = 8 : i64, tbaa = [#tbaa_tag7]} : !llvm.ptr<1>, !llvm.ptr
    %48 = llvm.getelementptr inbounds %17[%2, 1] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %4, %48 {alignment = 8 : i64, tbaa = [#tbaa_tag21]} : i32, !llvm.ptr
    %49 = llvm.getelementptr inbounds %17[%2, 2] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %0, %49 {alignment = 4 : i64, tbaa = [#tbaa_tag2]} : i32, !llvm.ptr
    %50 = llvm.getelementptr inbounds %17[%2, 3] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %arg7, %50 {alignment = 8 : i64, tbaa = [#tbaa_tag4]} : i32, !llvm.ptr
    %51 = llvm.getelementptr inbounds %17[%2, 4] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %3, %51 {alignment = 4 : i64, tbaa = [#tbaa_tag6]} : i32, !llvm.ptr
    %52 = llvm.getelementptr inbounds %17[%2, 5] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %53 = llvm.load volatile %21 {alignment = 4 : i64, tbaa = [#tbaa_tag12]} : !llvm.ptr -> i32
    llvm.store %53, %52 {alignment = 8 : i64, tbaa = [#tbaa_tag1]} : i32, !llvm.ptr
    %54 = llvm.getelementptr inbounds %17[%2, 6] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    %55 = llvm.load volatile %25 {alignment = 4 : i64, tbaa = [#tbaa_tag16]} : !llvm.ptr -> i32
    llvm.store %55, %54 {alignment = 4 : i64, tbaa = [#tbaa_tag3]} : i32, !llvm.ptr
    %56 = llvm.getelementptr inbounds %17[%2, 7] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_affine_access_t", (ptr<1>, i32, i32, i32, i32, i32, i32, i32)>
    llvm.store %3, %56 {alignment = 8 : i64, tbaa = [#tbaa_tag5]} : i32, !llvm.ptr
    llvm.call spir_funccc @TTL_loop_affine_matmul_body(%14, %15, %16, %17) : (!llvm.ptr, !llvm.ptr, !llvm.ptr, !llvm.ptr) -> ()
    llvm.intr.lifetime.end 40, %17 : !llvm.ptr
    llvm.intr.lifetime.end 40, %16 : !llvm.ptr
    llvm.intr.lifetime.end 40, %15 : !llvm.ptr
    llvm.intr.lifetime.end 52, %14 : !llvm.ptr
    llvm.return
  }
  llvm.func internal unnamed_addr spir_funccc @_ZL15TTL_read_tensor20TTL_int_int_tensor_tjjj(%arg0: !llvm.ptr {llvm.align = 8 : i64, llvm.byval = !llvm.struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>, llvm.nocapture, llvm.noundef, llvm.readonly}, %arg1: i32 {llvm.noundef}, %arg2: i32 {llvm.noundef}) -> i32 attributes {dso_local, frame_pointer = #llvm.framePointerKind<all>, memory = #llvm.memory_effects<other = read, argMem = read, inaccessibleMem = none>, passthrough = ["mustprogress", "nofree", "noinline", "norecurse", "nosync", "nounwind", "willreturn", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]} {
    %0 = llvm.mlir.constant(0 : i64) : i64
    %1 = llvm.mlir.constant(2 : i32) : i32
    %2 = llvm.load %arg0 {alignment = 8 : i64, tbaa = [#tbaa_tag22]} : !llvm.ptr -> !llvm.ptr<3>
    %3 = llvm.getelementptr inbounds %arg0[%0, 2] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>
    %4 = llvm.load %3 {alignment = 4 : i64, tbaa = [#tbaa_tag23]} : !llvm.ptr -> i32
    %5 = llvm.mul %4, %arg2  : i32
    %6 = llvm.add %5, %arg1  : i32
    %7 = llvm.zext %6 : i32 to i64
    %8 = llvm.getelementptr inbounds %2[%7] : (!llvm.ptr<3>, i64) -> !llvm.ptr<3>, i32
    %9 = llvm.load %8 {alignment = 4 : i64, tbaa = [#tbaa_tag]} : !llvm.ptr<3> -> i32
    llvm.return %9 : i32
  }
  llvm.func internal unnamed_addr spir_funccc @_ZL16TTL_write_tensor20TTL_int_int_tensor_tijjj(%arg0: !llvm.ptr {llvm.align = 8 : i64, llvm.byval = !llvm.struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>, llvm.nocapture, llvm.noundef, llvm.readonly}, %arg1: i32 {llvm.noundef}, %arg2: i32 {llvm.noundef}, %arg3: i32 {llvm.noundef}) attributes {dso_local, frame_pointer = #llvm.framePointerKind<all>, memory = #llvm.memory_effects<other = write, argMem = readwrite, inaccessibleMem = none>, passthrough = ["mustprogress", "nofree", "noinline", "norecurse", "nosync", "nounwind", "willreturn", ["no-trapping-math", "true"], ["stack-protector-buffer-size", "8"]]} {
    %0 = llvm.mlir.constant(0 : i64) : i64
    %1 = llvm.mlir.constant(2 : i32) : i32
    %2 = llvm.load %arg0 {alignment = 8 : i64, tbaa = [#tbaa_tag22]} : !llvm.ptr -> !llvm.ptr<3>
    %3 = llvm.getelementptr inbounds %arg0[%0, 2] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<"struct.TTL_int_int_tensor_t", (ptr<3>, i32, struct<"struct.TTL_layout_t", (i32, i32)>, struct<"struct.TTL_shape_t", (i32, i32, i32)>)>
    %4 = llvm.load %3 {alignment = 4 : i64, tbaa = [#tbaa_tag23]} : !llvm.ptr -> i32
    %5 = llvm.mul %4, %arg3  : i32
    %6 = llvm.add %5, %arg2  : i32
    %7 = llvm.zext %6 : i32 to i64
    %8 = llvm.getelementptr inbounds %2[%7] : (!llvm.ptr<3>, i64) -> !llvm.ptr<3>, i32
    llvm.store %arg1, %8 {alignment = 4 : i64, tbaa = [#tbaa_tag]} : i32, !llvm.ptr<3>
    llvm.return
  }
}

