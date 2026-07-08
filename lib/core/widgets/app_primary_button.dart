import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.expanded = true,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;
  final Color? backgroundColor;

  static final _labelStyle =
      AppTypography.labelLarge.copyWith(color: AppColors.cFFFFFF);

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: AppColors.cFFFFFF,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        disabledForegroundColor: AppColors.cFFFFFF.withValues(alpha: 0.7),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
        textStyle: _labelStyle,
      ),
      child: isLoading
          ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.cFFFFFF,
              ),
            )
          : Text(label, style: _labelStyle),
    );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
