import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

class ExamSkipButton extends StatelessWidget {
  const ExamSkipButton({
    super.key,
    required this.onPressed,
    required this.isEnabled,
  });

  final VoidCallback? onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.cFFFFFF,
        disabledForegroundColor: AppColors.cFFFFFF.withValues(alpha: 0.4),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        AppStrings.skipQuestion,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isEnabled
                  ? AppColors.cFFFFFF
                  : AppColors.cFFFFFF.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
