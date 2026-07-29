import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/notification_history_item.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationsController extends GetxController {
  NotificationsController(this._notificationRepository, this._logger);

  final NotificationRepository _notificationRepository;
  final AppLogger _logger;

  final notifications = <NotificationHistoryItem>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_load());
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final notificationsResult = await _notificationRepository.getNotifications();
      switch (notificationsResult) {
        case Success(:final data):
          notifications.assignAll(data);
        case ErrorResult():
          notifications.clear();
      }

      await _notificationRepository.markAllAsRead();
    } catch (e, st) {
      notifications.clear();
      if (kDebugMode) {
        _logger.error('notifications load failed', error: e, stackTrace: st);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
