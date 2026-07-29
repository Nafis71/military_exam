import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/notification_history_item.dart';
import '../../domain/repositories/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository() {
    _notifications = _buildInitialNotifications();
  }

  late List<NotificationHistoryItem> _notifications;

  List<NotificationHistoryItem> _buildInitialNotifications() {
    return const [
      NotificationHistoryItem(
        id: 'exam-reminder',
        title: AppStrings.mockNotificationExamReminderTitle,
        body: AppStrings.mockNotificationExamReminderBody,
        timestamp: AppStrings.mockNotificationExamReminderTimestamp,
      ),
      NotificationHistoryItem(
        id: 'device-bound',
        title: AppStrings.mockNotificationDeviceBoundTitle,
        body: AppStrings.mockNotificationDeviceBoundBody,
        timestamp: AppStrings.mockNotificationDeviceBoundTimestamp,
      ),
      NotificationHistoryItem(
        id: 'demo-completed',
        title: AppStrings.mockNotificationDemoCompletedTitle,
        body: AppStrings.mockNotificationDemoCompletedBody,
        timestamp: AppStrings.mockNotificationDemoCompletedTimestamp,
      ),
      NotificationHistoryItem(
        id: 'security-tip',
        title: AppStrings.mockNotificationSecurityTipTitle,
        body: AppStrings.mockNotificationSecurityTipBody,
        timestamp: AppStrings.mockNotificationSecurityTipTimestamp,
      ),
    ];
  }

  @override
  Future<Result<List<NotificationHistoryItem>>> getNotifications() async {
    return Success(List<NotificationHistoryItem>.unmodifiable(_notifications));
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    final unreadCount =
        _notifications.where((notification) => !notification.isRead).length;
    return Success(unreadCount);
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList(growable: false);
    return const Success(null);
  }
}
