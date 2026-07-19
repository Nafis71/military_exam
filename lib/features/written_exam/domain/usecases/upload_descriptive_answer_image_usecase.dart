import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../exam_session/domain/repositories/exam_repository.dart';

class UploadDescriptiveAnswerImageUseCase {
  UploadDescriptiveAnswerImageUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<WrittenImageUploadResult>> call({
    required String questionId,
    required String filePath,
    void Function(int sent, int total)? onSendProgress,
  }) =>
      _examRepository.uploadDescriptiveAnswerImage(
        questionId: questionId,
        filePath: filePath,
        onSendProgress: onSendProgress,
      );
}
