import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_png_asset.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../../../../core/widgets/typewriter_text.dart';

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
    this.footer,
    this.contentKey,
    this.typewriterMessage = false,
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
  final Widget? footer;

  /// When this value changes, icon/title/message replay their entrance animation.
  final Object? contentKey;
  final bool typewriterMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        StaggeredEntrance(
          contentKey: contentKey,
          children: [
            Center(
              child: icon ??
                  AppLogoView(
                    width: 200.w,
                    height: 200.h,
                  ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Text(
              title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm.h),
            typewriterMessage
                ? TypewriterText(
                    text: message,
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                    repeat: true,
                  )
                : Text(
                    message,
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
            if (footer != null) ...[
              SizedBox(height: AppSpacing.md.h),
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
                  backgroundColor: iconColor ?? AppColors.primary,
                  onPressed: onAction,
                ),
              if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                SizedBox(height: AppSpacing.sm.h),
                OutlinedButton(
                  onPressed: isLoading ? null : onSecondaryAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
                  ),
                  child: Text(secondaryActionLabel!),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
