import 'package:get/get.dart';

import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../domain/constants/written_exam_demo_questions.dart';
import '../../domain/usecases/add_written_image_usecase.dart';
import '../../domain/usecases/delete_written_image_usecase.dart';
import '../../domain/usecases/replace_written_image_usecase.dart';
import '../../domain/usecases/submit_written_exam_usecase.dart';
import '../../domain/usecases/upload_written_image_usecase.dart';

class WrittenExamController extends GetxController {
  WrittenExamController({
    required AddWrittenImageUseCase addWrittenImageUseCase,
    required ReplaceWrittenImageUseCase replaceWrittenImageUseCase,
    required DeleteWrittenImageUseCase deleteWrittenImageUseCase,
    required UploadWrittenImageUseCase uploadWrittenImageUseCase,
    required SubmitWrittenExamUseCase submitWrittenExamUseCase,
  })  : _addWrittenImageUseCase = addWrittenImageUseCase,
        _replaceWrittenImageUseCase = replaceWrittenImageUseCase,
        _deleteWrittenImageUseCase = deleteWrittenImageUseCase,
        _uploadWrittenImageUseCase = uploadWrittenImageUseCase,
        _submitWrittenExamUseCase = submitWrittenExamUseCase;

  final AddWrittenImageUseCase _addWrittenImageUseCase;
  final ReplaceWrittenImageUseCase _replaceWrittenImageUseCase;
  final DeleteWrittenImageUseCase _deleteWrittenImageUseCase;
  final UploadWrittenImageUseCase _uploadWrittenImageUseCase;
  final SubmitWrittenExamUseCase _submitWrittenExamUseCase;

  final images = <WrittenAnswerImage>[].obs;
  final submissionStatus = SubmissionStatus.idle.obs;
  final submissionReceipt = Rxn<SubmissionReceipt>();
  final errorMessage = RxnString();

  List<WrittenQuestion> get questions => WrittenExamDemoQuestions.all;

  bool get hasAnyImages => images.isNotEmpty;

  bool get canSubmit =>
      questions.every((q) => imagesForQuestion(q.id).isNotEmpty);

  List<WrittenAnswerImage> imagesForQuestion(String questionId) =>
      images.where((img) => img.questionId == questionId).toList();

  Future<void> addImage(String questionId, String localPath) async {
    final result = await _addWrittenImageUseCase(localPath, questionId);
    _handleImageResult(result);
  }

  Future<void> replaceImage(String localId, String newLocalPath) async {
    final result = await _replaceWrittenImageUseCase(localId, newLocalPath);
    _handleImageResult(result);
  }

  Future<void> deleteImage(String localId) async {
    final result = await _deleteWrittenImageUseCase(localId);
    if (result is Success<void>) {
      images.removeWhere((img) => img.localId == localId);
    } else if (result is ErrorResult<void>) {
      errorMessage.value = result.failure.message;
    }
  }

  Future<void> uploadImage(String localId) async {
    final result = await _uploadWrittenImageUseCase(localId);
    switch (result) {
      case Success(:final data):
        final index = images.indexWhere((img) => img.localId == localId);
        if (index >= 0) {
          images[index] = images[index].copyWith(
            uploadStatus: data.status,
            uploadProgress: data.progress,
          );
        }
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  Future<void> submitExam(String sessionId) async {
    submissionStatus.value = SubmissionStatus.saving;
    errorMessage.value = null;

    for (final image in images) {
      if (image.uploadStatus != ImageUploadStatus.uploaded) {
        await uploadImage(image.localId);
      }
    }

    final result = await _submitWrittenExamUseCase(sessionId);
    switch (result) {
      case Success(:final data):
        submissionReceipt.value = data;
        submissionStatus.value = SubmissionStatus.submitted;
      case ErrorResult(:final failure):
        submissionStatus.value = SubmissionStatus.failed;
        errorMessage.value = failure.message;
    }
  }

  void _handleImageResult(Result<WrittenAnswerImage> result) {
    switch (result) {
      case Success(:final data):
        final index = images.indexWhere((img) => img.localId == data.localId);
        if (index >= 0) {
          images[index] = data;
        } else {
          images.add(data);
        }
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }
}
