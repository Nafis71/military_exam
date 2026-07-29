import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/onboarding_candidate.dart';
import '../../domain/entities/onboarding_state.dart';
import 'candidate_secure_datasource.dart';
import 'onboarding_prefs_local_datasource.dart';

abstract class OnboardingLocalDataSource {
  Future<Result<OnboardingState>> readState();

  Future<Result<void>> writeState(OnboardingState state);

  Future<Result<void>> clearAll();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  OnboardingLocalDataSourceImpl(this._candidateSecure, this._prefs);

  final CandidateSecureDataSource _candidateSecure;
  final OnboardingPrefsLocalDataSource _prefs;

  @override
  Future<Result<OnboardingState>> readState() async {
    try {
      final isLoggedInResult = await _prefs.readIsLoggedIn();
      if (isLoggedInResult is ErrorResult<bool>) {
        return ErrorResult(isLoggedInResult.failure);
      }

      final candidateResult = await _candidateSecure.readCandidate();
      if (candidateResult is ErrorResult<OnboardingCandidate?>) {
        return ErrorResult(candidateResult.failure);
      }

      final hasCompletedDemoResult = await _prefs.readHasCompletedDemo();
      if (hasCompletedDemoResult is ErrorResult<bool>) {
        return ErrorResult(hasCompletedDemoResult.failure);
      }

      final hasSeenDemoDialogResult = await _prefs.readHasSeenDemoDialog();
      if (hasSeenDemoDialogResult is ErrorResult<bool>) {
        return ErrorResult(hasSeenDemoDialogResult.failure);
      }

      final hasSeenCongratulationsResult =
          await _prefs.readHasSeenCongratulationsDialog();
      if (hasSeenCongratulationsResult is ErrorResult<bool>) {
        return ErrorResult(hasSeenCongratulationsResult.failure);
      }

      final hasSeenDashboardTutorialResult =
          await _prefs.readHasSeenDashboardTutorial();
      if (hasSeenDashboardTutorialResult is ErrorResult<bool>) {
        return ErrorResult(hasSeenDashboardTutorialResult.failure);
      }

      final isDeviceBoundResult = await _candidateSecure.readIsDeviceBound();
      if (isDeviceBoundResult is ErrorResult<bool>) {
        return ErrorResult(isDeviceBoundResult.failure);
      }

      return Success(
        OnboardingState(
          isLoggedIn: isLoggedInResult.dataOrNull ?? false,
          candidate: candidateResult.dataOrNull,
          hasCompletedDemo: hasCompletedDemoResult.dataOrNull ?? false,
          hasSeenDemoDialog: hasSeenDemoDialogResult.dataOrNull ?? false,
          hasSeenCongratulationsDialog:
              hasSeenCongratulationsResult.dataOrNull ?? false,
          hasSeenDashboardTutorial:
              hasSeenDashboardTutorialResult.dataOrNull ?? false,
          isDeviceBound: isDeviceBoundResult.dataOrNull ?? false,
        ),
      );
    } catch (error) {
      return ErrorResult(UnexpectedFailure('Failed to read onboarding: $error'));
    }
  }

  @override
  Future<Result<void>> writeState(OnboardingState state) async {
    try {
      final isLoggedInResult =
          await _prefs.writeIsLoggedIn(state.isLoggedIn);
      if (isLoggedInResult is ErrorResult<void>) {
        return ErrorResult(isLoggedInResult.failure);
      }

      final candidateResult =
          await _candidateSecure.writeCandidate(state.candidate);
      if (candidateResult is ErrorResult<void>) {
        return ErrorResult(candidateResult.failure);
      }

      final hasCompletedDemoResult =
          await _prefs.writeHasCompletedDemo(state.hasCompletedDemo);
      if (hasCompletedDemoResult is ErrorResult<void>) {
        return ErrorResult(hasCompletedDemoResult.failure);
      }

      final hasSeenDemoDialogResult =
          await _prefs.writeHasSeenDemoDialog(state.hasSeenDemoDialog);
      if (hasSeenDemoDialogResult is ErrorResult<void>) {
        return ErrorResult(hasSeenDemoDialogResult.failure);
      }

      final hasSeenCongratulationsResult = await _prefs
          .writeHasSeenCongratulationsDialog(state.hasSeenCongratulationsDialog);
      if (hasSeenCongratulationsResult is ErrorResult<void>) {
        return ErrorResult(hasSeenCongratulationsResult.failure);
      }

      final hasSeenDashboardTutorialResult = await _prefs
          .writeHasSeenDashboardTutorial(state.hasSeenDashboardTutorial);
      if (hasSeenDashboardTutorialResult is ErrorResult<void>) {
        return ErrorResult(hasSeenDashboardTutorialResult.failure);
      }

      final isDeviceBoundResult =
          await _candidateSecure.writeIsDeviceBound(state.isDeviceBound);
      if (isDeviceBoundResult is ErrorResult<void>) {
        return ErrorResult(isDeviceBoundResult.failure);
      }

      return const Success(null);
    } catch (error) {
      return ErrorResult(UnexpectedFailure('Failed to write onboarding: $error'));
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    final clearCandidateResult = await _candidateSecure.clearCandidateData();
    if (clearCandidateResult is ErrorResult<void>) {
      return ErrorResult(clearCandidateResult.failure);
    }
    return _prefs.clearAll();
  }
}
