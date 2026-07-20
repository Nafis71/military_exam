import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class ExamCountdownDisplay extends StatelessWidget {
  const ExamCountdownDisplay({
    super.key,
    required this.formattedCountdown,
  });

  final String formattedCountdown;

  @override
  Widget build(BuildContext context) {
    return Text(
      formattedCountdown,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 40.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.c0F3D2E,
            letterSpacing: 2,
          ),
    );
  }
}
