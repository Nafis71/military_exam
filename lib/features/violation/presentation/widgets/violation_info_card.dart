import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

/// Bottom info card with red bullet rules.
class ViolationInfoCard extends StatelessWidget {
  const ViolationInfoCard({
    super.key,
    required this.bullets,
  });

  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 21.w, vertical: 17.h),
      decoration: BoxDecoration(
        color: AppColors.cFFFFFF,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.cD9E5DE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < bullets.length; i++) ...[
            if (i > 0) SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.cC43D4D,
                    height: 24 / 16,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    bullets[i],
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.c66736C,
                      height: 20.8 / 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
