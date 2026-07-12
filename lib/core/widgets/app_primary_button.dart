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
    this.trailingIcon,
    this.borderRadius,
    this.boxShadow,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;
  final Color? backgroundColor;
  final IconData? trailingIcon;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;

  static final _labelStyle =
      AppTypography.labelLarge.copyWith(color: AppColors.cFFFFFF);

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: AppColors.cFFFFFF,
        disabledBackgroundColor: AppColors.cE5EBE7,
        disabledForegroundColor: AppColors.c98A39D,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
        textStyle: _labelStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 30.r),
        ),
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
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: _labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (trailingIcon != null) ...[
                  SizedBox(width: 8.w),
                  Icon(trailingIcon, color: AppColors.cFFFFFF, size: 24.sp),
                ],
              ],
            ),
    );

    Widget result = expanded ? SizedBox(width: double.infinity, child: button) : button;
    if (boxShadow != null && onPressed != null) {
      result = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 30.r),
          boxShadow: boxShadow,
        ),
        child: result,
      );
    }
    return result;
  }
}
