import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/camera_permission_gate_view.dart';
import '../../../../core/widgets/security_status_body.dart';
import '../../../../core/widgets/verified_user_icon.dart';
import '../controllers/identity_verification_controller.dart';
import '../widgets/identity_qr_scan_icon.dart';

class IdentityVerificationPage extends GetView<IdentityVerificationController> {
  const IdentityVerificationPage({super.key});

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
              if (controller.showPermissionGate) {
                return CameraPermissionGateView(
                  useLightText: true,
                  status: controller.permissionStatus.value,
                  isRequestingPermission:
                      controller.isRequestingPermission.value,
                  onRequest: controller.requestPermission,
                  onOpenSettings: controller.openSettings,
                  onContinue: controller.onPermissionContinue,
                  onRefresh: controller.refreshStatus,
                );
              }

              return _ScanFlowBody(controller: controller);
            }),
          ),
        ),
      ),
    );
  }
}

class _ScanFlowBody extends StatelessWidget {
  const _ScanFlowBody({required this.controller});

  final IdentityVerificationController controller;

  @override
  Widget build(BuildContext context) {
    final flowStatus = controller.flowStatus.value;
    final isVerified =
        flowStatus == IdentityVerificationFlowStatus.verified;
    final isVerifying =
        flowStatus == IdentityVerificationFlowStatus.verifying;
    final isBusy = isVerifying ||
        controller.isScannerOpen.value ||
        controller.isNavigating.value;

    return SecurityStatusBody(
      contentKey: flowStatus,
      useLightText: true,
      title: isVerified
          ? AppStrings.identityVerifiedTitle
          : AppStrings.procedureStep2Title,
      message: isVerified
          ? AppStrings.identityVerifiedMessage
          : AppStrings.procedureStep2Description,
      isLoading: isVerified
          ? controller.isNavigating.value
          : isBusy,
      icon: isVerified ? const VerifiedUserIcon() : const IdentityQrScanIcon(),
      iconColor: AppColors.primary,
      actionLabel: isVerified
          ? AppStrings.continueToInstructions
          : AppStrings.scanQrCode,
      onAction: isVerified
          ? controller.continueToInstructions
          : controller.openScanner,
    );
  }
}
