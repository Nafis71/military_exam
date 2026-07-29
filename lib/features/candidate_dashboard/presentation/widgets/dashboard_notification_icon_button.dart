import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardNotificationIconButton extends StatelessWidget {
  const DashboardNotificationIconButton({
    super.key,
    required this.onPressed,
    this.unreadCount = 0,
  });

  final VoidCallback onPressed;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.notifications_outlined,
      color: AppColors.c0F3D2E,
      size: 24.sp,
    );

    return IconButton(
      onPressed: onPressed,
      tooltip: AppStrings.notificationsAccessibilityLabel,
      icon: unreadCount > 0
          ? Badge(
              backgroundColor: AppColors.cA51D21,
              label: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: TextStyle(
                  color: AppColors.cFFFFFF,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: icon,
            )
          : icon,
    );
  }
}
