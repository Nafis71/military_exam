import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/exam_procedure_penalties_section.dart';
import '../widgets/exam_procedure_timeline.dart';

class ExamProcedurePage extends StatelessWidget {
  const ExamProcedurePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.c0F3D2E),
          onPressed: Get.back,
        ),
        title: Text(
          AppStrings.examProcedureTitle,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.c0F3D2E,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ExamProcedureTimeline(),
            SizedBox(height: AppSpacing.xl.h),
            const ExamProcedurePenaltiesSection(),
          ],
        ),
      ),
    );
  }
}
