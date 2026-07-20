import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/features/exam_session/domain/utils/exam_waiting_utils.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

void main() {
  group('ExamWaitingUtils', () {
    test('isWaitingForExamStart is true when canAccessQuestions is false', () {
      final exam = _exam(
        canAccessQuestions: false,
        startTime: DateTime.utc(2099, 1, 1, 12),
      );

      expect(ExamWaitingUtils.isWaitingForExamStart(exam), isTrue);
    });

    test('isWaitingForExamStart is true when start time is in the future', () {
      final exam = _exam(
        canAccessQuestions: true,
        startTime: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      expect(ExamWaitingUtils.isWaitingForExamStart(exam), isTrue);
    });

    test('isWaitingForExamStart is true when canAccessQuestions is false after start',
        () {
      final exam = _exam(
        canAccessQuestions: false,
        startTime: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

      expect(ExamWaitingUtils.isWaitingForExamStart(exam), isTrue);
    });

    test('isWaitingForExamStart is false when exam is open', () {
      final exam = _exam(
        canAccessQuestions: true,
        startTime: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );

      expect(ExamWaitingUtils.isWaitingForExamStart(exam), isFalse);
    });

    test('timeUntilExamStart clamps at zero after start', () {
      final exam = _exam(
        canAccessQuestions: true,
        startTime: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

      expect(ExamWaitingUtils.timeUntilExamStart(exam), Duration.zero);
    });

    test('formatCountdown uses HH:MM:SS under one day', () {
      const duration = Duration(hours: 1, minutes: 2, seconds: 3);
      expect(ExamWaitingUtils.formatCountdown(duration), '01:02:03');
    });

    test('formatCountdown includes days when needed', () {
      const duration = Duration(days: 1, hours: 2, minutes: 3, seconds: 4);
      expect(ExamWaitingUtils.formatCountdown(duration), '1 দিন 02:03:04');
    });
  });
}

CurrentExam _exam({
  required bool canAccessQuestions,
  required DateTime startTime,
}) {
  return CurrentExam(
    examId: 'exam-1',
    examName: 'Test Exam',
    batchName: 'Batch',
    batchStatus: 'active',
    batchId: 'batch-1',
    totalQuestions: 1,
    durationMinutes: 60,
    window: ExamWindow(
      startTime: startTime,
      examEndTime: null,
      submitEndTime: null,
      bufferTimeMinutes: 0,
      canAccessQuestions: canAccessQuestions,
      canSubmit: canAccessQuestions,
      remainingExamMinutes: canAccessQuestions ? 60 : 0,
      remainingSubmitMinutes: 0,
    ),
    questions: const [],
  );
}
