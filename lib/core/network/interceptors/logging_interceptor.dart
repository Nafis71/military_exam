import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';
import '../../logging/log_event.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this._logger);

  final AppLogger _logger;

  static const _sensitiveKeys = {
    'authorization',
    'password',
    'token',
    'access_token',
    'refresh_token',
    'accesstoken',
    'refreshtoken',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.logEvent(
      LogEvent(
        category: LogCategory.api,
        type: LogEventType.request,
        message: '${options.method} ${options.uri}',
        data: {
          'headers': _sanitizeMap(options.headers),
          if (options.data != null) 'body': _serializePayload(options.data),
        },
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
        data: {
          'response': _serializePayload(response.data),
        },
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.logEvent(
      LogEvent(
        category: LogCategory.api,
        type: LogEventType.exception,
        message: '${err.response?.statusCode ?? 'ERR'} ${err.requestOptions.uri}',
        data: {
          'errorType': err.type.name,
          if (err.response?.data != null)
            'response': _serializePayload(err.response!.data),
        },
      ),
    );
    handler.next(err);
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> source) {
    final copy = Map<String, dynamic>.from(source);
    for (final entry in copy.entries) {
      if (_sensitiveKeys.contains(entry.key.toLowerCase())) {
        copy[entry.key] = '***';
      }
    }
    return copy;
  }

  dynamic _serializePayload(dynamic data) {
    if (data == null) return null;
    if (data is FormData) {
      return {
        'type': 'FormData',
        'fields': _sanitizeMap(
          Map<String, dynamic>.fromEntries(
            data.fields.map((entry) => MapEntry(entry.key, entry.value)),
          ),
        ),
        'files': data.files.map((file) => file.key).toList(),
      };
    }
    if (data is List<int>) return '<binary ${data.length} bytes>';
    if (data is Map) return _sanitizeMap(Map<String, dynamic>.from(data));
    return data;
  }
}
