import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/notification_history_item.dart';

class NotificationHistoryTile extends StatelessWidget {
  const NotificationHistoryTile({
    super.key,
    required this.notification,
  });

  final NotificationHistoryItem notification;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.surface : AppColors.cEAF4EF,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.c0F3D2E.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.c0F3D2E,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8.w,
                  height: 8.w,
                  margin: EdgeInsets.only(top: 6.h, left: AppSpacing.sm.w),
                  decoration: const BoxDecoration(
                    color: AppColors.c0A5943,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            notification.body,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.c66736C),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            notification.timestamp,
            style: textTheme.labelMedium?.copyWith(color: AppColors.c98A39D),
          ),
        ],
      ),
    );
  }
}
