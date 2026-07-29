import '../../../../core/utils/result.dart';
import '../entities/notification_history_item.dart';

abstract class NotificationRepository {
  Future<Result<List<NotificationHistoryItem>>> getNotifications();

  Future<Result<int>> getUnreadCount();

  Future<Result<void>> markAllAsRead();
}
