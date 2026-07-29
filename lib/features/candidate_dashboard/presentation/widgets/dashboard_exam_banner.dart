import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/exam_info.dart';

class DashboardExamBanner extends StatelessWidget {
  const DashboardExamBanner({
    super.key,
    this.examInfo,
    required this.onStartExamination,
  });

  final ExamInfo? examInfo;
  final VoidCallback onStartExamination;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        gradient: AppColors.brandHeaderGradient,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.c89D5B2.withValues(alpha: 0.4),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.examinationInfo,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.cFFFFFF.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            examInfo?.title ?? '—',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.cFFFFFF,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          _InfoRow(
            label: AppStrings.examDate,
            value: examInfo?.date ?? '—',
          ),
          SizedBox(height: 4.h),
          _InfoRow(
            label: AppStrings.examVenue,
            value: examInfo?.venue ?? '—',
          ),
          SizedBox(height: 4.h),
          _InfoRow(
            label: AppStrings.examStatus,
            value: examInfo?.status ?? '—',
          ),
          SizedBox(height: 20.h),
          Align(
            alignment: Alignment.centerRight,
            child: _ExamStartButton(onPressed: onStartExamination),
          ),
        ],
      ),
    );
  }
}

class _ExamStartButton extends StatelessWidget {
  const _ExamStartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.cFFFFFF,
        foregroundColor: AppColors.c0A5943,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.startExamination,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.c0A5943,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8.w),
          Icon(Icons.arrow_forward, color: AppColors.c0A5943, size: 20.sp),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.cFFFFFF.withValues(alpha: 0.8),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.cFFFFFF,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
