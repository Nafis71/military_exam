import 'package:equatable/equatable.dart';

class OnboardingCandidate extends Equatable {
  const OnboardingCandidate({
    required this.candidateId,
    required this.fullName,
    required this.phoneNumber,
    required this.emailAddress,
    this.profileImageUrl,
  });

  final String candidateId;
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final String? profileImageUrl;

  @override
  List<Object?> get props => [
        candidateId,
        fullName,
        phoneNumber,
        emailAddress,
        profileImageUrl,
      ];
}
