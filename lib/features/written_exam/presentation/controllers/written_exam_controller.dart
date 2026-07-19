import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../../domain/usecases/add_written_image_usecase.dart';
import '../../domain/usecases/delete_written_image_usecase.dart';
import '../../domain/usecases/get_written_images_usecase.dart';
import '../../domain/usecases/save_descriptive_draft_usecase.dart';
import '../../domain/usecases/upload_descriptive_answer_image_usecase.dart';

class WrittenExamController extends GetxController {
  WrittenExamController({
    required ExamSessionController sessionController,
    required AddWrittenImageUseCase addWrittenImageUseCase,
    required DeleteWrittenImageUseCase deleteWrittenImageUseCase,
    required GetWrittenImagesUseCase getWrittenImagesUseCase,
    required UploadDescriptiveAnswerImageUseCase uploadDescriptiveAnswerImageUseCase,
    required SaveDescriptiveDraftUseCase saveDescriptiveDraftUseCase,
  })  : _sessionController = sessionController,
        _addWrittenImageUseCase = addWrittenImageUseCase,
        _deleteWrittenImageUseCase = deleteWrittenImageUseCase,
        _getWrittenImagesUseCase = getWrittenImagesUseCase,
        _uploadDescriptiveAnswerImageUseCase =
            uploadDescriptiveAnswerImageUseCase,
        _saveDescriptiveDraftUseCase = saveDescriptiveDraftUseCase;

  final ExamSessionController _sessionController;
  final AddWrittenImageUseCase _addWrittenImageUseCase;
  final DeleteWrittenImageUseCase _deleteWrittenImageUseCase;
  final GetWrittenImagesUseCase _getWrittenImagesUseCase;
  final UploadDescriptiveAnswerImageUseCase _uploadDescriptiveAnswerImageUseCase;
  final SaveDescriptiveDraftUseCase _saveDescriptiveDraftUseCase;

  final images = <WrittenAnswerImage>[].obs;
  final currentIndex = 0.obs;
  final submissionStatus = SubmissionStatus.idle.obs;
  final uploadProgress = 0.0.obs;
  final isUploading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadPersistedImages());
  }

  bool get hasAnyImages => images.isNotEmpty;

  List<WrittenQuestion> get questions =>
      _sessionController.descriptiveQuestions;

  WrittenQuestion? get currentQuestion {
    if (questions.isEmpty || currentIndex.value >= questions.length) {
      return null;
    }
    return questions[currentIndex.value];
  }

  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex.value >= questions.length - 1;

  bool get canSubmit =>
      questions.isNotEmpty &&
      questions.every((q) => _hasUploadedImage(q.id));

  bool get currentQuestionHasUploadedImage {
    final question = currentQuestion;
    if (question == null) return false;
    return _hasUploadedImage(question.id);
  }

  List<WrittenAnswerImage> imagesForQuestion(String questionId) =>
      images.where((img) => img.questionId == questionId).toList();

  bool _hasUploadedImage(String questionId) {
    final questionImages = imagesForQuestion(questionId);
    return questionImages.any(
      (img) => img.uploadStatus == ImageUploadStatus.uploaded,
    );
  }

  Future<void> stageLocalImage(String questionId, String localPath) async {
    final result = await _addWrittenImageUseCase(localPath, questionId);
    _handleImageResult(result);
  }

  Future<bool> uploadStagedImage({
    required String questionId,
    required String localPath,
  }) async {
    isUploading.value = true;
    uploadProgress.value = 0;
    errorMessage.value = null;

    final result = await _uploadDescriptiveAnswerImageUseCase(
      questionId: questionId,
      filePath: localPath,
      onSendProgress: (sent, total) {
        if (total > 0) {
          uploadProgress.value = sent / total;
        }
      },
    );

    isUploading.value = false;

    switch (result) {
      case Success(:final data):
        final index = images.indexWhere(
          (img) => img.questionId == questionId && img.localPath == localPath,
        );
        if (index >= 0) {
          images[index] = images[index].copyWith(
            remoteId: data.answerId,
            uploadStatus: ImageUploadStatus.uploaded,
            uploadProgress: 1,
          );
        }
        await _saveDescriptiveDraftUseCase(questionId);
        uploadProgress.value = 1;
        return true;
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
        return false;
    }
  }

  Future<void> removeLocalImage(String localId) async {
    await _deleteWrittenImageUseCase(localId);
    images.removeWhere((img) => img.localId == localId);
  }

  Future<void> _loadPersistedImages() async {
    final result = await _getWrittenImagesUseCase();
    switch (result) {
      case Success(:final data):
        images.assignAll(data);
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  Future<void> flushPendingAnswer() async {
    final question = currentQuestion;
    if (question == null || !currentQuestionHasUploadedImage) return;
    await _saveDescriptiveDraftUseCase(question.id);
  }

  Future<void> goToNext() async {
    final question = currentQuestion;
    if (question == null) return;
    if (!currentQuestionHasUploadedImage) {
      errorMessage.value = AppStrings.writtenExamRequireUploadedImage;
      return;
    }
    await _saveDescriptiveDraftUseCase(question.id);
    if (!isLastQuestion) {
      currentIndex.value += 1;
      errorMessage.value = null;
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
        errorMessage.value = null;
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }
}
