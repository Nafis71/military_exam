import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Result<AuthSession>> login(LoginCredentials credentials) async {
    final result = await _remoteDataSource.login(
      LoginRequestModel.fromCredentials(credentials),
    );

    return switch (result) {
      Success(:final data) => Success(data.toEntity()),
      ErrorResult(:final failure) => ErrorResult(failure),
    };
  }

  @override
  Future<Result<ExamEligibility>> validateExamEligibility(
    String sessionId,
  ) =>
      _remoteDataSource.checkEligibility(sessionId);
}
