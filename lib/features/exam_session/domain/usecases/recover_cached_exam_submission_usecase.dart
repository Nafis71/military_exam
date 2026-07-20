import 'dart:io';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../written_exam/domain/repositories/written_exam_repository.dart';
import '../entities/cached_exam_recovery_result.dart';
import '../repositories/exam_repository.dart';
import 'finalize_exam_usecase.dart';

class RecoverCachedExamSubmissionUseCase {
  RecoverCachedExamSubmissionUseCase(
    this._examRepository,
    this._writtenExamRepository,
    this._finalizeExamUseCase,
  );

  final ExamRepository _examRepository;
  final WrittenExamRepository _writtenExamRepository;
  final FinalizeExamUseCase _finalizeExamUseCase;

  Future<Result<CachedExamRecoveryResult>> call() async {
    final examResult = await _examRepository.refreshCurrentExam();
    if (examResult is ErrorResult<CurrentExam>) {
      return ErrorResult(examResult.failure);
    }

    final currentExam = (examResult as Success<CurrentExam>).data;
    final uploadResult = await _uploadPendingWrittenImages();
    if (uploadResult is ErrorResult<void>) {
      return ErrorResult(uploadResult.failure);
    }

    final finalizeResult = await _finalizeExamUseCase(currentExam);
    return switch (finalizeResult) {
      Success(:final data) => Success(
          CachedExamRecoveryResult(receipt: data, exam: currentExam),
        ),
      ErrorResult(:final failure) => ErrorResult(failure),
    };
  }

  Future<Result<void>> _uploadPendingWrittenImages() async {
    final imagesResult = await _writtenExamRepository.getImages();
    switch (imagesResult) {
      case ErrorResult(:final failure):
        return ErrorResult(failure);
      case Success(:final data):
        for (final image in data) {
          if (image.uploadStatus == ImageUploadStatus.uploaded) continue;
          if (!File(image.localPath).existsSync()) {
            return const ErrorResult(
              UploadFailure(AppStrings.imageFileNotFound),
            );
          }

          final uploadResult = await _examRepository.uploadDescriptiveAnswerImage(
            questionId: image.questionId,
            filePath: image.localPath,
          );
          if (uploadResult is ErrorResult<WrittenImageUploadResult>) {
            return ErrorResult(uploadResult.failure);
          }
        }
        return const Success(null);
    }
  }
}
