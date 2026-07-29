import '../../../../core/utils/result.dart';
import '../../domain/repositories/onboarding_repository.dart';

class SetOnboardingFlagUseCase {
  const SetOnboardingFlagUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<void>> setHasSeenDemoDialog(bool value) =>
      _repository.setHasSeenDemoDialog(value);

  Future<Result<void>> setHasCompletedDemo(bool value) =>
      _repository.setHasCompletedDemo(value);

  Future<Result<void>> setHasSeenCongratulationsDialog(bool value) =>
      _repository.setHasSeenCongratulationsDialog(value);

  Future<Result<void>> setHasSeenDashboardTutorial(bool value) =>
      _repository.setHasSeenDashboardTutorial(value);
}
