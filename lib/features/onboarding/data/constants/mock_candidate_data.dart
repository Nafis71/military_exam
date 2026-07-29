import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/onboarding_candidate.dart';

abstract final class MockCandidateData {
  static OnboardingCandidate buildForId(String candidateId) {
    return OnboardingCandidate(
      candidateId: candidateId,
      fullName: '${AppStrings.mockCandidateNamePrefix} $candidateId',
      phoneNumber: AppStrings.mockCandidatePhone,
      emailAddress: AppStrings.mockCandidateEmail,
      profileImageUrl: null,
    );
  }
}
