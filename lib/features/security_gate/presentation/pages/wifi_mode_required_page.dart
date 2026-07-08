import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/no_wifi_icon.dart';
import '../../../../core/widgets/wifi_on_icon.dart';
import '../controllers/wifi_mode_controller.dart';
import '../widgets/security_status_body.dart';

class WifiModeRequiredPage extends GetView<WifiModeController> {
  const WifiModeRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Obx(() {
            final gateStatus = controller.status.value;
            final isChecking = gateStatus == WifiModeGateStatus.checking;
            final isEnabled = gateStatus == WifiModeGateStatus.enabled;

            final iconColor = isEnabled ? AppColors.success : AppColors.warning;

            return SecurityStatusBody(
              contentKey: gateStatus,
              title: _titleFor(gateStatus),
              message: _messageFor(gateStatus),
              isLoading: isChecking,
              icon: isEnabled ? const WifiOnIcon() : const NoWifiIcon(),
              iconColor: iconColor,
              actionLabel:
                  isEnabled ? AppStrings.continueAction : AppStrings.openSettings,
              onAction: isEnabled
                  ? controller.continueWhenReady
                  : controller.openSettings,
              secondaryActionLabel: AppStrings.refresh,
              onSecondaryAction: controller.refreshStatus,
            );
          }),
        ),
      ),
    );
  }

  String _titleFor(WifiModeGateStatus status) => switch (status) {
        WifiModeGateStatus.checking => AppStrings.enableWifi,
        WifiModeGateStatus.enabled => AppStrings.wifiEnabled,
        WifiModeGateStatus.disabled => AppStrings.enableWifi,
        WifiModeGateStatus.error => AppStrings.connectivityCheckFailedWithError,
      };

  String _messageFor(WifiModeGateStatus status) => switch (status) {
        WifiModeGateStatus.checking => AppStrings.checkingWifiStatus,
        WifiModeGateStatus.enabled => AppStrings.networkConnectedContinue,
        WifiModeGateStatus.disabled => AppStrings.wifiMustBeEnabled,
        WifiModeGateStatus.error => AppStrings.unableToVerifyConnectivity,
      };
}
