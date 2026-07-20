import '../../../../shared/domain/entities/exam_entities.dart';

abstract final class ExamWaitingUtils {
  static bool isWaitingForExamStart(CurrentExam? exam) {
    if (exam == null) return false;

    final startTime = exam.window.startTime;
    final now = DateTime.now().toUtc();
    final hasStarted =
        startTime == null || !now.isBefore(startTime.toUtc());

    if (!hasStarted) return true;
    return !exam.window.canAccessQuestions;
  }

  static Duration timeUntilExamStart(CurrentExam? exam) {
    final startTime = exam?.window.startTime;
    if (startTime == null) return Duration.zero;
    final remaining = startTime.toUtc().difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static bool hasCountdownTarget(CurrentExam? exam) =>
      exam?.window.startTime != null;

  static String formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final time = '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    if (days > 0) {
      return '$days দিন $time';
    }
    return time;
  }
}
