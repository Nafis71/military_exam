import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class WrittenExamSuccessBanner extends StatelessWidget {
  const WrittenExamSuccessBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: AppColors.cEAF4EF,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.cD9E5DE),
      ),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: AppColors.c1D8A57,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Text(
              '✓',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.cFFFFFF,
                    height: 21 / 14,
                  ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              AppStrings.writtenExamImageAddedSuccess,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.c0F3D2E,
                    height: 21 / 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
