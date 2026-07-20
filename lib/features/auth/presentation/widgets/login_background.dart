import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.85, -1.0),
          end: Alignment(0.85, 1.0),
          colors: [
            AppColors.c0F3D2E,
            AppColors.c176B4D,
            AppColors.c23966A,
          ],
          stops: [0.085, 0.583, 0.915],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: 24.h),
        child: child,
      ),
    );
  }
}
