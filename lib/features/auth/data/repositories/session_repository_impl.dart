import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_datasource.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._localDataSource);

  final SessionLocalDataSource _localDataSource;

  @override
  Future<Result<AuthSession?>> getCurrentSession() =>
      _localDataSource.readSession();

  @override
  Future<Result<void>> saveSession(AuthSession session) =>
      _localDataSource.writeSession(session);

  @override
  Future<Result<void>> clearSession() => _localDataSource.deleteSession();
}
