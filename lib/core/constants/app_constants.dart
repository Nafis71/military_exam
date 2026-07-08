abstract final class AppConstants {
  static const String appName = 'Military Exam';
  static const Duration splashMinDuration = Duration(seconds: 2);
  static const securityGateMinCheckingDuration =
      Duration(milliseconds: 1200);
  static const mcqQuestionEntranceDuration = Duration(milliseconds: 650);
  static const Duration airplaneModePollInterval = Duration(seconds: 2);
  static const Duration securityPollInterval = Duration(seconds: 3);
  static const Duration lifecycleViolationGracePeriod = Duration(seconds: 1);
  static const Duration settingsReturnRecheckDelay =
      Duration(milliseconds: 400);
  static const int defaultExamDurationMinutes = 60;
  static const int maxWrittenImages = 10;
}
