import 'package:equatable/equatable.dart';

class NotificationHistoryItem extends Equatable {
  const NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String timestamp;
  final bool isRead;

  NotificationHistoryItem copyWith({
    String? id,
    String? title,
    String? body,
    String? timestamp,
    bool? isRead,
  }) {
    return NotificationHistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, title, body, timestamp, isRead];
}
