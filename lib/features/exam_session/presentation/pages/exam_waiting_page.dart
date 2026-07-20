import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../controllers/exam_waiting_controller.dart';
import '../widgets/exam_countdown_display.dart';

class ExamWaitingPage extends GetView<ExamWaitingController> {
  const ExamWaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SizedBox.expand(
            child: Obx(() {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        controller.examName,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.c0F3D2E,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      Text(
                        AppStrings.examWaitingTitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.c66736C,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg.h),
                      Text(
                        controller.hasCountdownTarget
                            ? AppStrings.examStartsIn
                            : AppStrings.examWaitingNoStartTime,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.c176B4D,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      if (controller.hasCountdownTarget)
                        ExamCountdownDisplay(
                          formattedCountdown: controller.formattedCountdown,
                        ),
                      if (controller.durationMinutes > 0) ...[
                        SizedBox(height: AppSpacing.lg.h),
                        Text(
                          AppStrings.examDurationInfo(controller.durationMinutes),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.c66736C,
                          ),
                        ),
                      ],
                      if (controller.errorMessage.value != null) ...[
                        SizedBox(height: AppSpacing.lg.h),
                        Text(
                          controller.errorMessage.value!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.c66736C,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        AppPrimaryButton(
                          label: AppStrings.examWaitingRefresh,
                          isLoading: controller.isRefreshing.value,
                          onPressed: controller.isRefreshing.value
                              ? null
                              : controller.refreshExamWindow,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
