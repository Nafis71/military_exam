import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('examineeId rejects empty values', () {
      expect(Validators.examineeId(null), isNotNull);
      expect(Validators.examineeId(''), isNotNull);
    });

    test('examineeId accepts valid ids', () {
      expect(Validators.examineeId('soldier-001'), isNull);
    });

    test('password requires minimum length', () {
      expect(Validators.password('abc'), isNotNull);
      expect(Validators.password('secret'), isNull);
    });
  });
}
