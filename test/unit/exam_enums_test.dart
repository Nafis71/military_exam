import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  test('ViolationType display messages are user readable', () {
    expect(
      ViolationType.airplaneModeDisabled.displayMessage,
      contains('Airplane Mode'),
    );
    expect(
      ViolationType.screenshotTaken.displayMessage,
      contains('screenshot'),
    );
  });
}
