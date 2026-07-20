import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../entities/cached_exam_recovery_result.dart';
import '../repositories/exam_repository.dart';
import 'clear_exam_local_data_usecase.dart';
import 'finalize_exam_usecase.dart';
import 'upload_pending_written_images_usecase.dart';

class SubmitExamWithPendingUploadsUseCase {
  SubmitExamWithPendingUploadsUseCase(
    this._examRepository,
    this._uploadPendingWrittenImagesUseCase,
    this._finalizeExamUseCase,
    this._clearExamLocalDataUseCase,
  );

  final ExamRepository _examRepository;
  final UploadPendingWrittenImagesUseCase _uploadPendingWrittenImagesUseCase;
  final FinalizeExamUseCase _finalizeExamUseCase;
  final ClearExamLocalDataUseCase _clearExamLocalDataUseCase;

  Future<Result<CachedExamRecoveryResult>> call() async {
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
      return ErrorResult(finalizeResult.failure);
    }

    await _clearExamLocalDataUseCase();
    return Success(
      CachedExamRecoveryResult(
        receipt: (finalizeResult as Success<SubmissionReceipt>).data,
        exam: currentExam,
      ),
    );
  }
}
