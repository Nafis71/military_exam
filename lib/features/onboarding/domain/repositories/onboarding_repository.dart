import '../../../../core/utils/result.dart';
import '../../domain/entities/onboarding_candidate.dart';
import '../../domain/entities/onboarding_state.dart';

abstract class OnboardingRepository {
  Future<Result<OnboardingState>> getState();

  Future<Result<void>> saveCandidate(OnboardingCandidate candidate);

  Future<Result<void>> setHasSeenDemoDialog(bool value);

  Future<Result<void>> setHasCompletedDemo(bool value);

  Future<Result<void>> setHasSeenCongratulationsDialog(bool value);

  Future<Result<void>> setDeviceBound(bool value);

  Future<Result<void>> clearAll();
}
