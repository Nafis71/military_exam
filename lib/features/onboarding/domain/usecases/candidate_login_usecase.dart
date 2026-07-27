import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/onboarding_candidate.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../data/constants/mock_candidate_data.dart';

class CandidateLoginUseCase {
  const CandidateLoginUseCase(this._repository);

  final OnboardingRepository _repository;

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
    return Success(candidate);
  }
}
