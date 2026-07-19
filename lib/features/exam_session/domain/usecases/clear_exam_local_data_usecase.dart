import '../../../../core/utils/result.dart';
import '../repositories/exam_repository.dart';

class ClearExamLocalDataUseCase {
  ClearExamLocalDataUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<void>> call() => _examRepository.clearLocalExamData();
}
