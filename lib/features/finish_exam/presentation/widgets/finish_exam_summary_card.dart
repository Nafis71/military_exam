import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import 'finish_exam_summary_row.dart';

/// Submission details card matching Figma node 4:2565.
class FinishExamSummaryCard extends StatelessWidget {
  const FinishExamSummaryCard({
    super.key,
    required this.examName,
    required this.submittedAtLabel,
  });

  final String examName;
  final String submittedAtLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 360.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.cFFFFFF,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.c0F3D2E.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FinishExamSummaryRow(
            label: AppStrings.finishExamNameLabel,
            value: examName,
          ),
          FinishExamSummaryRow(
            label: AppStrings.finishExamTimeLabel,
            value: submittedAtLabel,
          ),
          FinishExamSummaryRow(
            label: AppStrings.finishExamStatusLabel,
            value: AppStrings.finishExamStatusCompleted,
            valueColor: AppColors.c1D8A57,
            valueFontWeight: FontWeight.w600,
          ),
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Text(
              AppStrings.finishExamResultsLaterNote,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.c66736C,
                height: 19.2 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
