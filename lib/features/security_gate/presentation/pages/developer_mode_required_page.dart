import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/developer_options_icon.dart';
import '../controllers/developer_mode_controller.dart';
import '../widgets/security_status_body.dart';

class DeveloperModeRequiredPage extends GetView<DeveloperModeController> {
  const DeveloperModeRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Obx(() {
            final gateStatus = controller.status.value;
            final isChecking = gateStatus == DeveloperModeGateStatus.checking;
            final isCleared = gateStatus == DeveloperModeGateStatus.cleared;
            final isCompromised =
                gateStatus == DeveloperModeGateStatus.deviceCompromised;

            return SecurityStatusBody(
              contentKey: gateStatus,
              title: AppStrings.disableDeveloperMode,
              message: _messageFor(gateStatus),
              isLoading: isChecking,
              icon: const DeveloperOptionsIcon(),
              iconColor: isCleared
                  ? AppColors.success
                  : isCompromised
                      ? AppColors.error
                      : AppColors.warning,
              actionLabel: isCleared
                  ? AppStrings.continueAction
                  : isCompromised
                      ? null
                      : AppStrings.openSettings,
              onAction: isCleared
                  ? controller.continueWhenReady
                  : isCompromised
                      ? null
                      : controller.openSettings,
              secondaryActionLabel: AppStrings.refresh,
              onSecondaryAction: controller.refreshStatus,
            );
          }),
        ),
      ),
    );
  }

  String _messageFor(DeveloperModeGateStatus status) => switch (status) {
        DeveloperModeGateStatus.checking =>
          AppStrings.checkingDeveloperModeStatus,
        DeveloperModeGateStatus.cleared =>
          AppStrings.developerModeDisabledContinue,
        DeveloperModeGateStatus.developerModeEnabled =>
          AppStrings.developerModeMustBeDisabled,
        DeveloperModeGateStatus.deviceCompromised =>
          AppStrings.deviceNotPermitted,
        DeveloperModeGateStatus.error =>
          AppStrings.unableToVerifyDeveloperMode,
      };
}
