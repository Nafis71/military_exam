import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../written_exam/domain/repositories/written_exam_repository.dart';
import '../repositories/exam_repository.dart';

class HasCachedExamAnswersUseCase {
  HasCachedExamAnswersUseCase(
    this._examRepository,
    this._writtenExamRepository,
  );

  final ExamRepository _examRepository;
  final WrittenExamRepository _writtenExamRepository;

  Future<Result<bool>> call({required String rollNumber}) async {
    final storedRollResult = await _examRepository.getRollNumber();
    if (storedRollResult is ErrorResult<String?>) {
      return ErrorResult(storedRollResult.failure);
    }

    final storedRoll = storedRollResult.dataOrNull;
    if (storedRoll != null &&
        storedRoll.isNotEmpty &&
        storedRoll != rollNumber) {
      return const Success(false);
    }

    final imagesResult = await _writtenExamRepository.getImages();
    if (imagesResult is ErrorResult<List<WrittenAnswerImage>>) {
      return ErrorResult(imagesResult.failure);
    }

    final questionIdsWithImages = (imagesResult.dataOrNull ?? [])
        .map((image) => image.questionId)
        .toSet();

    return _examRepository.hasCachedExamAnswers(
      questionIdsWithImages: questionIdsWithImages,
    );
  }
}
