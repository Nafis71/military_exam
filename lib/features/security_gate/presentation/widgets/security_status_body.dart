import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_png_asset.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../../../../core/widgets/typewriter_text.dart';
import 'security_gate_icon_card.dart';

class SecurityStatusBody extends StatelessWidget {
  const SecurityStatusBody({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.isLoading = false,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionColor,
    this.footer,
    this.contentKey,
    this.typewriterMessage = false,
    this.wrapIconInCard = true,
  });

  final String title;
  final String message;
  final Widget? icon;
  final Color? iconColor;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color? secondaryActionColor;
  final Widget? footer;

  /// When this value changes, icon/title/message replay their entrance animation.
  final Object? contentKey;
  final bool typewriterMessage;
  final bool wrapIconInCard;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleMedium?.copyWith(
      fontSize: 20.sp,
      fontWeight: FontWeight.w700,
      color: AppColors.c094C3C,
      height: 28 / 20,
    );
    final messageStyle = textTheme.bodyMedium?.copyWith(
      color: AppColors.c474E5A,
      height: 22 / 14,
    );
    final resolvedSecondaryColor = secondaryActionColor ?? AppColors.cBDBDBD;
    final resolvedPrimaryColor = iconColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        StaggeredEntrance(
          contentKey: contentKey,
          children: [
            Center(child: _buildIcon()),
            SizedBox(height: 44.h),
            Text(
              title,
              style: titleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            typewriterMessage
                ? TypewriterText(
                    text: message,
                    style: messageStyle,
                    textAlign: TextAlign.center,
                    repeat: true,
                  )
                : Text(
                    message,
                    style: messageStyle,
                    textAlign: TextAlign.center,
                  ),
            if (footer != null) ...[
              SizedBox(height: 24.h),
              footer!,
            ],
          ],
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null ||
            secondaryActionLabel != null && onSecondaryAction != null)
          StaggeredEntrance(
            contentKey: contentKey,
            children: [
              if (actionLabel != null && onAction != null)
                AppPrimaryButton(
                  label: actionLabel!,
                  isLoading: isLoading,
                  backgroundColor: resolvedPrimaryColor,
                  onPressed: onAction,
                ),
              if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                SizedBox(height: 13.h),
                OutlinedButton(
                  onPressed: isLoading ? null : onSecondaryAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: resolvedSecondaryColor == AppColors.cBDBDBD
                        ? AppColors.c000000
                        : resolvedSecondaryColor,
                    side: BorderSide(color: resolvedSecondaryColor),
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w400,
                      color: resolvedSecondaryColor == AppColors.cBDBDBD
                          ? AppColors.c000000
                          : resolvedSecondaryColor,
                    ),
                  ),
                  child: Text(secondaryActionLabel!),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildIcon() {
    final iconWidget = icon ??
        AppLogoView(
          width: 76.w,
          height: 76.h,
        );

    if (!wrapIconInCard) return iconWidget;

    return SecurityGateIconCard(
      child: SizedBox(
        width: 76.w,
        height: 76.w,
        child: FittedBox(fit: BoxFit.contain, child: iconWidget),
      ),
    );
  }
}
