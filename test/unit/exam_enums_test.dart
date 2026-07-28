import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  test('ViolationType display messages are user readable', () {
    expect(
      ViolationType.airplaneModeDisabled.displayMessage,
      AppStrings.airplaneModeDisabledDuringExam,
    );
    expect(
      ViolationType.screenshotTaken.displayMessage,
      AppStrings.screenshotAttemptDetected,
    );
    expect(
      ViolationType.airplaneModeDisabled.displayMessage,
      isNotEmpty,
    );
  });
}
