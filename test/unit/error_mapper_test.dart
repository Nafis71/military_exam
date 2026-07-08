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

    test('maps security exception to security failure', () {
      final failure = mapper.mapException(
        const SecurityException('Device compromised'),
      );
      expect(failure, isA<SecurityFailure>());
    });
  });
}
