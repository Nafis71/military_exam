import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../entities/login_credentials.dart';

abstract class AuthRepository {
  Future<Result<AuthSession>> login(LoginCredentials credentials);

  Future<Result<List<String>>> getDistricts();

  Future<Result<ExamEligibility>> validateExamEligibility(String sessionId);
}
