import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/verified_user_icon.dart';
import '../../../../core/widgets/violation_icon.dart';
import '../controllers/security_gate_controller.dart';
import '../widgets/security_checklist.dart';
import '../widgets/security_status_body.dart';

class SecurityGatePage extends GetView<SecurityGateController> {
  const SecurityGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Obx(() {
            final gateStatus = controller.status.value;
            final isPassed = gateStatus == SecurityGateStatus.passed;

            return SecurityStatusBody(
              contentKey: gateStatus,
              title: _titleFor(gateStatus),
              message: _messageFor(gateStatus),
              typewriterMessage: gateStatus == SecurityGateStatus.checking,
              isLoading: gateStatus == SecurityGateStatus.checking,
              actionLabel: _actionLabelFor(gateStatus),
              onAction: _onActionFor(gateStatus),
              icon: _iconFor(gateStatus),
              iconColor: _primaryButtonColorFor(gateStatus),
              footer: isPassed ? const SecurityChecklist() : null,
              wrapIconInCard: gateStatus != SecurityGateStatus.checking,
            );
          }),
        ),
      ),
    );
  }

  String _titleFor(SecurityGateStatus status) => switch (status) {
        SecurityGateStatus.checking => AppStrings.verifyingDeviceSecurity,
        SecurityGateStatus.passed => AppStrings.securityChecksPassed,
        SecurityGateStatus.deviceCompromised => AppStrings.rootedDeviceTitle,
        SecurityGateStatus.airplaneModeRequired =>
          AppStrings.airplaneModeRequired,
        SecurityGateStatus.failed => AppStrings.securityCheckFailed,
      };

  String _messageFor(SecurityGateStatus status) => switch (status) {
        SecurityGateStatus.checking => AppStrings.checkingDeviceIntegrity,
        SecurityGateStatus.passed => AppStrings.deviceMeetsRequirements,
        SecurityGateStatus.airplaneModeRequired =>
          AppStrings.enableAirplaneModeBeforeContinuing,
        SecurityGateStatus.failed => AppStrings.securityCheckFailed,
        SecurityGateStatus.deviceCompromised => AppStrings.rootedDeviceMessage,
      };

  String? _actionLabelFor(SecurityGateStatus status) => switch (status) {
        SecurityGateStatus.failed => AppStrings.retry,
        SecurityGateStatus.passed => AppStrings.continueAction,
        SecurityGateStatus.deviceCompromised => null,
        _ => null,
      };

  VoidCallback? _onActionFor(SecurityGateStatus status) => switch (status) {
        SecurityGateStatus.failed => controller.runChecks,
        SecurityGateStatus.passed => controller.continueToNext,
        _ => null,
      };

  Widget _iconFor(SecurityGateStatus status) {
    if (status == SecurityGateStatus.checking) {
      return SizedBox(
        width: 48.w,
        height: 48.w,
        child: const CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      );
    }
    if (status == SecurityGateStatus.deviceCompromised) {
      return const ViolationIcon();
    }
    if (status == SecurityGateStatus.passed) {
      return const VerifiedUserIcon();
    }
    return const ViolationIcon();
  }

  Color? _primaryButtonColorFor(SecurityGateStatus status) => switch (status) {
        SecurityGateStatus.passed => AppColors.primary,
        SecurityGateStatus.failed => AppColors.error,
        _ => null,
      };
}
