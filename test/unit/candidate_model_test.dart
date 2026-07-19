import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/features/auth/data/models/candidate_model.dart';

void main() {
  group('CandidateModel', () {
    test('fromJson parses API envelope and maps to AuthSession', () {
      final model = CandidateModel.fromJson({
        'success': true,
        'statusCode': 201,
        'message': 'Candidate login successful',
        'data': {
          'id': 'e755bfa9-6723-4321-a005-16c27aa26826',
          'full_name': 'MD. SAHANUR RAHMAN SAYEM',
          'district': 'DHAKA',
          'roll_number': '1',
          'status': 'attended',
        },
      });

      expect(model.id, 'e755bfa9-6723-4321-a005-16c27aa26826');
      expect(model.fullName, 'MD. SAHANUR RAHMAN SAYEM');
      expect(model.district, 'DHAKA');
      expect(model.rollNumber, '1');
      expect(model.status, 'attended');

      final session = model.toAuthSession();
      expect(session.token, '');
      expect(session.sessionId, model.id);
      expect(session.examinee.id, model.id);
      expect(session.examinee.name, model.fullName);
      expect(session.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('fromJson accepts bare data object', () {
      final model = CandidateModel.fromJson({
        'id': 'abc',
        'full_name': 'Test Candidate',
        'district': 'Dhaka',
        'roll_number': '8',
        'status': 'attended',
      });

      expect(model.id, 'abc');
      expect(model.rollNumber, '8');
    });
  });
}
