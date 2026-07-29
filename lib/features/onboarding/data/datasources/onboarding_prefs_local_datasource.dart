import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';

abstract class OnboardingPrefsLocalDataSource {
  Future<Result<bool>> readIsLoggedIn();

  Future<Result<void>> writeIsLoggedIn(bool value);

  Future<Result<bool>> readHasCompletedDemo();

  Future<Result<void>> writeHasCompletedDemo(bool value);

  Future<Result<bool>> readHasSeenDemoDialog();

  Future<Result<void>> writeHasSeenDemoDialog(bool value);

  Future<Result<bool>> readHasSeenCongratulationsDialog();

  Future<Result<void>> writeHasSeenCongratulationsDialog(bool value);

  Future<Result<void>> clearAll();
}

class OnboardingPrefsHiveDataSourceImpl implements OnboardingPrefsLocalDataSource {
  OnboardingPrefsHiveDataSourceImpl(this._box);

  final Box<dynamic> _box;

  @override
  Future<Result<bool>> readIsLoggedIn() async {
    try {
      return Success(_box.get(StorageKeys.isLoggedIn) == true);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to read onboarding login state: $error'),
      );
    }
  }

  @override
  Future<Result<void>> writeIsLoggedIn(bool value) async {
    try {
      await _box.put(StorageKeys.isLoggedIn, value);
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to write onboarding login state: $error'),
      );
    }
  }

  @override
  Future<Result<bool>> readHasCompletedDemo() async {
    try {
      return Success(_box.get(StorageKeys.hasCompletedDemo) == true);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to read demo completion state: $error'),
      );
    }
  }

  @override
  Future<Result<void>> writeHasCompletedDemo(bool value) async {
    try {
      await _box.put(StorageKeys.hasCompletedDemo, value);
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to write demo completion state: $error'),
      );
    }
  }

  @override
  Future<Result<bool>> readHasSeenDemoDialog() async {
    try {
      return Success(_box.get(StorageKeys.hasSeenDemoDialog) == true);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to read demo dialog state: $error'),
      );
    }
  }

  @override
  Future<Result<void>> writeHasSeenDemoDialog(bool value) async {
    try {
      await _box.put(StorageKeys.hasSeenDemoDialog, value);
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to write demo dialog state: $error'),
      );
    }
  }

  @override
  Future<Result<bool>> readHasSeenCongratulationsDialog() async {
    try {
      return Success(
        _box.get(StorageKeys.hasSeenCongratulationsDialog) == true,
      );
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to read congratulations dialog state: $error'),
      );
    }
  }

  @override
  Future<Result<void>> writeHasSeenCongratulationsDialog(bool value) async {
    try {
      await _box.put(StorageKeys.hasSeenCongratulationsDialog, value);
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure(
          'Failed to write congratulations dialog state: $error',
        ),
      );
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await _box.clear();
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to clear onboarding preferences: $error'),
      );
    }
  }
}
