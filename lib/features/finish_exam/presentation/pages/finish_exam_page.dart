import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../controllers/finish_exam_controller.dart';
import '../widgets/finish_exam_status_icon.dart';
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
                FinishExamStatusIcon(submissionType: controller.submissionType),
                SizedBox(height: 40.h),
                Text(
                  controller.title,
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
                  controller.message,
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
                SizedBox(height: 40.h),
                AppPrimaryButton(
                  label: controller.primaryButtonLabel,
                  onPressed: controller.onPrimaryAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
