import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

abstract class SessionLocalDataSource {
  Future<Result<AuthSession?>> readSession();

  Future<Result<void>> writeSession(AuthSession session);

  Future<Result<void>> deleteSession();
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  SessionLocalDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<Result<AuthSession?>> readSession() async {
    try {
      final token = await _storage.read(key: StorageKeys.authToken);
      final sessionId = await _storage.read(key: StorageKeys.sessionId);
      final examineeId = await _storage.read(key: StorageKeys.examineeId);
      final examineeName = await _storage.read(key: 'examinee_name');
      final expiresAtRaw = await _storage.read(key: 'session_expires_at');

      if (token == null || sessionId == null || examineeId == null) {
        return const Success(null);
      }

      return Success(
        AuthSession(
          token: token,
          sessionId: sessionId,
          examinee: Examinee(
            id: examineeId,
            name: examineeName ?? examineeId,
          ),
          expiresAt: expiresAtRaw != null
              ? DateTime.parse(expiresAtRaw)
              : DateTime.now().add(const Duration(hours: 4)),
        ),
      );
    } catch (error) {
      return ErrorResult(UnexpectedFailure('Failed to read session: $error'));
    }
  }

  @override
  Future<Result<void>> writeSession(AuthSession session) async {
    try {
      await _storage.write(key: StorageKeys.authToken, value: session.token);
      await _storage.write(
        key: StorageKeys.sessionId,
        value: session.sessionId,
      );
      await _storage.write(
        key: StorageKeys.examineeId,
        value: session.examinee.id,
      );
      await _storage.write(
        key: 'examinee_name',
        value: session.examinee.name,
      );
      await _storage.write(
        key: 'session_expires_at',
        value: session.expiresAt.toIso8601String(),
      );
      await _storage.write(
        key: 'session_snapshot',
        value: jsonEncode({
          'token': session.token,
          'session_id': session.sessionId,
          'examinee_id': session.examinee.id,
          'examinee_name': session.examinee.name,
          'expires_at': session.expiresAt.toIso8601String(),
        }),
      );
      return const Success(null);
    } catch (error) {
      return ErrorResult(UnexpectedFailure('Failed to save session: $error'));
    }
  }

  @override
  Future<Result<void>> deleteSession() async {
    try {
      await _storage.delete(key: StorageKeys.authToken);
      await _storage.delete(key: StorageKeys.sessionId);
      await _storage.delete(key: StorageKeys.examineeId);
      await _storage.delete(key: 'examinee_name');
      await _storage.delete(key: 'session_expires_at');
      await _storage.delete(key: 'session_snapshot');
      return const Success(null);
    } catch (error) {
      return ErrorResult(UnexpectedFailure('Failed to clear session: $error'));
    }
  }
}
