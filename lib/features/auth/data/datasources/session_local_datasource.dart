import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

abstract class SessionLocalDataSource {
  Future<Result<AuthSession?>> readSession();

  Future<Result<void>> writeSession(AuthSession session);

  Future<Result<void>> deleteSession();
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  SessionLocalDataSourceImpl(this._box);

  final Box<dynamic> _box;

  static const _authTokenKey = 'auth_token';
  static const _sessionIdKey = 'session_id';
  static const _examineeIdKey = 'examinee_id';
  static const _examineeNameKey = 'examinee_name';
  static const _sessionExpiresAtKey = 'session_expires_at';
  static const _sessionSnapshotKey = 'session_snapshot';

  @override
  Future<Result<AuthSession?>> readSession() async {
    try {
      final token = _box.get(_authTokenKey) as String?;
      final sessionId = _box.get(_sessionIdKey) as String?;
      final examineeId = _box.get(_examineeIdKey) as String?;
      final examineeName = _box.get(_examineeNameKey) as String?;
      final expiresAtRaw = _box.get(_sessionExpiresAtKey) as String?;

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
              ? DateTime.tryParse(expiresAtRaw) ??
                  DateTime.now().add(const Duration(hours: 4))
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
      await _box.put(_authTokenKey, session.token);
      await _box.put(_sessionIdKey, session.sessionId);
      await _box.put(_examineeIdKey, session.examinee.id);
      await _box.put(_examineeNameKey, session.examinee.name);
      await _box.put(
        _sessionExpiresAtKey,
        session.expiresAt.toIso8601String(),
      );
      await _box.put(
        _sessionSnapshotKey,
        jsonEncode({
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
      await _box.delete(_authTokenKey);
      await _box.delete(_sessionIdKey);
      await _box.delete(_examineeIdKey);
      await _box.delete(_examineeNameKey);
      await _box.delete(_sessionExpiresAtKey);
      await _box.delete(_sessionSnapshotKey);
      return const Success(null);
    } catch (error) {
      return ErrorResult(UnexpectedFailure('Failed to clear session: $error'));
    }
  }
}
