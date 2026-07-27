import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardNotificationIconButton extends StatelessWidget {
  const DashboardNotificationIconButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: AppStrings.notificationsAccessibilityLabel,
      icon: Icon(
        Icons.notifications_outlined,
        color: AppColors.c0F3D2E,
        size: 24.sp,
      ),
    );
  }
}
