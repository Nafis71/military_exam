abstract final class ExamDurationUtils {
  static int elapsedSeconds({
    required int totalDurationMinutes,
    DateTime? examStartTime,
    int? timerRemainingSeconds,
    DateTime? sessionStartedAt,
    int? remainingExamMinutes,
  }) {
    if (totalDurationMinutes <= 0) return 0;

    final maxSeconds = totalDurationMinutes * 60;
    int? elapsed;

    if (timerRemainingSeconds != null && timerRemainingSeconds >= 0) {
      elapsed = maxSeconds - timerRemainingSeconds;
    }

    if (elapsed == null && sessionStartedAt != null) {
      elapsed = DateTime.now().difference(sessionStartedAt).inSeconds;
    }

    if (elapsed == null && examStartTime != null) {
      final startUtc = examStartTime.toUtc();
      final nowUtc = DateTime.now().toUtc();
      if (!nowUtc.isBefore(startUtc)) {
        elapsed = nowUtc.difference(startUtc).inSeconds;
      }
    }

    if (elapsed == null && remainingExamMinutes != null) {
      final minutesElapsed = totalDurationMinutes - remainingExamMinutes;
      if (minutesElapsed >= 0 && minutesElapsed <= totalDurationMinutes) {
        elapsed = minutesElapsed * 60;
      }
    }

    return (elapsed ?? 0).clamp(0, maxSeconds);
  }

  static String formatMinutes(int minutes) => '$minutes মিনিট';

  static String formatElapsedDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes == 0) return '$seconds সেকেন্ড';
    if (seconds == 0) return '$minutes মিনিট';
    return '$minutes মিনিট $seconds সেকেন্ড';
  }
}
