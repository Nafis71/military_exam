import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/features/auth/data/models/login_request_model.dart';
import 'package:military_exam/features/auth/domain/entities/login_credentials.dart';

void main() {
  group('LoginRequestModel', () {
    test('toJson emits roll_number and batch_password', () {
      const model = LoginRequestModel(
        rollNumber: '8',
        batchPassword: 'secret',
      );

      expect(model.toJson(), {
        'roll_number': '8',
        'batch_password': 'secret',
      });
    });

    test('fromCredentials copies entity fields', () {
      const credentials = LoginCredentials(
        rollNumber: '1',
        batchPassword: 'pass',
      );

      final model = LoginRequestModel.fromCredentials(credentials);

      expect(model.rollNumber, '1');
      expect(model.batchPassword, 'pass');
      expect(model.toJson(), {
        'roll_number': '1',
        'batch_password': 'pass',
      });
    });
  });
}
