import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/finish_exam_controller.dart';
import '../widgets/finish_exam_success_icon.dart';
import '../widgets/finish_exam_summary_card.dart';

class FinishExamPage extends GetView<FinishExamController> {
  const FinishExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cFFFFFF,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 66.h, 20.w, 24.h),
            child: Column(
              children: [
                const FinishExamSuccessIcon(),
                SizedBox(height: 40.h),
                Text(
                  AppStrings.submissionSuccessful,
                  textAlign: TextAlign.center,
                  style: textTheme.displayLarge?.copyWith(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.c0F3D2E,
                    letterSpacing: 0.5,
                    height: 42 / 28,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  AppStrings.submissionSuccessfulMessage,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.c66736C,
                    height: 25.5 / 15,
                  ),
                ),
                SizedBox(height: 40.h),
                FinishExamSummaryCard(
                  examName: controller.examName,
                  submittedAtLabel: controller.submittedAtLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
