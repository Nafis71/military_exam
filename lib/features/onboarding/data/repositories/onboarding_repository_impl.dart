import '../../../../core/utils/result.dart';
import '../../domain/entities/onboarding_candidate.dart';
import '../../domain/entities/onboarding_state.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._local);

  final OnboardingLocalDataSource _local;

  @override
  Future<Result<OnboardingState>> getState() => _local.readState();

  @override
  Future<Result<void>> saveCandidate(OnboardingCandidate candidate) async {
    final current = await _local.readState();
    if (current is ErrorResult<OnboardingState>) {
      return ErrorResult(current.failure);
    }
    final state = (current as Success<OnboardingState>).data;
    return _local.writeState(
      state.copyWith(
        isLoggedIn: true,
        candidate: candidate,
        isDeviceBound: true,
      ),
    );
  }

  @override
  Future<Result<void>> setHasSeenDemoDialog(bool value) =>
      _updateFlag((s) => s.copyWith(hasSeenDemoDialog: value));

  @override
  Future<Result<void>> setHasCompletedDemo(bool value) =>
      _updateFlag((s) => s.copyWith(hasCompletedDemo: value));

  @override
  Future<Result<void>> setHasSeenCongratulationsDialog(bool value) =>
      _updateFlag((s) => s.copyWith(hasSeenCongratulationsDialog: value));

  @override
  Future<Result<void>> setHasSeenDashboardTutorial(bool value) =>
      _updateFlag((s) => s.copyWith(hasSeenDashboardTutorial: value));

  @override
  Future<Result<void>> setDeviceBound(bool value) =>
      _updateFlag((s) => s.copyWith(isDeviceBound: value));

  @override
  Future<Result<void>> clearAll() async {
    // TODO: notify server unbind
    return _local.clearAll();
  }

  Future<Result<void>> _updateFlag(
    OnboardingState Function(OnboardingState) update,
  ) async {
    final current = await _local.readState();
    if (current is ErrorResult<OnboardingState>) {
      return ErrorResult(current.failure);
    }
    return _local.writeState(update((current as Success<OnboardingState>).data));
  }
}
