import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../exam_session/domain/usecases/save_roll_number_usecase.dart';
import '../../domain/entities/onboarding_candidate.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../data/constants/mock_candidate_data.dart';

class CandidateLoginUseCase {
  const CandidateLoginUseCase(
    this._repository,
    this._saveRollNumberUseCase,
  );

  final OnboardingRepository _repository;
  final SaveRollNumberUseCase _saveRollNumberUseCase;

  Future<Result<OnboardingCandidate>> call(String candidateId) async {
    final trimmed = candidateId.trim();
    if (trimmed.isEmpty) {
      return const ErrorResult(ValidationFailure(''));
    }
    final candidate = MockCandidateData.buildForId(trimmed);
    final saveResult = await _repository.saveCandidate(candidate);
    if (saveResult is ErrorResult<void>) {
      return ErrorResult(saveResult.failure);
    }

    final rollResult = await _saveRollNumberUseCase(trimmed);
    if (rollResult is ErrorResult<void>) {
      return ErrorResult(rollResult.failure);
    }

    return Success(candidate);
  }
}
