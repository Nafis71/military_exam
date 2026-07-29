import 'dart:io';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../written_exam/domain/repositories/written_exam_repository.dart';
import '../repositories/exam_repository.dart';

class UploadPendingWrittenImagesUseCase {
  UploadPendingWrittenImagesUseCase(
    this._examRepository,
    this._writtenExamRepository,
    this._examRunContext,
  );

  final ExamRepository _examRepository;
  final WrittenExamRepository _writtenExamRepository;
  final ExamRunContext _examRunContext;

  Future<Result<void>> call() async {
    if (_examRunContext.isOnboardingDemo) {
      return const Success(null);
    }

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

          final uploaded =
              (uploadResult as Success<WrittenImageUploadResult>).data;
          final markResult = await _writtenExamRepository.markImageUploaded(
            localId: image.localId,
            remoteId: uploaded.answerId,
          );
          if (markResult is ErrorResult<void>) {
            return ErrorResult(markResult.failure);
          }

          final draftResult =
              await _examRepository.saveDescriptiveDraft(image.questionId);
          if (draftResult is ErrorResult<void>) {
            return ErrorResult(draftResult.failure);
          }
        }
        return const Success(null);
    }
  }
}
