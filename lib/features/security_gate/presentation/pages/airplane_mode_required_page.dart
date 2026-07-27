import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/airplane_icon.dart';
import '../controllers/airplane_mode_controller.dart';
import '../../../../core/widgets/security_instruction_box.dart';
import '../../../../core/widgets/security_status_body.dart';

class AirplaneModeRequiredPage extends GetView<AirplaneModeController> {
  const AirplaneModeRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Obx(() {
            final gateStatus = controller.status.value;
            final isChecking = gateStatus == AirplaneModeGateStatus.checking;
            final isEnabled = gateStatus == AirplaneModeGateStatus.enabled;
            final isDisabled = gateStatus == AirplaneModeGateStatus.disabled;

            return SecurityStatusBody(
              contentKey: gateStatus,
              title: _titleFor(gateStatus),
              message: _messageFor(gateStatus),
              isLoading: isChecking,
              icon: AirplaneIcon(isEnabled: isEnabled),
              iconColor: isEnabled ? AppColors.primary : AppColors.c000000,
              footer: isDisabled
                  ? const SecurityInstructionBox(
                      instruction: AppStrings.airplaneModeInstruction,
                    )
                  : null,
              actionLabel:
                  isEnabled ? AppStrings.continueAction : AppStrings.openSettings,
              onAction: isEnabled
                  ? controller.continueWhenReady
                  : controller.openSettings,
              secondaryActionLabel: AppStrings.refresh,
              onSecondaryAction: controller.refreshStatus,
              secondaryActionColor:
                  isEnabled ? AppColors.primary : AppColors.cBDBDBD,
            );
          }),
        ),
      ),
    );
  }

  String _titleFor(AirplaneModeGateStatus status) => switch (status) {
        AirplaneModeGateStatus.checking => AppStrings.airplaneModeRequired,
        AirplaneModeGateStatus.enabled => AppStrings.airplaneModeEnabled,
        AirplaneModeGateStatus.disabled => AppStrings.enableAirplaneMode,
        AirplaneModeGateStatus.error => AppStrings.airplaneModeCheckFailed,
      };

  String _messageFor(AirplaneModeGateStatus status) => switch (status) {
        AirplaneModeGateStatus.checking =>
          AppStrings.checkingAirplaneModeStatus,
        AirplaneModeGateStatus.enabled => AppStrings.airplaneModeEnabledContinue,
        AirplaneModeGateStatus.disabled => AppStrings.airplaneModeMustBeEnabled,
        AirplaneModeGateStatus.error => AppStrings.unableToVerifyAirplaneMode,
      };
}
