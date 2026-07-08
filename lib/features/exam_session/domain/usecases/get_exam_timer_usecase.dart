import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/exam_repository.dart';

class GetExamTimerUseCase {
  GetExamTimerUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<ExamTimer>> call(String sessionId) =>
      _examRepository.getTimer(sessionId);
}
