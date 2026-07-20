import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

abstract class ExamRepository {
  Future<Result<ExamSession>> startSession(String authSessionId);

  Future<Result<ExamSession?>> getCurrentSession();

  Future<Result<CurrentExam>> getCurrentExam();

  Future<Result<CurrentExam>> refreshCurrentExam();

  Future<Result<bool>> hasCachedExamAnswers();

  Future<Result<ExamTimer>> getTimer(String sessionId);

  Future<Result<List<McqQuestion>>> getMcqQuestions(String sessionId);

  Future<Result<List<FillBlankQuestion>>> getFillBlankQuestions(String sessionId);

  Future<Result<McqAnswer>> saveMcqAnswerLocally(McqAnswer answer);

  Future<Result<FillBlankAnswer>> saveFillBlankAnswerLocally(
    FillBlankAnswer answer,
  );

  Future<Result<void>> saveDescriptiveDraft(String questionId);

  Future<Result<Map<String, String>>> getMcqProgress(String sessionId);

  Future<Result<Map<String, String>>> getFillBlankProgress(String sessionId);

  Future<Result<void>> saveRollNumber(String rollNumber);

  Future<Result<String?>> getRollNumber();

  Future<Result<Map<String, ExamAnswerDraft>>> getAnswerDrafts();

  Future<Result<SubmissionReceipt>> finalizeExam(CurrentExam? currentExam);

  Future<Result<WrittenImageUploadResult>> uploadDescriptiveAnswerImage({
    required String questionId,
    required String filePath,
    void Function(int sent, int total)? onSendProgress,
  });

  Future<Result<void>> clearLocalExamData();

  Future<Result<SubmissionReceipt>> autoSubmit(String sessionId);

  Future<Result<SubmissionReceipt>> finishExam(String sessionId);

  Future<Result<ExamLockState>> lockSession(String sessionId, String reason);

  Future<Result<void>> reportViolation(SecurityViolation violation);
}
