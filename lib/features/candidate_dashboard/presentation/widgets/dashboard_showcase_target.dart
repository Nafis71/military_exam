import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/theme/app_colors.dart';
import '../constants/dashboard_showcase_scope.dart';

class DashboardShowcaseTarget extends StatelessWidget {
  const DashboardShowcaseTarget({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.targetBorderRadius,
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final BorderRadius? targetBorderRadius;

  @override
  Widget build(BuildContext context) {
    if (!DashboardShowcaseScope.isScopeReady) {
      return child;
    }

    final textTheme = Theme.of(context).textTheme;

    return Showcase(
      key: showcaseKey,
      scope: DashboardShowcaseScope.scope,
      title: title,
      description: description,
      tooltipBackgroundColor: AppColors.cFFFFFF,
      textColor: AppColors.c0F3D2E,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        color: AppColors.c0F3D2E,
        fontWeight: FontWeight.w700,
      ),
      descTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.c66736C),
      targetBorderRadius: targetBorderRadius ?? BorderRadius.circular(12.r),
      child: child,
    );
  }
}
