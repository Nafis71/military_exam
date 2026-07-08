import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import '../utils/result.dart';

class ApiClient {
  ApiClient(this._dio, this._errorMapper);

  final Dio _dio;
  final ErrorMapper _errorMapper;

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
  }) =>
      _request(() => _dio.get(path, queryParameters: queryParameters), parser);

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
  }) =>
      _request(
        () => _dio.post(path, data: data, queryParameters: queryParameters),
        parser,
      );

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? parser,
  }) =>
      _request(() => _dio.delete(path, data: data), parser);

  Future<Result<T>> upload<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    T Function(dynamic json)? parser,
  }) =>
      _request(
        () => _dio.post(
          path,
          data: formData,
          onSendProgress: onSendProgress,
        ),
        parser,
      );

  Future<Result<T>> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic json)? parser,
  ) async {
    try {
      final response = await call();
      if (parser != null) {
        return Success(parser(response.data));
      }
      return Success(response.data as T);
    } catch (error) {
      if (error is DioException && error.error is AppException) {
        return ErrorResult(_errorMapper.mapException(error.error!));
      }
      return ErrorResult(_errorMapper.mapException(error));
    }
  }
}
