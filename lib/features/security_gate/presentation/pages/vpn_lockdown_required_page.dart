import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/violation_icon.dart';
import '../controllers/vpn_lockdown_controller.dart';
import '../../../../core/widgets/security_instruction_box.dart';
import '../../../../core/widgets/security_status_body.dart';

class VpnLockdownRequiredPage extends GetView<VpnLockdownController> {
  const VpnLockdownRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.brandHeaderGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Obx(() {
              final gateStatus = controller.status.value;
              final isChecking = gateStatus == VpnLockdownGateStatus.checking;
              final isEnabled = gateStatus == VpnLockdownGateStatus.enabled;
              final isDisabled = gateStatus == VpnLockdownGateStatus.disabled;

              return SecurityStatusBody(
                contentKey: gateStatus,
                useLightText: true,
                title: _titleFor(gateStatus),
                message: _messageFor(gateStatus),
                isLoading: isChecking || controller.isActivating.value,
                icon: const ViolationIcon(),
                iconColor: isEnabled ? AppColors.primary : AppColors.c000000,
                footer: isDisabled
                    ? const SecurityInstructionBox(
                        instruction: AppStrings.networkLockdownInstruction,
                        useLightText: true,
                      )
                    : null,
                actionLabel: isEnabled
                    ? AppStrings.continueAction
                    : AppStrings.enableNetworkLockdown,
                onAction: isEnabled
                    ? controller.continueWhenReady
                    : controller.activateLockdown,
                secondaryActionLabel: AppStrings.refresh,
                onSecondaryAction: controller.refreshStatus,
                secondaryActionColor:
                    isEnabled ? AppColors.primary : AppColors.cBDBDBD,
              );
            }),
          ),
        ),
      ),
    );
  }

  String _titleFor(VpnLockdownGateStatus status) => switch (status) {
        VpnLockdownGateStatus.checking => AppStrings.networkLockdownRequired,
        VpnLockdownGateStatus.enabled => AppStrings.networkLockdownEnabled,
        VpnLockdownGateStatus.disabled => AppStrings.enableNetworkLockdown,
        VpnLockdownGateStatus.error => AppStrings.unableToVerifyNetworkLockdown,
      };

  String _messageFor(VpnLockdownGateStatus status) => switch (status) {
        VpnLockdownGateStatus.checking =>
          AppStrings.checkingNetworkLockdownStatus,
        VpnLockdownGateStatus.enabled =>
          AppStrings.networkLockdownEnabledContinue,
        VpnLockdownGateStatus.disabled =>
          AppStrings.networkLockdownMustBeEnabled,
        VpnLockdownGateStatus.error =>
          AppStrings.unableToVerifyNetworkLockdown,
      };
}
