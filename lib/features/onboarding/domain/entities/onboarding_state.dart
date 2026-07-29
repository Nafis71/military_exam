import 'package:equatable/equatable.dart';

import 'onboarding_candidate.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    required this.isLoggedIn,
    this.candidate,
    this.hasCompletedDemo = false,
    this.hasSeenDemoDialog = false,
    this.hasSeenCongratulationsDialog = false,
    this.hasSeenDashboardTutorial = false,
    this.isDeviceBound = false,
  });

  final bool isLoggedIn;
  final OnboardingCandidate? candidate;
  final bool hasCompletedDemo;
  final bool hasSeenDemoDialog;
  final bool hasSeenCongratulationsDialog;
  final bool hasSeenDashboardTutorial;
  final bool isDeviceBound;

  OnboardingState copyWith({
    bool? isLoggedIn,
    OnboardingCandidate? candidate,
    bool? hasCompletedDemo,
    bool? hasSeenDemoDialog,
    bool? hasSeenCongratulationsDialog,
    bool? hasSeenDashboardTutorial,
    bool? isDeviceBound,
  }) {
    return OnboardingState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      candidate: candidate ?? this.candidate,
      hasCompletedDemo: hasCompletedDemo ?? this.hasCompletedDemo,
      hasSeenDemoDialog: hasSeenDemoDialog ?? this.hasSeenDemoDialog,
      hasSeenCongratulationsDialog:
          hasSeenCongratulationsDialog ?? this.hasSeenCongratulationsDialog,
      hasSeenDashboardTutorial:
          hasSeenDashboardTutorial ?? this.hasSeenDashboardTutorial,
      isDeviceBound: isDeviceBound ?? this.isDeviceBound,
    );
  }

  @override
  List<Object?> get props => [
        isLoggedIn,
        candidate,
        hasCompletedDemo,
        hasSeenDemoDialog,
        hasSeenCongratulationsDialog,
        hasSeenDashboardTutorial,
        isDeviceBound,
      ];
}
