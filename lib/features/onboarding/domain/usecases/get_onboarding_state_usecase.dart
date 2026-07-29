import '../../../../core/utils/result.dart';
import '../../domain/entities/onboarding_state.dart';
import '../../domain/repositories/onboarding_repository.dart';

class GetOnboardingStateUseCase {
  const GetOnboardingStateUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Result<OnboardingState>> call() => _repository.getState();
}
