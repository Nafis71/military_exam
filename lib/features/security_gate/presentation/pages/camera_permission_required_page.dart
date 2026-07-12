import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/camera_denied_icon.dart';
import '../../../../core/widgets/camera_granted_icon.dart';
import '../controllers/camera_permission_controller.dart';
import '../widgets/security_instruction_box.dart';
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
            final needsInstruction = gateStatus ==
                    CameraPermissionGateStatus.denied ||
                gateStatus == CameraPermissionGateStatus.permanentlyDenied;

            return SecurityStatusBody(
              contentKey: gateStatus,
              title: isGranted
                  ? AppStrings.cameraPermissionGrantedTitle
                  : AppStrings.enableCameraPermission,
              message: _messageFor(gateStatus),
              isLoading: isChecking || controller.isRequestingPermission.value,
              icon: isGranted
                  ? const CameraGrantedIcon()
                  : const CameraDeniedIcon(),
              iconColor: isGranted ? AppColors.primary : AppColors.c000000,
              footer: needsInstruction
                  ? const SecurityInstructionBox(
                      instruction: AppStrings.cameraInstruction,
                    )
                  : null,
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
              secondaryActionColor:
                  isGranted ? AppColors.primary : AppColors.cBDBDBD,
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
