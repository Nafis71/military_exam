import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class CongratulationsDialog extends StatelessWidget {
  const CongratulationsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.cFFFFFF,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text(
        AppStrings.congratulationsTitle,
        style: textTheme.titleLarge?.copyWith(
          color: AppColors.c0F3D2E,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        AppStrings.congratulationsMessage,
        style: textTheme.bodyMedium?.copyWith(color: AppColors.c66736C),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.c0A5943,
          ),
          child: Text(AppStrings.viewExaminationProcedure),
        ),
      ],
    );
  }
}
