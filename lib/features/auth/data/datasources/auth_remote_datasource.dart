import '../../../../core/constants/app_strings.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/config/deployment.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<Result<LoginResponseModel>> login(LoginRequestModel request);

  Future<Result<ExamEligibility>> checkEligibility(String sessionId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._apiClient, this._logger);

  final ApiClient _apiClient;
  final AppLogger _logger;

  @override
  Future<Result<LoginResponseModel>> login(LoginRequestModel request) async {
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: login served from device (no API call)');
      return Success(_demoLoginResponse(request.examineeId));
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(LoginResponseModel.fromJson(result.data));
    }

    _logger.warning('Login API failed, returning demo session');
    return Success(_demoLoginResponse(request.examineeId));
  }

  @override
  Future<Result<ExamEligibility>> checkEligibility(String sessionId) async {
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: eligibility served from device (no API call)');
      return const Success(
        ExamEligibility(
          isEligible: true,
          isExamActive: true,
          isLocked: false,
          message: AppStrings.demoEligibleForExam,
        ),
      );
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.eligibility,
      queryParameters: {'session_id': sessionId},
    );

    if (result is Success<Map<String, dynamic>>) {
      final json = result.data;
      return Success(
        ExamEligibility(
          isEligible: json['is_eligible'] as bool? ?? true,
          isExamActive: json['is_exam_active'] as bool? ?? true,
          isLocked: json['is_locked'] as bool? ?? false,
          message: json['message'] as String?,
        ),
      );
    }

    _logger.warning('Eligibility API failed, returning demo eligibility');
    return const Success(
      ExamEligibility(
        isEligible: true,
        isExamActive: true,
        isLocked: false,
        message: AppStrings.demoEligibleForExam,
      ),
    );
  }

  LoginResponseModel _demoLoginResponse(String examineeId) {
    return LoginResponseModel(
      token: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: 'demo-session-${DateTime.now().millisecondsSinceEpoch}',
      examineeId: examineeId,
      examineeName: '${AppStrings.demoExamineeNamePrefix} $examineeId',
      expiresAt: DateTime.now().add(const Duration(hours: 4)),
    );
  }
}
