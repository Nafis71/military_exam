import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/exam_repository.dart';

class StartExamSessionUseCase {
  StartExamSessionUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<ExamSession>> call(String authSessionId) =>
      _examRepository.startSession(authSessionId);
}
