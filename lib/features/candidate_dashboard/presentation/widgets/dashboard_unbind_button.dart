import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class DashboardUnbindButton extends StatelessWidget {
  const DashboardUnbindButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.cFFFFFF,
        foregroundColor: AppColors.c000000,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 18.h,
              width: 18.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.unbindDevice,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.c000000,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: AppSpacing.sm.w),
                Icon(Icons.link_off, color: AppColors.cDC2626, size: 20.sp),
              ],
            ),
    );
  }
}
