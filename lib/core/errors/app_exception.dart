sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.code});
}

class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class BadRequestException extends AppException {
  const BadRequestException(super.message, {super.code});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.code});
}

class UploadException extends AppException {
  const UploadException(super.message, {super.code});
}

class SecurityException extends AppException {
  const SecurityException(super.message, {super.code});
}

class PlatformExceptionWrapper extends AppException {
  const PlatformExceptionWrapper(super.message, {super.code});
}

class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}
