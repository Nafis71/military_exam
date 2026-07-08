import '../../../../core/services/auth_token_holder.dart';
import '../../../../core/utils/result.dart';
import '../repositories/session_repository.dart';

class ClearSessionUseCase {
  ClearSessionUseCase(this._sessionRepository, this._tokenHolder);

  final SessionRepository _sessionRepository;
  final AuthTokenHolder _tokenHolder;

  Future<Result<void>> call() async {
    _tokenHolder.clear();
    return _sessionRepository.clearSession();
  }
}
