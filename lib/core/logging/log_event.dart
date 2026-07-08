enum LogCategory {
  api,
  auth,
  security,
  lifecycle,
  upload,
  exam,
  general,
}

enum LogEventType {
  request,
  response,
  violation,
  lifecycleChange,
  uploadProgress,
  authentication,
  exception,
}

class LogEvent {
  const LogEvent({
    required this.category,
    required this.type,
    required this.message,
    this.data,
  });

  final LogCategory category;
  final LogEventType type;
  final String message;
  final Map<String, dynamic>? data;
}
