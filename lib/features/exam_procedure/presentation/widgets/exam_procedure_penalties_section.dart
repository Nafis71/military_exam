import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ExamProcedurePenaltiesSection extends StatelessWidget {
  const ExamProcedurePenaltiesSection({super.key});

  static const _penalties = [
    AppStrings.penaltyLeaveApp,
    AppStrings.penaltyDisableVpn,
    AppStrings.penaltyUnregisteredDevice,
    AppStrings.penaltyFailedVerification,
    AppStrings.penaltyBypassSecurity,
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.cE5EBE7,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cD9E5DE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.securityPenaltiesTitle,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.c0F3D2E,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.securityPenaltiesDescription,
            style: textTheme.bodySmall?.copyWith(color: AppColors.c66736C),
          ),
          SizedBox(height: 12.h),
          for (final penalty in _penalties)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16.sp, color: AppColors.c66736C),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      penalty,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.c66736C,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
