import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/camera_permission_controller.dart';
import '../widgets/security_status_body.dart';

class CameraPermissionRequiredPage extends GetView<CameraPermissionController> {
  const CameraPermissionRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Obx(() {
            final gateStatus = controller.status.value;
            final isChecking =
                gateStatus == CameraPermissionGateStatus.checking;
            final isGranted = gateStatus == CameraPermissionGateStatus.granted;
            final isPermanentlyDenied =
                gateStatus == CameraPermissionGateStatus.permanentlyDenied;

            return SecurityStatusBody(
              contentKey: gateStatus,
              title: AppStrings.enableCameraPermission,
              message: _messageFor(gateStatus),
              isLoading: isChecking || controller.isRequestingPermission.value,
              icon: Icon(
                isGranted
                    ? Icons.camera_alt
                    : Icons.camera_alt_outlined,
                size: 200.w,
                color: isGranted ? AppColors.success : AppColors.warning,
              ),
              iconColor: isGranted ? AppColors.success : AppColors.warning,
              actionLabel: isGranted
                  ? AppStrings.continueAction
                  : isPermanentlyDenied
                      ? AppStrings.openSettings
                      : AppStrings.grantCameraPermission,
              onAction: isGranted
                  ? controller.continueWhenReady
                  : isPermanentlyDenied
                      ? controller.openSettings
                      : controller.requestPermission,
              secondaryActionLabel: AppStrings.refresh,
              onSecondaryAction: controller.refreshStatus,
            );
          }),
        ),
      ),
    );
  }

  String _messageFor(CameraPermissionGateStatus status) => switch (status) {
        CameraPermissionGateStatus.checking =>
          AppStrings.checkingCameraPermissionStatus,
        CameraPermissionGateStatus.granted =>
          AppStrings.cameraPermissionGrantedContinue,
        CameraPermissionGateStatus.denied =>
          AppStrings.cameraPermissionMustBeGranted,
        CameraPermissionGateStatus.permanentlyDenied =>
          AppStrings.cameraPermissionPermanentlyDenied,
      };
}
