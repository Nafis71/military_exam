import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class SecurityInstructionBox extends StatelessWidget {
  const SecurityInstructionBox({
    super.key,
    required this.instruction,
  });

  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cFCFFFE,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.c0A5943),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠️',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 25.sp,
                  height: 1.5,
                ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.importantInstruction,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.c0A5943,
                        height: 21 / 14,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  instruction,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11.sp,
                        color: AppColors.c474E5A,
                        height: 20.8 / 11,
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
