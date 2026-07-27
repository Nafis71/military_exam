import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/onboarding_state.dart';
import '../models/onboarding_candidate_model.dart';

abstract class OnboardingLocalDataSource {
  Future<Result<OnboardingState>> readState();

  Future<Result<void>> writeState(OnboardingState state);

  Future<Result<void>> clearAll();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  OnboardingLocalDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<Result<OnboardingState>> readState() async {
    try {
      final isLoggedInRaw = await _storage.read(key: StorageKeys.isLoggedIn);
      final candidateRaw = await _storage.read(key: StorageKeys.candidate);
      final hasCompletedDemoRaw =
          await _storage.read(key: StorageKeys.hasCompletedDemo);
      final hasSeenDemoDialogRaw =
          await _storage.read(key: StorageKeys.hasSeenDemoDialog);
      final hasSeenCongratulationsRaw = await _storage.read(
        key: StorageKeys.hasSeenCongratulationsDialog,
      );
      final isDeviceBoundRaw =
          await _storage.read(key: StorageKeys.isDeviceBound);

      OnboardingCandidateModel? candidate;
      if (candidateRaw != null) {
        candidate = OnboardingCandidateModel.fromJson(
          jsonDecode(candidateRaw) as Map<String, dynamic>,
        );
      }

      return Success(
        OnboardingState(
          isLoggedIn: isLoggedInRaw == 'true',
          candidate: candidate,
          hasCompletedDemo: hasCompletedDemoRaw == 'true',
          hasSeenDemoDialog: hasSeenDemoDialogRaw == 'true',
          hasSeenCongratulationsDialog: hasSeenCongratulationsRaw == 'true',
          isDeviceBound: isDeviceBoundRaw == 'true',
        ),
      );
    } catch (error) {
      return ErrorResult(UnexpectedFailure('Failed to read onboarding: $error'));
    }
  }

  @override
  Future<Result<void>> writeState(OnboardingState state) async {
    try {
      await _storage.write(
        key: StorageKeys.isLoggedIn,
        value: state.isLoggedIn.toString(),
      );
      if (state.candidate != null) {
        await _storage.write(
          key: StorageKeys.candidate,
          value: jsonEncode(
            OnboardingCandidateModel.fromEntity(state.candidate!).toJson(),
          ),
        );
      } else {
        await _storage.delete(key: StorageKeys.candidate);
      }
      await _storage.write(
        key: StorageKeys.hasCompletedDemo,
        value: state.hasCompletedDemo.toString(),
      );
      await _storage.write(
        key: StorageKeys.hasSeenDemoDialog,
        value: state.hasSeenDemoDialog.toString(),
      );
      await _storage.write(
        key: StorageKeys.hasSeenCongratulationsDialog,
        value: state.hasSeenCongratulationsDialog.toString(),
      );
      await _storage.write(
        key: StorageKeys.isDeviceBound,
        value: state.isDeviceBound.toString(),
      );
      return const Success(null);
    } catch (error) {
      return ErrorResult(UnexpectedFailure('Failed to write onboarding: $error'));
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await _storage.delete(key: StorageKeys.isLoggedIn);
      await _storage.delete(key: StorageKeys.candidate);
      await _storage.delete(key: StorageKeys.hasCompletedDemo);
      await _storage.delete(key: StorageKeys.hasSeenDemoDialog);
      await _storage.delete(key: StorageKeys.hasSeenCongratulationsDialog);
      await _storage.delete(key: StorageKeys.isDeviceBound);
      return const Success(null);
    } catch (error) {
      return ErrorResult(UnexpectedFailure('Failed to clear onboarding: $error'));
    }
  }
}
