import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../entities/exam_submit_summary.dart';
import '../repositories/exam_repository.dart';
import '../utils/exam_duration_utils.dart';
import '../utils/finalize_payload_builder.dart';

class GetExamSubmitSummaryUseCase {
  GetExamSubmitSummaryUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<ExamSubmitSummary>> call({
    required CurrentExam exam,
    int? timerRemainingSeconds,
    DateTime? sessionStartedAt,
  }) async {
    final draftsResult = await _examRepository.getAnswerDrafts();
    if (draftsResult is ErrorResult<Map<String, ExamAnswerDraft>>) {
      return ErrorResult(draftsResult.failure);
    }

    final drafts = (draftsResult as Success<Map<String, ExamAnswerDraft>>).data;
    final answeredCount = drafts.values
        .where(FinalizePayloadBuilder.shouldIncludeDraft)
        .length;

    return Success(
      ExamSubmitSummary(
        examName: exam.examName,
        batchName: exam.batchName,
        totalDurationMinutes: exam.durationMinutes,
        elapsedSeconds: ExamDurationUtils.elapsedSeconds(
          totalDurationMinutes: exam.durationMinutes,
          examStartTime: exam.window.startTime,
          timerRemainingSeconds: timerRemainingSeconds,
          sessionStartedAt: sessionStartedAt,
          remainingExamMinutes: exam.window.remainingExamMinutes,
        ),
        totalQuestions: exam.totalQuestions,
        answeredQuestions: answeredCount,
      ),
    );
  }
}
