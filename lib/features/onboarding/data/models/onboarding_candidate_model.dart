import '../../domain/entities/onboarding_candidate.dart';

class OnboardingCandidateModel extends OnboardingCandidate {
  const OnboardingCandidateModel({
    required super.candidateId,
    required super.fullName,
    required super.phoneNumber,
    required super.emailAddress,
    super.profileImageUrl,
  });

  factory OnboardingCandidateModel.fromJson(Map<String, dynamic> json) {
    return OnboardingCandidateModel(
      candidateId: json['candidateId'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      emailAddress: json['emailAddress'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'candidateId': candidateId,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'emailAddress': emailAddress,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      };

  factory OnboardingCandidateModel.fromEntity(OnboardingCandidate entity) {
    return OnboardingCandidateModel(
      candidateId: entity.candidateId,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      emailAddress: entity.emailAddress,
      profileImageUrl: entity.profileImageUrl,
    );
  }
}
