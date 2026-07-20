import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/security_gate/domain/utils/violation_submit_outcome.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

void main() {
  final receipt = SubmissionReceipt(
    submissionId: 'sub-1',
    submittedAt: DateTime(2026, 7, 20, 12),
    message: 'ok',
  );

  test('resolveViolationSubmitOutcome returns success on submit success', () {
    final outcome = resolveViolationSubmitOutcome(Success(receipt));

    expect(outcome.answersSubmitted, isTrue);
    expect(outcome.submissionPending, isFalse);
    expect(outcome.stopAutoRetry, isFalse);
  });

  test('resolveViolationSubmitOutcome marks network failure as pending', () {
    final outcome = resolveViolationSubmitOutcome(
      const ErrorResult(NetworkFailure('offline')),
    );

    expect(outcome.answersSubmitted, isFalse);
    expect(outcome.submissionPending, isTrue);
    expect(outcome.stopAutoRetry, isFalse);
  });

  test('resolveViolationSubmitOutcome marks missing image as non-retryable',
      () {
    final outcome = resolveViolationSubmitOutcome(
      const ErrorResult(UploadFailure(AppStrings.imageFileNotFound)),
    );

    expect(outcome.answersSubmitted, isFalse);
    expect(outcome.submissionPending, isFalse);
    expect(outcome.stopAutoRetry, isTrue);
  });

  test('resolveViolationSubmitOutcome marks other upload failures as pending',
      () {
    final outcome = resolveViolationSubmitOutcome(
      const ErrorResult(UploadFailure(AppStrings.writtenExamImageUploadFailed)),
    );

    expect(outcome.answersSubmitted, isFalse);
    expect(outcome.submissionPending, isTrue);
    expect(outcome.stopAutoRetry, isFalse);
  });

  test('resolveViolationSubmitOutcome marks validation failure as non-retryable',
      () {
    final outcome = resolveViolationSubmitOutcome(
      const ErrorResult(ValidationFailure('finalize failed')),
    );

    expect(outcome.answersSubmitted, isFalse);
    expect(outcome.submissionPending, isFalse);
    expect(outcome.stopAutoRetry, isTrue);
  });
}
