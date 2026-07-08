import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/exam_repository.dart';

class LockExamSessionUseCase {
  LockExamSessionUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<ExamLockState>> call(String sessionId, String reason) =>
      _examRepository.lockSession(sessionId, reason);
}
