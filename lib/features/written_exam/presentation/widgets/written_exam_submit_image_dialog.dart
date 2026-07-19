import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';

class WrittenExamSubmitImageDialog extends StatelessWidget {
  const WrittenExamSubmitImageDialog({
    super.key,
    required this.imagePath,
    required this.onSubmit,
    required this.onRetake,
  });

  final String imagePath;
  final VoidCallback onSubmit;
  final VoidCallback onRetake;

  static Future<bool?> show({
    required BuildContext context,
    required String imagePath,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WrittenExamSubmitImageDialog(
        imagePath: imagePath,
        onSubmit: () => Navigator.of(context).pop(true),
        onRetake: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.writtenExamConfirmImageTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.c17231D,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              AppStrings.writtenExamConfirmImageMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.c66736C,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                height: 180.h,
                width: double.infinity,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            AppPrimaryButton(
              label: AppStrings.writtenExamSubmitImage,
              onPressed: onSubmit,
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRetake,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.c176B4D,
                  side: const BorderSide(color: AppColors.cD9E5DE),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  AppStrings.writtenExamRetakeImage,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.c176B4D,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
