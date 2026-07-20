import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/exam_repository.dart';

class GetCurrentExamUseCase {
  GetCurrentExamUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<CurrentExam>> call({bool refresh = false}) {
    if (refresh) {
      return _examRepository.refreshCurrentExam();
    }
    return _examRepository.getCurrentExam();
  }
}
