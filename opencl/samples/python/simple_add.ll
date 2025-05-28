; ModuleID = 'simple_add.cl'
source_filename = "simple_add.cl"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%struct.TTL_int_int_sub_tensor_t = type { %struct.TTL_int_int_tensor_t, %struct.anon }
%struct.TTL_int_int_tensor_t = type { ptr addrspace(3), i32, %struct.TTL_layout_t, %struct.TTL_shape_t }
%struct.TTL_layout_t = type { i32, i32 }
%struct.TTL_shape_t = type { i32, i32, i32 }
%struct.anon = type { %struct.TTL_shape_t, %struct.TTL_offset_t }
%struct.TTL_offset_t = type { i32, i32, i32 }
%struct.loop_affine_t = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }
%struct.tensor_access_t = type { ptr addrspace(1), i32, i32 }

; Function Attrs: convergent noinline norecurse nounwind
define dso_local spir_func target("spirv.Event") @_Z26async_work_group_copy_3D3DPU3AS3vmPU3AS1Kvmmmmmmmmm9ocl_event(ptr addrspace(3) noundef %0, i64 noundef %1, ptr addrspace(1) noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, i64 noundef %9, i64 noundef %10, i64 noundef %11, target("spirv.Event") returned %12) local_unnamed_addr #0 {
  %14 = icmp eq i64 %7, 0
  br i1 %14, label %20, label %15

15:                                               ; preds = %13
  %16 = icmp eq i64 %6, 0
  %17 = mul i64 %5, %4
  %18 = mul i64 %8, %4
  %19 = mul i64 %10, %4
  br label %21

20:                                               ; preds = %32, %13
  ret target("spirv.Event") %12

21:                                               ; preds = %15, %32
  %22 = phi i64 [ 0, %15 ], [ %33, %32 ]
  br i1 %16, label %32, label %23

23:                                               ; preds = %21
  %24 = mul i64 %22, %11
  %25 = add i64 %24, %1
  %26 = mul i64 %25, %4
  %27 = getelementptr inbounds i8, ptr addrspace(3) %0, i64 %26
  %28 = mul i64 %22, %9
  %29 = add i64 %28, %3
  %30 = mul i64 %29, %4
  %31 = getelementptr inbounds i8, ptr addrspace(1) %2, i64 %30
  br label %35

32:                                               ; preds = %35, %21
  %33 = add nuw i64 %22, 1
  %34 = icmp ult i64 %33, %7
  br i1 %34, label %21, label %20

35:                                               ; preds = %23, %35
  %36 = phi i64 [ %42, %35 ], [ 0, %23 ]
  %37 = phi ptr addrspace(3) [ %41, %35 ], [ %27, %23 ]
  %38 = phi ptr addrspace(1) [ %40, %35 ], [ %31, %23 ]
  %39 = tail call spir_func target("spirv.Event") @_Z21async_work_group_copyPU3AS3hPU3AS1Khm9ocl_event(ptr addrspace(3) noundef %37, ptr addrspace(1) noundef %38, i64 noundef %17, target("spirv.Event") %12) #10
  %40 = getelementptr inbounds i8, ptr addrspace(1) %38, i64 %18
  %41 = getelementptr inbounds i8, ptr addrspace(3) %37, i64 %19
  %42 = add nuw i64 %36, 1
  %43 = icmp ult i64 %42, %6
  br i1 %43, label %35, label %32
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: convergent nounwind
declare dso_local spir_func target("spirv.Event") @_Z21async_work_group_copyPU3AS3hPU3AS1Khm9ocl_event(ptr addrspace(3) noundef, ptr addrspace(1) noundef, i64 noundef, target("spirv.Event")) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: convergent noinline norecurse nounwind
define dso_local spir_func target("spirv.Event") @_Z26async_work_group_copy_3D3DPU3AS1vmPU3AS3Kvmmmmmmmmm9ocl_event(ptr addrspace(1) noundef %0, i64 noundef %1, ptr addrspace(3) noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, i64 noundef %9, i64 noundef %10, i64 noundef %11, target("spirv.Event") returned %12) local_unnamed_addr #0 {
  %14 = icmp eq i64 %7, 0
  br i1 %14, label %20, label %15

15:                                               ; preds = %13
  %16 = icmp eq i64 %6, 0
  %17 = mul i64 %5, %4
  %18 = mul i64 %8, %4
  %19 = mul i64 %10, %4
  br label %21

20:                                               ; preds = %32, %13
  ret target("spirv.Event") %12

21:                                               ; preds = %15, %32
  %22 = phi i64 [ 0, %15 ], [ %33, %32 ]
  br i1 %16, label %32, label %23

23:                                               ; preds = %21
  %24 = mul i64 %22, %11
  %25 = add i64 %24, %1
  %26 = mul i64 %25, %4
  %27 = getelementptr inbounds i8, ptr addrspace(1) %0, i64 %26
  %28 = mul i64 %22, %9
  %29 = add i64 %28, %3
  %30 = mul i64 %29, %4
  %31 = getelementptr inbounds i8, ptr addrspace(3) %2, i64 %30
  br label %35

32:                                               ; preds = %35, %21
  %33 = add nuw i64 %22, 1
  %34 = icmp ult i64 %33, %7
  br i1 %34, label %21, label %20

35:                                               ; preds = %23, %35
  %36 = phi i64 [ %42, %35 ], [ 0, %23 ]
  %37 = phi ptr addrspace(1) [ %41, %35 ], [ %27, %23 ]
  %38 = phi ptr addrspace(3) [ %40, %35 ], [ %31, %23 ]
  %39 = tail call spir_func target("spirv.Event") @_Z21async_work_group_copyPU3AS1hPU3AS3Khm9ocl_event(ptr addrspace(1) noundef %37, ptr addrspace(3) noundef %38, i64 noundef %17, target("spirv.Event") %12) #10
  %40 = getelementptr inbounds i8, ptr addrspace(3) %38, i64 %18
  %41 = getelementptr inbounds i8, ptr addrspace(1) %37, i64 %19
  %42 = add nuw i64 %36, 1
  %43 = icmp ult i64 %42, %6
  br i1 %43, label %35, label %32
}

; Function Attrs: convergent nounwind
declare dso_local spir_func target("spirv.Event") @_Z21async_work_group_copyPU3AS1hPU3AS3Khm9ocl_event(ptr addrspace(1) noundef, ptr addrspace(3) noundef, i64 noundef, target("spirv.Event")) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind memory(readwrite, inaccessiblemem: none)
define dso_local spir_func void @compute(ptr nocapture noundef readonly byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, ptr nocapture noundef readonly byval(%struct.TTL_int_int_sub_tensor_t) align 8 %1) local_unnamed_addr #3 {
  %3 = getelementptr inbounds %struct.TTL_int_int_tensor_t, ptr %1, i64 0, i32 3, i32 1
  %4 = load i32, ptr %3, align 8, !tbaa !4
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %16, label %6

6:                                                ; preds = %2
  %7 = getelementptr inbounds %struct.TTL_int_int_tensor_t, ptr %1, i64 0, i32 3
  %8 = load i32, ptr %7, align 4, !tbaa !14
  %9 = icmp eq i32 %8, 0
  br label %10

10:                                               ; preds = %6, %17
  %11 = phi i32 [ 0, %6 ], [ %18, %17 ]
  br i1 %9, label %17, label %12

12:                                               ; preds = %10
  %13 = add nuw nsw i32 %11, 10
  %14 = add nuw nsw i32 %11, 9
  %15 = add nuw nsw i32 %11, 11
  br label %20

16:                                               ; preds = %17, %2
  ret void

17:                                               ; preds = %20, %10
  %18 = add nuw nsw i32 %11, 1
  %19 = icmp ult i32 %18, %4
  br i1 %19, label %10, label %16

20:                                               ; preds = %12, %20
  %21 = phi i32 [ 0, %12 ], [ %34, %20 ]
  %22 = add nuw nsw i32 %21, 10
  %23 = add nuw nsw i32 %21, 9
  %24 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %23, i32 noundef %13) #11
  %25 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %22, i32 noundef %14) #11
  %26 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %22, i32 noundef %13) #11
  %27 = add nuw nsw i32 %21, 11
  %28 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %27, i32 noundef %13) #11
  %29 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %22, i32 noundef %15) #11
  %30 = add nsw i32 %25, %24
  %31 = add nsw i32 %30, %26
  %32 = add nsw i32 %31, %28
  %33 = add nsw i32 %32, %29
  tail call spir_func void @_ZL16TTL_write_tensor24TTL_int_int_sub_tensor_tijj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %1, i32 noundef %33, i32 noundef %21, i32 noundef %11) #11
  %34 = add nuw nsw i32 %21, 1
  %35 = icmp ult i32 %34, %8
  br i1 %35, label %20, label %17
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(read, inaccessiblemem: none)
define internal spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr nocapture noundef readonly byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #4 {
  %4 = tail call spir_func i32 @_ZL15TTL_read_tensor20TTL_int_int_tensor_tjjj(ptr noundef nonnull byval(%struct.TTL_int_int_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2) #11
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(write, argmem: readwrite, inaccessiblemem: none)
define internal spir_func void @_ZL16TTL_write_tensor24TTL_int_int_sub_tensor_tijj(ptr nocapture noundef readonly byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) unnamed_addr #5 {
  tail call spir_func void @_ZL16TTL_write_tensor20TTL_int_int_tensor_tijjj(ptr noundef nonnull byval(%struct.TTL_int_int_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #11
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nounwind willreturn
define dso_local spir_func void @loop_affine_matmul_body(ptr noundef byval(%struct.loop_affine_t) align 4 %0, ptr nocapture noundef readonly byval(%struct.tensor_access_t) align 8 %1, ptr nocapture noundef readonly byval(%struct.tensor_access_t) align 8 %2) local_unnamed_addr #6 {
  %4 = alloca %struct.TTL_layout_t, align 4
  %5 = alloca %struct.TTL_layout_t, align 4
  %6 = alloca %struct.TTL_offset_t, align 4
  %7 = alloca %struct.TTL_offset_t, align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #11
  %8 = getelementptr inbounds %struct.tensor_access_t, ptr %1, i64 0, i32 1
  %9 = load i32, ptr %8, align 8, !tbaa !15
  %10 = getelementptr inbounds %struct.tensor_access_t, ptr %1, i64 0, i32 2
  %11 = load i32, ptr %10, align 4, !tbaa !17
  call spir_func void @_ZL17TTL_create_layoutjj(ptr dead_on_unwind nonnull writable sret(%struct.TTL_layout_t) align 4 %4, i32 noundef %9, i32 noundef %11) #11
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #11
  %12 = getelementptr inbounds %struct.tensor_access_t, ptr %2, i64 0, i32 1
  %13 = load i32, ptr %12, align 8, !tbaa !15
  %14 = getelementptr inbounds %struct.tensor_access_t, ptr %2, i64 0, i32 2
  %15 = load i32, ptr %14, align 4, !tbaa !17
  call spir_func void @_ZL17TTL_create_layoutjj(ptr dead_on_unwind nonnull writable sret(%struct.TTL_layout_t) align 4 %5, i32 noundef %13, i32 noundef %15) #11
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %6) #11
  %16 = getelementptr inbounds %struct.loop_affine_t, ptr %0, i64 0, i32 4
  %17 = load volatile i32, ptr %16, align 4, !tbaa !18
  %18 = getelementptr inbounds %struct.loop_affine_t, ptr %0, i64 0, i32 12
  %19 = load volatile i32, ptr %18, align 4, !tbaa !20
  call spir_func void @_ZL17TTL_create_offsetiii(ptr dead_on_unwind nonnull writable sret(%struct.TTL_offset_t) align 4 %6, i32 noundef %17, i32 noundef %19) #11
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %7) #11
  %20 = load volatile i32, ptr %18, align 4, !tbaa !20
  %21 = getelementptr inbounds %struct.loop_affine_t, ptr %0, i64 0, i32 8
  %22 = load volatile i32, ptr %21, align 4, !tbaa !21
  call spir_func void @_ZL17TTL_create_offsetiii(ptr dead_on_unwind nonnull writable sret(%struct.TTL_offset_t) align 4 %7, i32 noundef %20, i32 noundef %22) #11
  %23 = load volatile i32, ptr %16, align 4, !tbaa !18
  %24 = load volatile i32, ptr %21, align 4, !tbaa !21
  %25 = tail call spir_func i32 @TTL_linearize(ptr noundef nonnull byval(%struct.TTL_offset_t) align 4 %6, ptr noundef nonnull byval(%struct.TTL_layout_t) align 4 %4) #11
  %26 = tail call spir_func i32 @TTL_linearize(ptr noundef nonnull byval(%struct.TTL_offset_t) align 4 %7, ptr noundef nonnull byval(%struct.TTL_layout_t) align 4 %5) #11
  %27 = load ptr addrspace(1), ptr %2, align 8, !tbaa !22
  %28 = sext i32 %26 to i64
  %29 = getelementptr inbounds i32, ptr addrspace(1) %27, i64 %28
  %30 = load i32, ptr addrspace(1) %29, align 4, !tbaa !23
  %31 = load ptr addrspace(1), ptr %1, align 8, !tbaa !22
  %32 = sext i32 %25 to i64
  %33 = getelementptr inbounds i32, ptr addrspace(1) %31, i64 %32
  store i32 %30, ptr addrspace(1) %33, align 4, !tbaa !23
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %7) #11
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %6) #11
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #11
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #11
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: write)
define internal spir_func void @_ZL17TTL_create_layoutjj(ptr dead_on_unwind noalias nocapture writable writeonly sret(%struct.TTL_layout_t) align 4 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #7 {
  store i32 %1, ptr %0, align 4, !tbaa !24
  %4 = getelementptr inbounds %struct.TTL_layout_t, ptr %0, i64 0, i32 1
  store i32 %2, ptr %4, align 4, !tbaa !25
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: write)
define internal spir_func void @_ZL17TTL_create_offsetiii(ptr dead_on_unwind noalias nocapture writable writeonly sret(%struct.TTL_offset_t) align 4 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #7 {
  store i32 %1, ptr %0, align 4, !tbaa !26
  %4 = getelementptr inbounds %struct.TTL_offset_t, ptr %0, i64 0, i32 1
  store i32 %2, ptr %4, align 4, !tbaa !27
  %5 = getelementptr inbounds %struct.TTL_offset_t, ptr %0, i64 0, i32 2
  store i32 0, ptr %5, align 4, !tbaa !28
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: read)
define internal spir_func i32 @TTL_linearize(ptr nocapture noundef readonly byval(%struct.TTL_offset_t) align 4 %0, ptr nocapture noundef readonly byval(%struct.TTL_layout_t) align 4 %1) unnamed_addr #8 {
  %3 = getelementptr inbounds %struct.TTL_offset_t, ptr %0, i64 0, i32 2
  %4 = load i32, ptr %3, align 4, !tbaa !28
  %5 = getelementptr inbounds %struct.TTL_layout_t, ptr %1, i64 0, i32 1
  %6 = load i32, ptr %5, align 4, !tbaa !25
  %7 = mul i32 %6, %4
  %8 = getelementptr inbounds %struct.TTL_offset_t, ptr %0, i64 0, i32 1
  %9 = load i32, ptr %8, align 4, !tbaa !27
  %10 = load i32, ptr %1, align 4, !tbaa !24
  %11 = mul i32 %10, %9
  %12 = add i32 %11, %7
  %13 = load i32, ptr %0, align 4, !tbaa !26
  %14 = add i32 %12, %13
  ret i32 %14
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local spir_kernel void @matmul_kernel(ptr addrspace(1) noalias noundef align 4 %0, i32 noundef %1, i32 noundef %2, ptr addrspace(1) noalias noundef align 4 %3, i32 noundef %4, i32 noundef %5, ptr addrspace(1) noalias nocapture noundef readnone align 4 %6, i32 noundef %7, i32 noundef %8, i32 noundef %9, i32 noundef %10, i32 noundef %11) local_unnamed_addr #9 !kernel_arg_addr_space !29 !kernel_arg_access_qual !30 !kernel_arg_type !31 !kernel_arg_base_type !31 !kernel_arg_type_qual !32 {
  %13 = alloca %struct.loop_affine_t, align 4
  %14 = alloca %struct.tensor_access_t, align 8
  %15 = alloca %struct.tensor_access_t, align 8
  call void @llvm.lifetime.start.p0(i64 52, ptr nonnull %13) #11
  store volatile i32 2, ptr %13, align 4, !tbaa !33
  %16 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 1
  store volatile i32 1, ptr %16, align 4, !tbaa !34
  %17 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 2
  store volatile i32 %9, ptr %17, align 4, !tbaa !35
  %18 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 3
  store volatile i32 3, ptr %18, align 4, !tbaa !36
  %19 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 4
  store volatile i32 0, ptr %19, align 4, !tbaa !18
  %20 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 5
  store volatile i32 2, ptr %20, align 4, !tbaa !37
  %21 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 6
  store volatile i32 %10, ptr %21, align 4, !tbaa !38
  %22 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 7
  store volatile i32 2, ptr %22, align 4, !tbaa !39
  %23 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 8
  store volatile i32 0, ptr %23, align 4, !tbaa !21
  %24 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 9
  store volatile i32 3, ptr %24, align 4, !tbaa !40
  %25 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 10
  store volatile i32 %11, ptr %25, align 4, !tbaa !41
  %26 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 11
  store volatile i32 1, ptr %26, align 4, !tbaa !42
  %27 = getelementptr inbounds %struct.loop_affine_t, ptr %13, i64 0, i32 12
  store volatile i32 0, ptr %27, align 4, !tbaa !20
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %14) #11
  store ptr addrspace(1) %0, ptr %14, align 8, !tbaa !22
  %28 = getelementptr inbounds %struct.tensor_access_t, ptr %14, i64 0, i32 1
  store i32 0, ptr %28, align 8, !tbaa !15
  %29 = getelementptr inbounds %struct.tensor_access_t, ptr %14, i64 0, i32 2
  store i32 1, ptr %29, align 4, !tbaa !17
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %15) #11
  store ptr addrspace(1) %3, ptr %15, align 8, !tbaa !22
  %30 = getelementptr inbounds %struct.tensor_access_t, ptr %15, i64 0, i32 1
  store i32 %4, ptr %30, align 8, !tbaa !15
  %31 = getelementptr inbounds %struct.tensor_access_t, ptr %15, i64 0, i32 2
  store i32 %5, ptr %31, align 4, !tbaa !17
  tail call spir_func void @loop_affine_matmul_body(ptr noundef nonnull byval(%struct.loop_affine_t) align 4 %13, ptr noundef nonnull byval(%struct.tensor_access_t) align 8 %14, ptr noundef nonnull byval(%struct.tensor_access_t) align 8 %15) #11
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %15) #11
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %14) #11
  call void @llvm.lifetime.end.p0(i64 52, ptr nonnull %13) #11
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(read, inaccessiblemem: none)
define internal spir_func i32 @_ZL15TTL_read_tensor20TTL_int_int_tensor_tjjj(ptr nocapture noundef readonly byval(%struct.TTL_int_int_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #4 {
  %4 = load ptr addrspace(3), ptr %0, align 8, !tbaa !43
  %5 = getelementptr inbounds %struct.TTL_int_int_tensor_t, ptr %0, i64 0, i32 2
  %6 = load i32, ptr %5, align 4, !tbaa !44
  %7 = mul i32 %6, %2
  %8 = add i32 %7, %1
  %9 = zext i32 %8 to i64
  %10 = getelementptr inbounds i32, ptr addrspace(3) %4, i64 %9
  %11 = load i32, ptr addrspace(3) %10, align 4, !tbaa !23
  ret i32 %11
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(write, argmem: readwrite, inaccessiblemem: none)
define internal spir_func void @_ZL16TTL_write_tensor20TTL_int_int_tensor_tijjj(ptr nocapture noundef readonly byval(%struct.TTL_int_int_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) unnamed_addr #5 {
  %5 = load ptr addrspace(3), ptr %0, align 8, !tbaa !43
  %6 = getelementptr inbounds %struct.TTL_int_int_tensor_t, ptr %0, i64 0, i32 2
  %7 = load i32, ptr %6, align 4, !tbaa !44
  %8 = mul i32 %7, %3
  %9 = add i32 %8, %2
  %10 = zext i32 %9 to i64
  %11 = getelementptr inbounds i32, ptr addrspace(3) %5, i64 %10
  store i32 %1, ptr addrspace(3) %11, align 4, !tbaa !23
  ret void
}

attributes #0 = { convergent noinline norecurse nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { convergent nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { nofree noinline norecurse nosync nounwind memory(readwrite, inaccessiblemem: none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(read, inaccessiblemem: none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(write, argmem: readwrite, inaccessiblemem: none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #6 = { mustprogress nofree noinline norecurse nounwind willreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #7 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: write) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #8 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #9 = { nofree noinline norecurse nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #10 = { convergent nounwind }
attributes #11 = { nounwind }

!llvm.module.flags = !{!0, !1}
!opencl.ocl.version = !{!2}
!opencl.spir.version = !{!2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 2, i32 0}
!3 = !{!"Ubuntu clang version 18.1.8 (++20240731025043+3b5b5c1ec4a3-1~exp1~20240731145144.92)"}
!4 = !{!5, !10, i64 24}
!5 = !{!"", !6, i64 0, !13, i64 32}
!6 = !{!"", !7, i64 0, !10, i64 8, !11, i64 12, !12, i64 20}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!"int", !8, i64 0}
!11 = !{!"", !10, i64 0, !10, i64 4}
!12 = !{!"", !10, i64 0, !10, i64 4, !10, i64 8}
!13 = !{!"", !12, i64 0, !12, i64 12}
!14 = !{!5, !10, i64 20}
!15 = !{!16, !10, i64 8}
!16 = !{!"", !7, i64 0, !10, i64 8, !10, i64 12}
!17 = !{!16, !10, i64 12}
!18 = !{!19, !10, i64 16}
!19 = !{!"", !10, i64 0, !10, i64 4, !10, i64 8, !10, i64 12, !10, i64 16, !10, i64 20, !10, i64 24, !10, i64 28, !10, i64 32, !10, i64 36, !10, i64 40, !10, i64 44, !10, i64 48}
!20 = !{!19, !10, i64 48}
!21 = !{!19, !10, i64 32}
!22 = !{!16, !7, i64 0}
!23 = !{!10, !10, i64 0}
!24 = !{!11, !10, i64 0}
!25 = !{!11, !10, i64 4}
!26 = !{!12, !10, i64 0}
!27 = !{!12, !10, i64 4}
!28 = !{!12, !10, i64 8}
!29 = !{i32 1, i32 0, i32 0, i32 1, i32 0, i32 0, i32 1, i32 0, i32 0, i32 0, i32 0, i32 0}
!30 = !{!"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none"}
!31 = !{!"int*", !"int", !"int", !"int*", !"int", !"int", !"int*", !"int", !"int", !"int", !"int", !"int"}
!32 = !{!"restrict", !"", !"", !"restrict", !"", !"", !"restrict", !"", !"", !"", !"", !""}
!33 = !{!19, !10, i64 0}
!34 = !{!19, !10, i64 4}
!35 = !{!19, !10, i64 8}
!36 = !{!19, !10, i64 12}
!37 = !{!19, !10, i64 20}
!38 = !{!19, !10, i64 24}
!39 = !{!19, !10, i64 28}
!40 = !{!19, !10, i64 36}
!41 = !{!19, !10, i64 40}
!42 = !{!19, !10, i64 44}
!43 = !{!6, !7, i64 0}
!44 = !{!6, !10, i64 12}
