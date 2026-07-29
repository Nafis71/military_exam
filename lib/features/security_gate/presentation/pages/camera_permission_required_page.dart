import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/camera_permission_gate_view.dart';
import '../controllers/camera_permission_controller.dart';

class CameraPermissionRequiredPage extends GetView<CameraPermissionController> {
  const CameraPermissionRequiredPage({super.key});

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
            child: Obx(
              () => CameraPermissionGateView(
                useLightText: true,
                status: controller.status.value,
                isRequestingPermission: controller.isRequestingPermission.value,
                onRequest: controller.requestPermission,
                onOpenSettings: controller.openSettings,
                onContinue: controller.continueWhenReady,
                onRefresh: controller.refreshStatus,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
