import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// White rounded status icon card with glow and circular icon background.
class AppStatusIconCard extends StatelessWidget {
  const AppStatusIconCard({
    super.key,
    required this.child,
    this.glowColor,
    this.circleColor,
  });

  final Widget child;
  final Color? glowColor;
  final Color? circleColor;

  @override
  Widget build(BuildContext context) {
    final resolvedGlow = glowColor ?? AppColors.c89D5B2.withValues(alpha: 0.7);
    final resolvedCircle =
        circleColor ?? AppColors.c89D5B2.withValues(alpha: 0.25);

    return Container(
      width: 160.w,
      height: 160.w,
      decoration: BoxDecoration(
        color: AppColors.cFFFFFF,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: resolvedGlow,
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            color: resolvedCircle,
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
