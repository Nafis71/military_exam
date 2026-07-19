import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/errors/error_mapper.dart';
import 'package:military_exam/core/errors/app_exception.dart';
import 'package:military_exam/core/errors/failure.dart';

void main() {
  group('ErrorMapper', () {
    final mapper = ErrorMapper();

    test('maps unauthorized exception to auth failure', () {
      final failure = mapper.mapException(
        const UnauthorizedException('Invalid credentials'),
      );
      expect(failure, isA<AuthFailure>());
    });

    test('maps 404 dio exception to auth failure with api message', () {
      final failure = mapper.mapException(
        DioException(
          requestOptions: RequestOptions(path: '/candidates/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/candidates/login'),
            statusCode: 404,
            data: const {
              'message': 'প্রার্থীর তথ্য পাওয়া যায়নি',
              'error': 'Not Found',
              'statusCode': 404,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'প্রার্থীর তথ্য পাওয়া যায়নি');
    });

    test('maps 400 dio exception to bad request failure with api message', () {
      final failure = mapper.mapException(
        DioException(
          requestOptions: RequestOptions(path: '/candidates/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/candidates/login'),
            statusCode: 400,
            data: const {
              'message':
                  'এখনো লগইন করা যাবে না। লগইন খুলবে: 2026-07-19 17:50:00',
              'error': 'Bad Request',
              'statusCode': 400,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(failure, isA<BadRequestFailure>());
      expect(
        failure.message,
        'এখনো লগইন করা যাবে না। লগইন খুলবে: 2026-07-19 17:50:00',
      );
    });

    test('maps security exception to security failure', () {
      final failure = mapper.mapException(
        const SecurityException('Device compromised'),
      );
      expect(failure, isA<SecurityFailure>());
    });
  });
}
