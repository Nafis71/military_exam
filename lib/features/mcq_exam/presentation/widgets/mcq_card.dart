import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

class McqCard extends StatelessWidget {
  const McqCard({super.key, required this.question});

  final McqQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.c0F3D2E.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.cEAF4EF,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '${AppStrings.questionOf} ${question.index}',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.c176B4D,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            question.question,
            softWrap: true,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.c17231D,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
