import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/dashboard_security_setting_item.dart';
import '../controllers/dashboard_security_settings_controller.dart';

class DashboardSecuritySettingTile extends StatelessWidget {
  const DashboardSecuritySettingTile({
    super.key,
    required this.item,
    required this.isInteractionDisabled,
    required this.onToggle,
  });

  final DashboardSecuritySettingItem item;
  final bool isInteractionDisabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DashboardSecuritySettingsController.titleFor(item.type),
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.c0F3D2E,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  DashboardSecuritySettingsController.descriptionFor(item.type),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.c66736C,
                  ),
                ),
                if (item.hasError) ...[
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    AppStrings.securitySettingCheckFailed,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                if (item.disabledHint != null) ...[
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    item.disabledHint!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Switch(
            value: item.isEnabled,
            onChanged: isInteractionDisabled || item.isToggleDisabled
                ? null
                : onToggle,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.c89D5B2,
          ),
        ],
      ),
    );
  }
}
