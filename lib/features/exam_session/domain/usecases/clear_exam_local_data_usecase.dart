import '../../../../core/utils/result.dart';
import '../../../written_exam/domain/repositories/written_exam_repository.dart';
import '../repositories/exam_repository.dart';

class ClearExamLocalDataUseCase {
  ClearExamLocalDataUseCase(
    this._examRepository,
    this._writtenExamRepository,
  );

  final ExamRepository _examRepository;
  final WrittenExamRepository _writtenExamRepository;

  Future<Result<void>> call() async {
    final clearImagesResult = await _writtenExamRepository.clearStoredImages();
    if (clearImagesResult is ErrorResult<void>) {
      return ErrorResult(clearImagesResult.failure);
    }
    return _examRepository.clearLocalExamData();
  }
}
