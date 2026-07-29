import 'package:dio/dio.dart';

import '../config/deployment.dart';
import '../logging/app_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class DioFactory {
  DioFactory({
    required AppLogger logger,
    String? Function()? tokenProvider,
  })  : _logger = logger,
        _tokenProvider = tokenProvider;

  final AppLogger _logger;
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
    ]);

    return dio;
  }
}
