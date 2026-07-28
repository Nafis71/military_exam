import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/features/auth/data/models/login_request_model.dart';
import 'package:military_exam/features/auth/domain/entities/login_credentials.dart';

void main() {
  group('LoginRequestModel', () {
    test('toJson emits roll_number only', () {
      const model = LoginRequestModel(
        rollNumber: '8',
      );

      expect(model.toJson(), {
        'roll_number': '8',
      });
    });

    test('fromCredentials copies entity fields', () {
      const credentials = LoginCredentials(
        rollNumber: '1',
      );

      final model = LoginRequestModel.fromCredentials(credentials);

      expect(model.rollNumber, '1');
      expect(model.toJson(), {
        'roll_number': '1',
      });
    });
  });
}
