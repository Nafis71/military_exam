import '../../../../core/utils/result.dart';
import '../../../written_exam/domain/repositories/written_exam_repository.dart';
import '../repositories/exam_repository.dart';

class HasCachedExamAnswersUseCase {
  HasCachedExamAnswersUseCase(
    this._examRepository,
    this._writtenExamRepository,
  );

  final ExamRepository _examRepository;
  final WrittenExamRepository _writtenExamRepository;

  Future<Result<bool>> call() async {
    final examCacheResult = await _examRepository.hasCachedExamAnswers();
    if (examCacheResult is ErrorResult<bool>) {
      return ErrorResult(examCacheResult.failure);
    }
    if (examCacheResult.dataOrNull == true) {
      return const Success(true);
    }

    final imagesResult = await _writtenExamRepository.getImages();
    switch (imagesResult) {
      case ErrorResult(:final failure):
        return ErrorResult(failure);
      case Success(:final data):
        return Success(data.isNotEmpty);
    }
  }
}
