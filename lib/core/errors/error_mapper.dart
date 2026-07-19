import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
import 'app_exception.dart';
import 'failure.dart';

class ErrorMapper {
  Failure mapException(Object error) {
    if (error is Failure) return error;
    if (error is AppException) return _mapAppException(error);
    if (error is DioException) return _mapDioException(error);
    return UnexpectedFailure(error.toString());
  }

  Failure _mapAppException(AppException exception) {
    return switch (exception) {
      UnauthorizedException() => AuthFailure(exception.message),
      ForbiddenException() => ExamLockedFailure(exception.message),
      SecurityException() => SecurityFailure(exception.message),
      UploadException() => UploadFailure(exception.message),
      ValidationException() => ValidationFailure(exception.message),
      NetworkException() ||
      TimeoutException() =>
        NetworkFailure(exception.message),
      _ => UnexpectedFailure(exception.message),
    };
  }

  Failure _mapDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final message = exception.response?.data?['message']?.toString() ??
        exception.message ??
        AppStrings.networkRequestFailed;

    if (statusCode == 401 || statusCode == 404) return AuthFailure(message);
    if (statusCode == 403) return ExamLockedFailure(message);
    if (statusCode == 422) return ValidationFailure(message);
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout) {
      return NetworkFailure(AppStrings.requestTimedOut);
    }
    if (exception.type == DioExceptionType.connectionError) {
      return NetworkFailure(AppStrings.noInternetConnection);
    }
    return NetworkFailure(message);
  }
}
