import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

class SecurityInstructionBox extends StatelessWidget {
  const SecurityInstructionBox({
    super.key,
    required this.instruction,
    this.useLightText = false,
  });

  final String instruction;
  final bool useLightText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: useLightText
            ? AppColors.cFFFFFF.withValues(alpha: 0.15)
            : AppColors.cFCFFFE,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: useLightText
              ? AppColors.cFFFFFF.withValues(alpha: 0.35)
              : AppColors.c0A5943,
        ),
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
                        color:
                            useLightText ? AppColors.cFFFFFF : AppColors.c0A5943,
                        height: 21 / 14,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  instruction,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11.sp,
                        color:
                            useLightText ? AppColors.cFFFFFF : AppColors.c474E5A,
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
