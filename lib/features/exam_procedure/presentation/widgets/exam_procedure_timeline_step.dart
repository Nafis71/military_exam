import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ExamProcedureTimelineStep extends StatelessWidget {
  const ExamProcedureTimelineStep({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.cD9E5DE,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.c0A5943, size: 20.sp),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    color: AppColors.cD9E5DE,
                  ),
                ),
            ],
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.c0F3D2E,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.c66736C,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
