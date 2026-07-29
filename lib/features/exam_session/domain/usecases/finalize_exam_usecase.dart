import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../written_exam/domain/repositories/written_exam_repository.dart';
import '../repositories/exam_repository.dart';

class FinalizeExamUseCase {
  FinalizeExamUseCase(
    this._examRepository,
    this._writtenExamRepository,
  );

  final ExamRepository _examRepository;
  final WrittenExamRepository _writtenExamRepository;

  Future<Result<SubmissionReceipt>> call(CurrentExam? currentExam) async {
    final imagesResult = await _writtenExamRepository.getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    final questionIdsWithImages = (imagesResult.dataOrNull ?? [])
        .map((image) => image.questionId)
        .toSet();

    return _examRepository.finalizeExam(
      currentExam,
      questionIdsWithImages: questionIdsWithImages,
    );
  }
}
