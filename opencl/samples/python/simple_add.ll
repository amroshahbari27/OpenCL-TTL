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
%struct.TTL_affine_access_t = type { ptr addrspace(1), i32, i32, i32, i32, i32, i32, i32 }
%struct.TTL_loop_affine_t = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }

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
  %39 = tail call spir_func target("spirv.Event") @_Z21async_work_group_copyPU3AS3hPU3AS1Khm9ocl_event(ptr addrspace(3) noundef %37, ptr addrspace(1) noundef %38, i64 noundef %17, target("spirv.Event") %12) #9
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
  %39 = tail call spir_func target("spirv.Event") @_Z21async_work_group_copyPU3AS1hPU3AS3Khm9ocl_event(ptr addrspace(1) noundef %37, ptr addrspace(3) noundef %38, i64 noundef %17, target("spirv.Event") %12) #9
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
  %24 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %23, i32 noundef %13) #10
  %25 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %22, i32 noundef %14) #10
  %26 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %22, i32 noundef %13) #10
  %27 = add nuw nsw i32 %21, 11
  %28 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %27, i32 noundef %13) #10
  %29 = tail call spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %22, i32 noundef %15) #10
  %30 = add nsw i32 %25, %24
  %31 = add nsw i32 %30, %26
  %32 = add nsw i32 %31, %28
  %33 = add nsw i32 %32, %29
  tail call spir_func void @_ZL16TTL_write_tensor24TTL_int_int_sub_tensor_tijj(ptr noundef nonnull byval(%struct.TTL_int_int_sub_tensor_t) align 8 %1, i32 noundef %33, i32 noundef %21, i32 noundef %11) #10
  %34 = add nuw nsw i32 %21, 1
  %35 = icmp ult i32 %34, %8
  br i1 %35, label %20, label %17
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(read, inaccessiblemem: none)
define internal spir_func i32 @_ZL15TTL_read_tensor24TTL_int_int_sub_tensor_tjj(ptr nocapture noundef readonly byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #4 {
  %4 = tail call spir_func i32 @_ZL15TTL_read_tensor20TTL_int_int_tensor_tjjj(ptr noundef nonnull byval(%struct.TTL_int_int_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2) #10
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(write, argmem: readwrite, inaccessiblemem: none)
define internal spir_func void @_ZL16TTL_write_tensor24TTL_int_int_sub_tensor_tijj(ptr nocapture noundef readonly byval(%struct.TTL_int_int_sub_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) unnamed_addr #5 {
  tail call spir_func void @_ZL16TTL_write_tensor20TTL_int_int_tensor_tijjj(ptr noundef nonnull byval(%struct.TTL_int_int_tensor_t) align 8 %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #10
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nounwind willreturn memory(argmem: readwrite, inaccessiblemem: readwrite)
define dso_local spir_func i32 @TTL_affine_compute_index(ptr addrspace(4) noundef %0) local_unnamed_addr #6 {
  %2 = getelementptr inbounds %struct.TTL_affine_access_t, ptr addrspace(4) %0, i64 0, i32 5
  %3 = load volatile i32, ptr addrspace(4) %2, align 8, !tbaa !15
  %4 = getelementptr inbounds %struct.TTL_affine_access_t, ptr addrspace(4) %0, i64 0, i32 2
  %5 = load volatile i32, ptr addrspace(4) %4, align 4, !tbaa !17
  %6 = mul nsw i32 %5, %3
  %7 = getelementptr inbounds %struct.TTL_affine_access_t, ptr addrspace(4) %0, i64 0, i32 6
  %8 = load volatile i32, ptr addrspace(4) %7, align 4, !tbaa !18
  %9 = getelementptr inbounds %struct.TTL_affine_access_t, ptr addrspace(4) %0, i64 0, i32 3
  %10 = load volatile i32, ptr addrspace(4) %9, align 8, !tbaa !19
  %11 = mul nsw i32 %10, %8
  %12 = add nsw i32 %11, %6
  %13 = getelementptr inbounds %struct.TTL_affine_access_t, ptr addrspace(4) %0, i64 0, i32 7
  %14 = load volatile i32, ptr addrspace(4) %13, align 8, !tbaa !20
  %15 = getelementptr inbounds %struct.TTL_affine_access_t, ptr addrspace(4) %0, i64 0, i32 4
  %16 = load volatile i32, ptr addrspace(4) %15, align 4, !tbaa !21
  %17 = mul nsw i32 %16, %14
  %18 = add nsw i32 %12, %17
  ret i32 %18
}

; Function Attrs: mustprogress nofree noinline norecurse nounwind willreturn
define dso_local spir_func void @TTL_loop_affine_matmul_body(ptr nocapture noundef readnone byval(%struct.TTL_loop_affine_t) align 4 %0, ptr noundef byval(%struct.TTL_affine_access_t) align 8 %1, ptr noundef byval(%struct.TTL_affine_access_t) align 8 %2, ptr noundef byval(%struct.TTL_affine_access_t) align 8 %3) local_unnamed_addr #7 {
  %5 = addrspacecast ptr %1 to ptr addrspace(4)
  %6 = call spir_func i32 @TTL_affine_compute_index(ptr addrspace(4) noundef %5) #10
  %7 = addrspacecast ptr %2 to ptr addrspace(4)
  %8 = call spir_func i32 @TTL_affine_compute_index(ptr addrspace(4) noundef %7) #10
  %9 = addrspacecast ptr %3 to ptr addrspace(4)
  %10 = call spir_func i32 @TTL_affine_compute_index(ptr addrspace(4) noundef %9) #10
  %11 = load ptr addrspace(1), ptr %1, align 8, !tbaa !22
  %12 = sext i32 %6 to i64
  %13 = getelementptr inbounds i32, ptr addrspace(1) %11, i64 %12
  %14 = load i32, ptr addrspace(1) %13, align 4, !tbaa !23
  %15 = load ptr addrspace(1), ptr %2, align 8, !tbaa !22
  %16 = sext i32 %8 to i64
  %17 = getelementptr inbounds i32, ptr addrspace(1) %15, i64 %16
  %18 = load i32, ptr addrspace(1) %17, align 4, !tbaa !23
  %19 = mul nsw i32 %18, %14
  %20 = load ptr addrspace(1), ptr %3, align 8, !tbaa !22
  %21 = sext i32 %10 to i64
  %22 = getelementptr inbounds i32, ptr addrspace(1) %20, i64 %21
  %23 = load i32, ptr addrspace(1) %22, align 4, !tbaa !23
  %24 = add nsw i32 %23, %19
  store i32 %24, ptr addrspace(1) %22, align 4, !tbaa !23
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local spir_kernel void @TTL_matmul_kernel(ptr addrspace(1) noalias noundef align 4 %0, i32 noundef %1, i32 noundef %2, ptr addrspace(1) noalias noundef align 4 %3, i32 noundef %4, i32 noundef %5, ptr addrspace(1) noalias noundef align 4 %6, i32 noundef %7, i32 noundef %8, i32 noundef %9, i32 noundef %10, i32 noundef %11) local_unnamed_addr #8 !kernel_arg_addr_space !24 !kernel_arg_access_qual !25 !kernel_arg_type !26 !kernel_arg_base_type !26 !kernel_arg_type_qual !27 {
  %13 = alloca %struct.TTL_loop_affine_t, align 4
  %14 = alloca %struct.TTL_affine_access_t, align 8
  %15 = alloca %struct.TTL_affine_access_t, align 8
  %16 = alloca %struct.TTL_affine_access_t, align 8
  call void @llvm.lifetime.start.p0(i64 52, ptr nonnull %13) #10
  store volatile i32 3, ptr %13, align 4, !tbaa !28
  %17 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 1
  store volatile i32 0, ptr %17, align 4, !tbaa !30
  %18 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 2
  store volatile i32 %9, ptr %18, align 4, !tbaa !31
  %19 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 3
  store volatile i32 1, ptr %19, align 4, !tbaa !32
  %20 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 4
  store volatile i32 0, ptr %20, align 4, !tbaa !33
  %21 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 5
  store volatile i32 0, ptr %21, align 4, !tbaa !34
  %22 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 6
  store volatile i32 %10, ptr %22, align 4, !tbaa !35
  %23 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 7
  store volatile i32 1, ptr %23, align 4, !tbaa !36
  %24 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 8
  store volatile i32 1, ptr %24, align 4, !tbaa !37
  %25 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 9
  store volatile i32 0, ptr %25, align 4, !tbaa !38
  %26 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 10
  store volatile i32 %11, ptr %26, align 4, !tbaa !39
  %27 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 11
  store volatile i32 1, ptr %27, align 4, !tbaa !40
  %28 = getelementptr inbounds %struct.TTL_loop_affine_t, ptr %13, i64 0, i32 12
  store volatile i32 2, ptr %28, align 4, !tbaa !41
  call void @llvm.lifetime.start.p0(i64 40, ptr nonnull %14) #10
  store ptr addrspace(1) %0, ptr %14, align 8, !tbaa !22
  %29 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %14, i64 0, i32 1
  store volatile i32 2, ptr %29, align 8, !tbaa !42
  %30 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %14, i64 0, i32 2
  store volatile i32 1, ptr %30, align 4, !tbaa !17
  %31 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %14, i64 0, i32 3
  store volatile i32 %1, ptr %31, align 8, !tbaa !19
  %32 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %14, i64 0, i32 4
  store volatile i32 0, ptr %32, align 4, !tbaa !21
  %33 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %14, i64 0, i32 5
  %34 = load volatile i32, ptr %20, align 4, !tbaa !33
  store volatile i32 %34, ptr %33, align 8, !tbaa !15
  %35 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %14, i64 0, i32 6
  %36 = load volatile i32, ptr %28, align 4, !tbaa !41
  store volatile i32 %36, ptr %35, align 4, !tbaa !18
  %37 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %14, i64 0, i32 7
  store volatile i32 0, ptr %37, align 8, !tbaa !20
  call void @llvm.lifetime.start.p0(i64 40, ptr nonnull %15) #10
  store ptr addrspace(1) %3, ptr %15, align 8, !tbaa !22
  %38 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %15, i64 0, i32 1
  store volatile i32 2, ptr %38, align 8, !tbaa !42
  %39 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %15, i64 0, i32 2
  store volatile i32 1, ptr %39, align 4, !tbaa !17
  %40 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %15, i64 0, i32 3
  store volatile i32 %4, ptr %40, align 8, !tbaa !19
  %41 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %15, i64 0, i32 4
  store volatile i32 0, ptr %41, align 4, !tbaa !21
  %42 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %15, i64 0, i32 5
  %43 = load volatile i32, ptr %28, align 4, !tbaa !41
  store volatile i32 %43, ptr %42, align 8, !tbaa !15
  %44 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %15, i64 0, i32 6
  %45 = load volatile i32, ptr %24, align 4, !tbaa !37
  store volatile i32 %45, ptr %44, align 4, !tbaa !18
  %46 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %15, i64 0, i32 7
  store volatile i32 0, ptr %46, align 8, !tbaa !20
  call void @llvm.lifetime.start.p0(i64 40, ptr nonnull %16) #10
  store ptr addrspace(1) %6, ptr %16, align 8, !tbaa !22
  %47 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %16, i64 0, i32 1
  store volatile i32 2, ptr %47, align 8, !tbaa !42
  %48 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %16, i64 0, i32 2
  store volatile i32 1, ptr %48, align 4, !tbaa !17
  %49 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %16, i64 0, i32 3
  store volatile i32 %7, ptr %49, align 8, !tbaa !19
  %50 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %16, i64 0, i32 4
  store volatile i32 0, ptr %50, align 4, !tbaa !21
  %51 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %16, i64 0, i32 5
  %52 = load volatile i32, ptr %20, align 4, !tbaa !33
  store volatile i32 %52, ptr %51, align 8, !tbaa !15
  %53 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %16, i64 0, i32 6
  %54 = load volatile i32, ptr %24, align 4, !tbaa !37
  store volatile i32 %54, ptr %53, align 4, !tbaa !18
  %55 = getelementptr inbounds %struct.TTL_affine_access_t, ptr %16, i64 0, i32 7
  store volatile i32 0, ptr %55, align 8, !tbaa !20
  tail call spir_func void @TTL_loop_affine_matmul_body(ptr noundef nonnull byval(%struct.TTL_loop_affine_t) align 4 %13, ptr noundef nonnull byval(%struct.TTL_affine_access_t) align 8 %14, ptr noundef nonnull byval(%struct.TTL_affine_access_t) align 8 %15, ptr noundef nonnull byval(%struct.TTL_affine_access_t) align 8 %16) #10
  call void @llvm.lifetime.end.p0(i64 40, ptr nonnull %16) #10
  call void @llvm.lifetime.end.p0(i64 40, ptr nonnull %15) #10
  call void @llvm.lifetime.end.p0(i64 40, ptr nonnull %14) #10
  call void @llvm.lifetime.end.p0(i64 52, ptr nonnull %13) #10
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
attributes #6 = { mustprogress nofree noinline norecurse nounwind willreturn memory(argmem: readwrite, inaccessiblemem: readwrite) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #7 = { mustprogress nofree noinline norecurse nounwind willreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #8 = { nofree noinline norecurse nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #9 = { convergent nounwind }
attributes #10 = { nounwind }

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
!15 = !{!16, !10, i64 24}
!16 = !{!"", !7, i64 0, !10, i64 8, !10, i64 12, !10, i64 16, !10, i64 20, !10, i64 24, !10, i64 28, !10, i64 32}
!17 = !{!16, !10, i64 12}
!18 = !{!16, !10, i64 28}
!19 = !{!16, !10, i64 16}
!20 = !{!16, !10, i64 32}
!21 = !{!16, !10, i64 20}
!22 = !{!16, !7, i64 0}
!23 = !{!10, !10, i64 0}
!24 = !{i32 1, i32 0, i32 0, i32 1, i32 0, i32 0, i32 1, i32 0, i32 0, i32 0, i32 0, i32 0}
!25 = !{!"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none"}
!26 = !{!"int*", !"int", !"int", !"int*", !"int", !"int", !"int*", !"int", !"int", !"int", !"int", !"int"}
!27 = !{!"restrict", !"", !"", !"restrict", !"", !"", !"restrict", !"", !"", !"", !"", !""}
!28 = !{!29, !10, i64 0}
!29 = !{!"", !10, i64 0, !10, i64 4, !10, i64 8, !10, i64 12, !10, i64 16, !10, i64 20, !10, i64 24, !10, i64 28, !10, i64 32, !10, i64 36, !10, i64 40, !10, i64 44, !10, i64 48}
!30 = !{!29, !10, i64 4}
!31 = !{!29, !10, i64 8}
!32 = !{!29, !10, i64 12}
!33 = !{!29, !10, i64 16}
!34 = !{!29, !10, i64 20}
!35 = !{!29, !10, i64 24}
!36 = !{!29, !10, i64 28}
!37 = !{!29, !10, i64 32}
!38 = !{!29, !10, i64 36}
!39 = !{!29, !10, i64 40}
!40 = !{!29, !10, i64 44}
!41 = !{!29, !10, i64 48}
!42 = !{!16, !10, i64 8}
!43 = !{!6, !7, i64 0}
!44 = !{!6, !10, i64 12}
