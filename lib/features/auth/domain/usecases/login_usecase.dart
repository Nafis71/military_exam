import '../../../../core/utils/result.dart';
import '../../../../core/services/auth_token_holder.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../entities/login_credentials.dart';
import '../repositories/auth_repository.dart';
import '../repositories/session_repository.dart';

class LoginUseCase {
  LoginUseCase(
    this._authRepository,
    this._sessionRepository,
    this._tokenHolder,
  );

  final AuthRepository _authRepository;
  final SessionRepository _sessionRepository;
  final AuthTokenHolder _tokenHolder;

  Future<Result<AuthSession>> call(LoginCredentials credentials) async {
    final loginResult = await _authRepository.login(credentials);
    if (loginResult is ErrorResult<AuthSession>) {
      return loginResult;
    }

    final session = (loginResult as Success<AuthSession>).data;
    _tokenHolder.setToken(session.token);
    final saveResult = await _sessionRepository.saveSession(session);
    if (saveResult is ErrorResult<void>) {
      return ErrorResult(saveResult.failure);
    }

    return Success(session);
  }
}
