import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/session_repository.dart';

class GetCurrentSessionUseCase {
  GetCurrentSessionUseCase(this._sessionRepository);

  final SessionRepository _sessionRepository;

  Future<Result<AuthSession?>> call() => _sessionRepository.getCurrentSession();
}
