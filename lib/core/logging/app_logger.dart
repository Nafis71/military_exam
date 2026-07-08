import 'package:logger/logger.dart' hide LogEvent;

import '../config/deployment.dart';
import 'log_event.dart' as app_log;

class AppLogger {
  AppLogger()
      : _logger = Logger(
          printer: PrettyPrinter(methodCount: 0),
          level: Deployment.instance.isProduction ? Level.off : Level.debug,
        );

  final Logger _logger;

  void debug(String message, {Map<String, dynamic>? data}) {
    if (Deployment.instance.isProduction) return;
    _logger.d(_format(message, data));
  }

  void info(String message, {Map<String, dynamic>? data}) {
    if (Deployment.instance.isProduction) return;
    _logger.i(_format(message, data));
  }

  void warning(String message, {Map<String, dynamic>? data}) {
    if (Deployment.instance.isProduction) return;
    _logger.w(_format(message, data));
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (Deployment.instance.isProduction) return;
    _logger.e(_format(message, data), error: error, stackTrace: stackTrace);
  }

  void logEvent(app_log.LogEvent event) {
    if (Deployment.instance.isProduction) return;
    info('[${event.category.name}] ${event.type.name}: ${event.message}',
        data: event.data);
  }

  String _format(String message, Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return message;
    return '$message | $data';
  }
}
