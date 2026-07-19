import 'package:dio/dio.dart';

import '../../errors/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = _mapError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapped,
        message: mapped.message,
      ),
    );
  }

  AppException _mapError(DioException err) {
    final statusCode = err.response?.statusCode;
    final message = err.response?.data?['message']?.toString() ??
        err.message ??
        'Network request failed';

    if (statusCode == 401 || statusCode == 404) {
      return UnauthorizedException(message, code: statusCode.toString());
    }
    if (statusCode == 400) {
      return BadRequestException(message, code: statusCode.toString());
    }
    if (statusCode == 403) {
      return ForbiddenException(message, code: statusCode.toString());
    }
    if (statusCode == 422) {
      return ValidationException(message, code: statusCode.toString());
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerException(message, code: statusCode.toString());
    }
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return TimeoutException('Request timed out');
    }
    if (err.type == DioExceptionType.connectionError) {
      return NetworkException('No internet connection');
    }
    return NetworkException(message);
  }
}
