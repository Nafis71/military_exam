import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/dashboard_security_settings_controller.dart';
import 'dashboard_security_setting_tile.dart';

class DashboardSecuritySettingsSheet
    extends GetView<DashboardSecuritySettingsController> {
  const DashboardSecuritySettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.65;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg.w,
          AppSpacing.md.h,
          AppSpacing.lg.w,
          AppSpacing.lg.h + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              AppStrings.securitySettingsTitle,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.c0F3D2E,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Obx(() {
                final isInteractionDisabled = controller.isRefreshing.value ||
                    controller.settings.any((item) => item.isBusy);

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final item in controller.settings)
                        DashboardSecuritySettingTile(
                          item: item,
                          isInteractionDisabled: isInteractionDisabled,
                          onToggle: (value) =>
                              controller.toggle(item.type, value),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
