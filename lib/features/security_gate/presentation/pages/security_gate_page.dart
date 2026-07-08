import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_png_asset.dart';
import '../controllers/security_gate_controller.dart';
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
            return SecurityStatusBody(
              contentKey: gateStatus,
              title: _titleFor(gateStatus),
              message: _messageFor(gateStatus),
              typewriterMessage: gateStatus == SecurityGateStatus.checking,
              isLoading: gateStatus == SecurityGateStatus.checking,
              actionLabel: _actionLabelFor(gateStatus),
              onAction: _onActionFor(gateStatus),
              icon: _iconFor(gateStatus),
              iconColor: _iconColorFor(gateStatus),
            );
          }),
        ),
      ),
    );
  }

  String _titleFor(SecurityGateStatus status) => switch (status) {
        SecurityGateStatus.checking => AppStrings.verifyingDeviceSecurity,
        SecurityGateStatus.passed => AppStrings.securityChecksPassed,
        SecurityGateStatus.deviceCompromised => AppStrings.deviceNotPermitted,
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
        SecurityGateStatus.deviceCompromised => AppStrings.deviceNotPermitted,
      };

  String? _actionLabelFor(SecurityGateStatus status) => switch (status) {
        SecurityGateStatus.failed => AppStrings.retry,
        SecurityGateStatus.passed => AppStrings.continueAction,
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
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
      );
    }
    return AppLogoView(width: 200.w, height: 200.h);
  }

  Color _iconColorFor(SecurityGateStatus status) => switch (status) {
        SecurityGateStatus.deviceCompromised ||
        SecurityGateStatus.failed =>
          AppColors.error,
        SecurityGateStatus.passed => AppColors.success,
        _ => AppColors.primary,
      };
}
