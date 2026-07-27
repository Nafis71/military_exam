import '../../../../core/utils/result.dart';
import '../../../onboarding/domain/entities/onboarding_candidate.dart';
import '../../../onboarding/domain/repositories/onboarding_repository.dart';
import '../../domain/repositories/candidate_profile_repository.dart';

class CandidateProfileRepositoryImpl implements CandidateProfileRepository {
  CandidateProfileRepositoryImpl(this._onboardingRepository);

  final OnboardingRepository _onboardingRepository;

  @override
  Future<Result<OnboardingCandidate?>> getProfile() async {
    final stateResult = await _onboardingRepository.getState();
    return switch (stateResult) {
      Success(:final data) => Success(data.candidate),
      ErrorResult(:final failure) => ErrorResult(failure),
    };
  }
}
