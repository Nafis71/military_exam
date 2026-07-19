import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

abstract class ExamRepository {
  Future<Result<ExamSession>> startSession(String authSessionId);

  Future<Result<ExamSession?>> getCurrentSession();

  Future<Result<CurrentExam>> getCurrentExam();

  Future<Result<ExamTimer>> getTimer(String sessionId);

  Future<Result<List<McqQuestion>>> getMcqQuestions(String sessionId);

  Future<Result<List<FillBlankQuestion>>> getFillBlankQuestions(String sessionId);

  Future<Result<McqAnswer>> submitMcqAnswer(McqAnswer answer);

  Future<Result<FillBlankAnswer>> saveFillBlankAnswer(FillBlankAnswer answer);

  Future<Result<Map<String, String>>> getMcqProgress(String sessionId);

  Future<Result<Map<String, String>>> getFillBlankProgress(String sessionId);

  Future<Result<SubmissionReceipt>> autoSubmit(String sessionId);

  Future<Result<SubmissionReceipt>> finishExam(String sessionId);

  Future<Result<ExamLockState>> lockSession(String sessionId, String reason);

  Future<Result<void>> reportViolation(SecurityViolation violation);
}
