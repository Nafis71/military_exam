import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class UnbindDeviceDialog extends StatelessWidget {
  const UnbindDeviceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.cFFFFFF,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text(
        AppStrings.unbindDeviceDialogTitle,
        style: textTheme.titleLarge?.copyWith(
          color: AppColors.c0F3D2E,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        AppStrings.unbindDeviceDialogMessage,
        style: textTheme.bodyMedium?.copyWith(color: AppColors.c66736C),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            AppStrings.cancelAction,
            style: textTheme.labelLarge?.copyWith(color: AppColors.c66736C),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.cDC2626,
          ),
          child: Text(AppStrings.unbindDeviceConfirm),
        ),
      ],
    );
  }
}
