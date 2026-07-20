import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../ports/pending_exam_answers_flusher.dart';
import '../repositories/exam_repository.dart';
import 'clear_exam_local_data_usecase.dart';
import 'finalize_exam_usecase.dart';
import 'upload_pending_written_images_usecase.dart';

class SubmitSavedExamAnswersUseCase {
  SubmitSavedExamAnswersUseCase(
    this._pendingAnswersFlusher,
    this._examRepository,
    this._uploadPendingWrittenImagesUseCase,
    this._finalizeExamUseCase,
    this._clearExamLocalDataUseCase,
  );

  final PendingExamAnswersFlusher _pendingAnswersFlusher;
  final ExamRepository _examRepository;
  final UploadPendingWrittenImagesUseCase _uploadPendingWrittenImagesUseCase;
  final FinalizeExamUseCase _finalizeExamUseCase;
  final ClearExamLocalDataUseCase _clearExamLocalDataUseCase;

  Future<Result<SubmissionReceipt>> call(ExamPhase phase) async {
    await _pendingAnswersFlusher.flush(phase);

    final uploadResult = await _uploadPendingWrittenImagesUseCase();
    if (uploadResult is ErrorResult<void>) {
      return ErrorResult(uploadResult.failure);
    }

    final examResult = await _examRepository.refreshCurrentExam();
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
