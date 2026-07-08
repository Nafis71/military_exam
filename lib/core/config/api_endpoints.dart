abstract final class ApiEndpoints {
  static const String login = '/auth/login';
  static const String eligibility = '/exam/eligibility';
  static const String sessionStart = '/exam/session/start';
  static const String sessionCurrent = '/exam/session/current';
  static const String sessionStatus = '/exam/session/status';
  static const String sessionLock = '/exam/session/lock';
  static const String mcqQuestions = '/exam/mcq/questions';
  static const String mcqAnswer = '/exam/mcq/answer';
  static const String writtenImages = '/exam/written/images';
  static const String writtenSubmit = '/exam/written/submit';
  static const String examSubmit = '/exam/submit';
  static const String examAutoSubmit = '/exam/auto-submit';
  static const String securityViolations = '/security/violations';
}
