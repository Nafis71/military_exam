import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';
import '../../logging/log_event.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.logEvent(
      LogEvent(
        category: LogCategory.api,
        type: LogEventType.request,
        message: '${options.method} ${options.uri}',
        data: {'headers': _sanitize(options.headers)},
      ),
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.logEvent(
      LogEvent(
        category: LogCategory.api,
        type: LogEventType.response,
        message: '${response.statusCode} ${response.requestOptions.uri}',
      ),
    );
    handler.next(response);
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      copy['Authorization'] = '***';
    }
    return copy;
  }
}
