import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../controllers/candidate_dashboard_controller.dart';
import '../widgets/dashboard_exam_banner.dart';
import '../widgets/dashboard_notification_icon_button.dart';
import '../widgets/dashboard_profile_card.dart';

class CandidateDashboardPage extends GetView<CandidateDashboardController> {
  const CandidateDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          AppStrings.candidateDashboardTitle,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.c0F3D2E,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          DashboardNotificationIconButton(
            onPressed: controller.onOpenNotifications,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final contentKey = controller.candidate.value?.candidateId;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg.w,
                  AppSpacing.lg.h,
                  AppSpacing.lg.w,
                  AppSpacing.md.h,
                ),
                child: StaggeredEntrance(
                  contentKey: contentKey,
                  children: [
                    DashboardProfileCard(
                      candidate: controller.candidate.value,
                      isDeviceBound: controller.isDeviceBound.value,
                      isUnbinding: controller.isUnbinding.value,
                      deviceBrandName: controller.deviceBrandName.value,
                      deviceModelNumber: controller.deviceModelNumber.value,
                      deviceOsVersion: controller.deviceOsVersion.value,
                      isDeviceInfoAvailable:
                          controller.isDeviceInfoAvailable.value,
                      onUnbind: controller.onUnbind,
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    DashboardExamBanner(
                      examInfo: controller.examInfo.value,
                      onStartExamination: controller.onStartExamination,
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    TextButton(
                      onPressed: controller.onViewExamProcedure,
                      child: Text(
                        AppStrings.viewExaminationProcedure,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.c0A5943,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.showStartDemo.value)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg.w,
                  AppSpacing.sm.h,
                  AppSpacing.lg.w,
                  AppSpacing.lg.h + bottomInset,
                ),
                child: StaggeredEntrance(
                  contentKey: contentKey,
                  children: [
                    Obx(
                      () => AppPrimaryButton(
                        label: AppStrings.startDemo,
                        onPressed: controller.isStartingDemo.value
                            ? null
                            : controller.onStartDemo,
                        isLoading: controller.isStartingDemo.value,
                        backgroundColor: AppColors.c66736C,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}
