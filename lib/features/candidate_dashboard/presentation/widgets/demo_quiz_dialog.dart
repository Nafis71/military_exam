import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class DemoQuizDialog extends StatelessWidget {
  const DemoQuizDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.cFFFFFF,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text(
        AppStrings.demoQuizTitle,
        style: textTheme.titleLarge?.copyWith(
          color: AppColors.c0F3D2E,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        AppStrings.demoQuizMessage,
        style: textTheme.bodyMedium?.copyWith(color: AppColors.c66736C),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            AppStrings.skip,
            style: textTheme.labelLarge?.copyWith(color: AppColors.c66736C),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.c0A5943,
          ),
          child: Text(AppStrings.startDemoButton),
        ),
      ],
    );
  }
}
