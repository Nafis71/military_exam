import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';

import '../theme/app_colors.dart';

class AppErrorToast {
  AppErrorToast._();

  static const Duration _duration = Duration(seconds: 3);

  static void show(String message) {
    showOverlayNotification(
      (context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: AppColors.cFEF2F2,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.cFEE2E2),
            ),
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                    height: 21 / 14,
                  ),
            ),
          ),
        ),
      ),
      duration: _duration,
      position: NotificationPosition.top,
    );
  }
}
