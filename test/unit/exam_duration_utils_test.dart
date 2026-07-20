import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/features/exam_session/domain/utils/exam_duration_utils.dart';

void main() {
  group('ExamDurationUtils.elapsedSeconds', () {
    test('prefers timer over exam start time when both are present', () {
      final examStart = DateTime.now().subtract(const Duration(minutes: 20));

      final elapsed = ExamDurationUtils.elapsedSeconds(
        totalDurationMinutes: 60,
        examStartTime: examStart,
        timerRemainingSeconds: 59 * 60,
      );

      expect(elapsed, 60);
    });

    test('uses exam start time when timer is absent', () {
      final examStart = DateTime.now().subtract(const Duration(minutes: 20));

      final elapsed = ExamDurationUtils.elapsedSeconds(
        totalDurationMinutes: 60,
        examStartTime: examStart,
      );

      expect(elapsed, inInclusiveRange(19 * 60, 21 * 60));
    });

    test('matches exam timer in waiting-room overcount scenario', () {
      // Scheduled open was 35 min ago, but student only had 30 min on the timer.
      final scheduledStart = DateTime.now().subtract(const Duration(minutes: 35));

      final elapsed = ExamDurationUtils.elapsedSeconds(
        totalDurationMinutes: 60,
        examStartTime: scheduledStart,
        timerRemainingSeconds: 30 * 60,
      );

      expect(elapsed, 30 * 60);
    });

    test('uses timer remaining seconds when exam start is absent', () {
      expect(
        ExamDurationUtils.elapsedSeconds(
          totalDurationMinutes: 60,
          timerRemainingSeconds: 30 * 60,
        ),
        30 * 60,
      );
    });

    test('uses session start when timer is absent', () {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 5, seconds: 15));

      final elapsed = ExamDurationUtils.elapsedSeconds(
        totalDurationMinutes: 60,
        sessionStartedAt: startedAt,
      );

      expect(elapsed, inInclusiveRange(314, 316));
    });

    test('uses server remaining minutes as last resort', () {
      expect(
        ExamDurationUtils.elapsedSeconds(
          totalDurationMinutes: 60,
          remainingExamMinutes: 25,
        ),
        35 * 60,
      );
    });

    test('clamps elapsed to total duration', () {
      expect(
        ExamDurationUtils.elapsedSeconds(
          totalDurationMinutes: 60,
          remainingExamMinutes: -5,
        ),
        0,
      );
    });
  });

  group('ExamDurationUtils.formatElapsedDuration', () {
    test('formats minutes and seconds', () {
      expect(ExamDurationUtils.formatElapsedDuration(90), '1 মিনিট 30 সেকেন্ড');
    });

    test('formats seconds only when under one minute', () {
      expect(ExamDurationUtils.formatElapsedDuration(45), '45 সেকেন্ড');
    });

    test('formats minutes only when seconds are zero', () {
      expect(ExamDurationUtils.formatElapsedDuration(1200), '20 মিনিট');
    });
  });
}
