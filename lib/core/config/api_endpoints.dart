abstract final class ApiEndpoints {
  static const String login = '/candidates/login';
  static const String districts = '/candidates/districts';
  static const String sessionCurrent = '/exam/session/current';
  static const String sessionLock = '/exam/session/lock';
  static const String currentExam = '/exams/current-exam';
  static const String examFinalize = '/exams/current-exam/finalize';
  static String examAnswerImageUpload(String questionId) =>
      '/exams/current-exam/answers/$questionId/upload';
  static const String mcqQuestions = '/exam/mcq/questions';
  static const String mcqAnswer = '/exam/mcq/answer';
  static const String writtenImages = '/exam/written/images';
  static const String writtenSubmit = '/exam/written/submit';
  static const String examSubmit = '/exam/submit';
  static const String examAutoSubmit = '/exam/auto-submit';
  static const String securityViolations = '/security/violations';
}
