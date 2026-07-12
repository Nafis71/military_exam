import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class WrittenExamHeader extends StatelessWidget {
  const WrittenExamHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.35, -1.0),
          end: Alignment(0.35, 1.0),
          colors: [AppColors.c0F3D2E, AppColors.c176B4D],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 25.h),
          child: Center(
            child: Text(
              AppStrings.writtenAnswers,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cFFFFFF,
                    height: 27 / 18,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
