import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/notification_history_tile.dart';

class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.c0F3D2E),
          onPressed: Get.back,
        ),
        title: Text(
          AppStrings.notificationsTitle,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.c0F3D2E,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Text(
              AppStrings.notificationsEmpty,
              style: textTheme.bodyLarge?.copyWith(color: AppColors.c66736C),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          itemCount: controller.notifications.length,
          separatorBuilder: (context, index) => SizedBox(height: AppSpacing.md.h),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return NotificationHistoryTile(notification: notification);
          },
        );
      }),
    );
  }
}
