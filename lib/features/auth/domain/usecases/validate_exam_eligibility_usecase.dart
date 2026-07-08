import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/auth_repository.dart';

class ValidateExamEligibilityUseCase {
  ValidateExamEligibilityUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<ExamEligibility>> call(String sessionId) =>
      _authRepository.validateExamEligibility(sessionId);
}
