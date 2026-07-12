import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';

class WrittenExamSubmitBar extends StatelessWidget {
  const WrittenExamSubmitBar({
    super.key,
    required this.onSubmit,
    required this.isLoading,
    required this.canSubmit,
    this.errorMessage,
  });

  final VoidCallback onSubmit;
  final bool isLoading;
  final bool canSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 17.h, 20.w, 32.h),
      decoration: const BoxDecoration(
        color: AppColors.cF7FAF8,
        border: Border(top: BorderSide(color: AppColors.cD9E5DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),
          AppPrimaryButton(
            label: canSubmit
                ? AppStrings.submitWrittenExam
                : AppStrings.submitWrittenExamDisabled,
            isLoading: isLoading,
            onPressed: !canSubmit || isLoading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
