import '../../../../core/constants/app_strings.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/config/deployment.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../models/candidate_model.dart';
import '../models/login_request_model.dart';

abstract class AuthRemoteDataSource {
  Future<Result<CandidateModel>> login(LoginRequestModel request);

  Future<Result<List<String>>> getDistricts();

  Future<Result<ExamEligibility>> checkEligibility(String sessionId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._apiClient, this._logger);

  final ApiClient _apiClient;
  final AppLogger _logger;

  @override
  Future<Result<CandidateModel>> login(LoginRequestModel request) async {
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: login served from device (no API call)');
      return Success(_demoLoginResponse(request));
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(CandidateModel.fromJson(result.data));
    }

    if (result is ErrorResult<Map<String, dynamic>>) {
      return ErrorResult(result.failure);
    }

    return const ErrorResult(UnexpectedFailure(AppStrings.networkRequestFailed));
  }

  @override
  Future<Result<List<String>>> getDistricts() async {
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: districts served from device (no API call)');
      return const Success(['DHAKA', 'PANCHAGAR']);
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.districts,
    );

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data['data'];
      if (data is! List) {
        _logger.warning('Districts API returned invalid data shape');
        return const ErrorResult(UnexpectedFailure(AppStrings.networkRequestFailed));
      }

      return Success(
        data.map((item) => item.toString()).toList(growable: false),
      );
    }

    if (result is ErrorResult<Map<String, dynamic>>) {
      return ErrorResult(result.failure);
    }

    return const ErrorResult(UnexpectedFailure(AppStrings.networkRequestFailed));
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

  CandidateModel _demoLoginResponse(LoginRequestModel request) {
    return CandidateModel(
      id: 'demo-candidate-${DateTime.now().millisecondsSinceEpoch}',
      fullName: '${AppStrings.demoExamineeNamePrefix} ${request.rollNumber}',
      district: '',
      rollNumber: request.rollNumber,
      status: 'attended',
    );
  }
}
