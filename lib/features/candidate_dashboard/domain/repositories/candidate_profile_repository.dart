import '../../../../core/utils/result.dart';
import '../../../onboarding/domain/entities/onboarding_candidate.dart';

abstract class CandidateProfileRepository {
  Future<Result<OnboardingCandidate?>> getProfile();
}
