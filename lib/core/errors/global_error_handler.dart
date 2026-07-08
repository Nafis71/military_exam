import '../logging/app_logger.dart';

class GlobalErrorHandler {
  GlobalErrorHandler(this._logger);

  final AppLogger _logger;

  void handle(Object error, StackTrace stackTrace, {String? context}) {
    _logger.error(
      context ?? 'Unhandled error',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
