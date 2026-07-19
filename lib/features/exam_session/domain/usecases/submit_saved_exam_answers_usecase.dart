import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../ports/pending_exam_answers_flusher.dart';
import 'clear_exam_local_data_usecase.dart';
import 'finalize_exam_usecase.dart';
import 'get_current_exam_usecase.dart';

class SubmitSavedExamAnswersUseCase {
  SubmitSavedExamAnswersUseCase(
    this._pendingAnswersFlusher,
    this._getCurrentExamUseCase,
    this._finalizeExamUseCase,
    this._clearExamLocalDataUseCase,
  );

  final PendingExamAnswersFlusher _pendingAnswersFlusher;
  final GetCurrentExamUseCase _getCurrentExamUseCase;
  final FinalizeExamUseCase _finalizeExamUseCase;
  final ClearExamLocalDataUseCase _clearExamLocalDataUseCase;

  Future<Result<SubmissionReceipt>> call(ExamPhase phase) async {
    await _pendingAnswersFlusher.flush(phase);

    final examResult = await _getCurrentExamUseCase();
    if (examResult is ErrorResult<CurrentExam>) {
      return ErrorResult(examResult.failure);
    }

    final currentExam = (examResult as Success<CurrentExam>).data;
    final finalizeResult = await _finalizeExamUseCase(currentExam);
    if (finalizeResult is ErrorResult<SubmissionReceipt>) {
      return finalizeResult;
    }

    await _clearExamLocalDataUseCase();
    return finalizeResult;
  }
}
