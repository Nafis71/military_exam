import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/onboarding_candidate.dart';
import '../models/onboarding_candidate_model.dart';

/// Persists candidate profile fields used on the dashboard profile card.
abstract class CandidateSecureDataSource {
  Future<Result<OnboardingCandidate?>> readCandidate();

  Future<Result<void>> writeCandidate(OnboardingCandidate? candidate);

  Future<Result<bool>> readIsDeviceBound();

  Future<Result<void>> writeIsDeviceBound(bool value);

  Future<Result<void>> clearCandidateData();
}

class CandidateSecureDataSourceImpl implements CandidateSecureDataSource {
  CandidateSecureDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<Result<OnboardingCandidate?>> readCandidate() async {
    try {
      final candidateRaw = await _storage.read(key: StorageKeys.candidate);
      if (candidateRaw == null) return const Success(null);
      return Success(
        OnboardingCandidateModel.fromJson(
          jsonDecode(candidateRaw) as Map<String, dynamic>,
        ),
      );
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to read candidate profile: $error'),
      );
    }
  }

  @override
  Future<Result<void>> writeCandidate(OnboardingCandidate? candidate) async {
    try {
      if (candidate == null) {
        await _storage.delete(key: StorageKeys.candidate);
        return const Success(null);
      }
      await _storage.write(
        key: StorageKeys.candidate,
        value: jsonEncode(
          OnboardingCandidateModel.fromEntity(candidate).toJson(),
        ),
      );
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to write candidate profile: $error'),
      );
    }
  }

  @override
  Future<Result<bool>> readIsDeviceBound() async {
    try {
      final raw = await _storage.read(key: StorageKeys.isDeviceBound);
      return Success(raw == 'true');
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to read device binding state: $error'),
      );
    }
  }

  @override
  Future<Result<void>> writeIsDeviceBound(bool value) async {
    try {
      await _storage.write(
        key: StorageKeys.isDeviceBound,
        value: value.toString(),
      );
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to write device binding state: $error'),
      );
    }
  }

  @override
  Future<Result<void>> clearCandidateData() async {
    try {
      await _storage.delete(key: StorageKeys.candidate);
      await _storage.delete(key: StorageKeys.isDeviceBound);
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        UnexpectedFailure('Failed to clear candidate profile: $error'),
      );
    }
  }
}
