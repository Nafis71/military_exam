import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../models/camera_permission_gate_status.dart';
import '../theme/app_colors.dart';
import 'camera_denied_icon.dart';
import 'camera_granted_icon.dart';
import 'security_instruction_box.dart';
import 'security_status_body.dart';

class CameraPermissionGateView extends StatelessWidget {
  const CameraPermissionGateView({
    super.key,
    required this.status,
    required this.isRequestingPermission,
    required this.onRequest,
    required this.onOpenSettings,
    required this.onContinue,
    required this.onRefresh,
    this.useLightText = false,
  });

  final CameraPermissionGateStatus status;
  final bool isRequestingPermission;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;
  final VoidCallback onContinue;
  final VoidCallback onRefresh;
  final bool useLightText;

  @override
  Widget build(BuildContext context) {
    final isChecking = status == CameraPermissionGateStatus.checking;
    final isGranted = status == CameraPermissionGateStatus.granted;
    final isPermanentlyDenied =
        status == CameraPermissionGateStatus.permanentlyDenied;
    final needsInstruction = status == CameraPermissionGateStatus.denied ||
        status == CameraPermissionGateStatus.permanentlyDenied;

    return SecurityStatusBody(
      contentKey: status,
      useLightText: useLightText,
      title: isGranted
          ? AppStrings.cameraPermissionGrantedTitle
          : AppStrings.enableCameraPermission,
      message: _messageFor(status),
      isLoading: isChecking || isRequestingPermission,
      icon: isGranted ? const CameraGrantedIcon() : const CameraDeniedIcon(),
      iconColor: isGranted ? AppColors.primary : AppColors.c000000,
      footer: needsInstruction
          ? SecurityInstructionBox(
              instruction: AppStrings.cameraInstruction,
              useLightText: useLightText,
            )
          : null,
      actionLabel: isGranted
          ? AppStrings.continueAction
          : isPermanentlyDenied
              ? AppStrings.openSettings
              : AppStrings.grantCameraPermission,
      onAction: isGranted
          ? onContinue
          : isPermanentlyDenied
              ? onOpenSettings
              : onRequest,
      secondaryActionLabel: AppStrings.refresh,
      onSecondaryAction: onRefresh,
      secondaryActionColor: isGranted ? AppColors.primary : AppColors.cBDBDBD,
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
