import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_primary_button.dart';

class ExamQuestionNavigationBar extends StatelessWidget {
  const ExamQuestionNavigationBar({
    super.key,
    required this.canGoBack,
    required this.onPrevious,
    required this.primaryLabel,
    required this.onPrimary,
    required this.isPrimaryLoading,
    required this.isPrimaryEnabled,
    this.primaryBoxShadow,
  });

  final bool canGoBack;
  final VoidCallback? onPrevious;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool isPrimaryLoading;
  final bool isPrimaryEnabled;
  final List<BoxShadow>? primaryBoxShadow;

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.c176B4D,
        );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md.w + mediaPadding.left,
        17.h,
        AppSpacing.md.w + mediaPadding.right,
        16.h + mediaPadding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cF7FAF8,
        border: Border(top: BorderSide(color: AppColors.cD9E5DE)),
      ),
      child: Row(
        children: [
          if (canGoBack) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.c176B4D,
                  side: const BorderSide(color: AppColors.cD9E5DE),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  AppStrings.previousQuestion,
                  style: labelStyle,
                ),
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: AppPrimaryButton(
              label: primaryLabel,
              isLoading: isPrimaryLoading,
              onPressed: isPrimaryEnabled ? onPrimary : null,
              boxShadow: primaryBoxShadow,
            ),
          ),
        ],
      ),
    );
  }
}
