import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

abstract class SessionRepository {
  Future<Result<AuthSession?>> getCurrentSession();

  Future<Result<void>> saveSession(AuthSession session);

  Future<Result<void>> clearSession();
}
