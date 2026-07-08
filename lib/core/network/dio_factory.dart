import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:uuid/uuid.dart';

import '../config/deployment.dart';
import '../logging/app_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class IdempotencyKeyProvider {
  const IdempotencyKeyProvider();

  String generate() => const Uuid().v4();
}

class DioFactory {
  DioFactory({
    required AppLogger logger,
    required IdempotencyKeyProvider idempotencyKeyProvider,
    String? Function()? tokenProvider,
  })  : _logger = logger,
        _idempotencyKeyProvider = idempotencyKeyProvider,
        _tokenProvider = tokenProvider;

  final AppLogger _logger;
  final IdempotencyKeyProvider _idempotencyKeyProvider;
  final String? Function()? _tokenProvider;

  Dio create() {
    final env = Deployment.instance.environment;
    final dio = Dio(
      BaseOptions(
        baseUrl: env.baseUrl,
        connectTimeout: env.connectTimeout,
        receiveTimeout: env.receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenProvider: _tokenProvider),
      LoggingInterceptor(_logger),
      RetryInterceptor(dio: dio),
      ErrorInterceptor(),
      if (env.enableNetworkLogs)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
        ),
    ]);

    return dio;
  }
}
