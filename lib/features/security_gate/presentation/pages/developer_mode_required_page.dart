import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/developer_options_icon.dart';
import '../../../../core/widgets/violation_icon.dart';
import '../controllers/developer_mode_controller.dart';
import '../widgets/security_instruction_box.dart';
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
            final isDeveloperModeEnabled =
                gateStatus == DeveloperModeGateStatus.developerModeEnabled;
            final isCompromised =
                gateStatus == DeveloperModeGateStatus.deviceCompromised;

            return SecurityStatusBody(
              contentKey: gateStatus,
              title: _titleFor(gateStatus),
              message: _messageFor(gateStatus),
              isLoading: isChecking,
              icon: isCompromised
                  ? const ViolationIcon()
                  : const DeveloperOptionsIcon(),
              iconColor: _primaryButtonColorFor(gateStatus),
              footer: isDeveloperModeEnabled
                  ? const SecurityInstructionBox(
                      instruction: AppStrings.developerModeInstruction,
                    )
                  : null,
              actionLabel: isCleared
                  ? AppStrings.continueAction
                  : isCompromised
                      ? null
                      : isDeveloperModeEnabled
                          ? AppStrings.openSettings
                          : null,
              onAction: isCleared
                  ? controller.continueWhenReady
                  : isCompromised
                      ? null
                      : isDeveloperModeEnabled
                          ? controller.openSettings
                          : null,
              secondaryActionLabel:
                  isCompromised ? null : AppStrings.refresh,
              onSecondaryAction:
                  isCompromised ? null : controller.refreshStatus,
            );
          }),
        ),
      ),
    );
  }

  String _titleFor(DeveloperModeGateStatus status) => switch (status) {
        DeveloperModeGateStatus.deviceCompromised =>
          AppStrings.rootedDeviceTitle,
        _ => AppStrings.disableDeveloperMode,
      };

  String _messageFor(DeveloperModeGateStatus status) => switch (status) {
        DeveloperModeGateStatus.checking =>
          AppStrings.checkingDeveloperModeStatus,
        DeveloperModeGateStatus.cleared =>
          AppStrings.developerModeDisabledContinue,
        DeveloperModeGateStatus.developerModeEnabled =>
          AppStrings.developerModeMustBeDisabled,
        DeveloperModeGateStatus.deviceCompromised =>
          AppStrings.rootedDeviceMessage,
        DeveloperModeGateStatus.error =>
          AppStrings.unableToVerifyDeveloperMode,
      };

  Color? _primaryButtonColorFor(DeveloperModeGateStatus status) =>
      switch (status) {
        DeveloperModeGateStatus.cleared => AppColors.primary,
        DeveloperModeGateStatus.developerModeEnabled => AppColors.c000000,
        _ => null,
      };
}
