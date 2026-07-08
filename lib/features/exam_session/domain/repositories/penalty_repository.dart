import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

abstract class PenaltyRepository {
  Future<Result<PenaltyDecision>> evaluateViolation(SecurityViolation violation);

  Future<Result<ExamLockState>> getLockState(String sessionId);

  Future<Result<void>> persistLockState(ExamLockState state);
}
