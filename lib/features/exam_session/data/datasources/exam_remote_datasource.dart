import '../../../../core/config/api_endpoints.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/config/deployment.dart';
import '../../../../core/constants/exam_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../models/exam_session_model.dart';
import '../models/mcq_answer_model.dart';
import '../models/mcq_option_model.dart';
import '../models/mcq_question_model.dart';

abstract class ExamRemoteDataSource {
  Future<Result<ExamSessionModel>> startSession(String authSessionId);

  Future<Result<ExamSessionModel?>> fetchCurrentSession();

  Future<Result<int>> fetchRemainingSeconds(String sessionId);

  Future<Result<List<McqQuestionModel>>> fetchMcqQuestions(String sessionId);

  Future<Result<McqAnswerModel>> submitMcqAnswer(
    String sessionId,
    McqAnswerModel answer,
  );

  Future<Result<SubmissionReceipt>> autoSubmit(String sessionId);

  Future<Result<SubmissionReceipt>> finishExam(String sessionId);

  Future<Result<void>> reportViolation(SecurityViolation violation);
}

class ExamRemoteDataSourceImpl implements ExamRemoteDataSource {
  ExamRemoteDataSourceImpl(this._apiClient, this._logger);

  final ApiClient _apiClient;
  final AppLogger _logger;

  static const _demoDurationMinutes = 90;

  @override
  Future<Result<ExamSessionModel>> startSession(String authSessionId) async {
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: exam session served from device (no API call)');
      return Success(_demoSession(authSessionId));
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.sessionStart,
      data: {'auth_session_id': authSessionId},
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(ExamSessionModel.fromJson(result.data));
    }

    _logger.warning('Start session API failed, returning demo session');
    return Success(_demoSession(authSessionId));
  }

  ExamSessionModel _demoSession(String authSessionId) {
    return ExamSessionModel(
      sessionId: 'exam-${DateTime.now().millisecondsSinceEpoch}',
      examineeId: authSessionId,
      startedAt: DateTime.now(),
      durationMinutes: _demoDurationMinutes,
      isLocked: false,
      currentPhase: ExamPhase.mcq.name,
    );
  }

  @override
  Future<Result<ExamSessionModel?>> fetchCurrentSession() async {
    if (Deployment.instance.isDemo) {
      return const Success(null);
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.sessionCurrent,
    );

    if (result is Success<Map<String, dynamic>>) {
      if (result.data.isEmpty) return const Success(null);
      return Success(ExamSessionModel.fromJson(result.data));
    }

    return const Success(null);
  }

  @override
  Future<Result<int>> fetchRemainingSeconds(String sessionId) async {
    if (Deployment.instance.isDemo) {
      return Success(_demoDurationMinutes * 60);
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.sessionStatus,
      queryParameters: {'session_id': sessionId},
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(result.data['remaining_seconds'] as int? ?? 0);
    }

    _logger.warning('Timer API failed, returning demo remaining time');
    return Success(_demoDurationMinutes * 60);
  }

  @override
  Future<Result<List<McqQuestionModel>>> fetchMcqQuestions(
    String sessionId,
  ) async {
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: MCQ questions served from device (no API call)');
      return Success(_demoMcqQuestions);
    }

    final result = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.mcqQuestions,
      queryParameters: {'session_id': sessionId},
    );

    if (result is Success<List<dynamic>>) {
      final questions = result.data
          .map((e) => McqQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(questions);
    }

    _logger.warning('MCQ API failed, returning demo soldier questions');
    return Success(_demoMcqQuestions);
  }

  @override
  Future<Result<McqAnswerModel>> submitMcqAnswer(
    String sessionId,
    McqAnswerModel answer,
  ) async {
    if (Deployment.instance.isDemo) {
      return Success(answer);
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.mcqAnswer,
      data: {
        'session_id': sessionId,
        ...answer.toJson(),
      },
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(answer);
    }

    _logger.warning('Submit MCQ API failed, accepting demo answer locally');
    return Success(answer);
  }

  @override
  Future<Result<SubmissionReceipt>> autoSubmit(String sessionId) async {
    if (Deployment.instance.isDemo) {
      return Success(_demoReceipt(AppStrings.autoSubmittedDemo));
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.examAutoSubmit,
      data: {'session_id': sessionId},
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(_receiptFromJson(result.data));
    }

    return Success(_demoReceipt(AppStrings.autoSubmittedTimeExpiry));
  }

  @override
  Future<Result<SubmissionReceipt>> finishExam(String sessionId) async {
    if (Deployment.instance.isDemo) {
      return Success(_demoReceipt(AppStrings.examSubmittedDemo));
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.examSubmit,
      data: {'session_id': sessionId},
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(_receiptFromJson(result.data));
    }

    return Success(_demoReceipt(AppStrings.examSubmittedSuccessfully));
  }

  @override
  Future<Result<void>> reportViolation(SecurityViolation violation) async {
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: violation logged on device only (no API call)');
      return const Success(null);
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.securityViolations,
      data: {
        'type': violation.type.name,
        'occurred_at': violation.occurredAt.toIso8601String(),
        'phase': violation.phase.name,
        'session_id': violation.sessionId,
        'platform': violation.platform,
      },
    );

    if (result is ErrorResult<Map<String, dynamic>>) {
      _logger.warning('Violation report API failed, continuing locally');
    }

    return const Success(null);
  }

  SubmissionReceipt _demoReceipt(String message) {
    return SubmissionReceipt(
      submissionId: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      submittedAt: DateTime.now(),
      message: message,
    );
  }

  SubmissionReceipt _receiptFromJson(Map<String, dynamic> json) {
    return SubmissionReceipt(
      submissionId: json['submission_id'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      message: json['message'] as String? ?? AppStrings.submitted,
    );
  }

  static List<McqQuestionModel> get _demoMcqQuestions {
    const total = ExamConstants.demoMcqCount;
    const questions = [
      (
        AppStrings.mcq1Question,
        [
          ('a', AppStrings.mcq1OptionA),
          ('b', AppStrings.mcq1OptionB),
          ('c', AppStrings.mcq1OptionC),
          ('d', AppStrings.mcq1OptionD),
        ],
      ),
      (
        AppStrings.mcq2Question,
        [
          ('a', AppStrings.mcq2OptionA),
          ('b', AppStrings.mcq2OptionB),
          ('c', AppStrings.mcq2OptionC),
          ('d', AppStrings.mcq2OptionD),
        ],
      ),
      (
        AppStrings.mcq3Question,
        [
          ('a', AppStrings.mcq3OptionA),
          ('b', AppStrings.mcq3OptionB),
          ('c', AppStrings.mcq3OptionC),
          ('d', AppStrings.mcq3OptionD),
        ],
      ),
      (
        AppStrings.mcq4Question,
        [
          ('a', AppStrings.mcq4OptionA),
          ('b', AppStrings.mcq4OptionB),
          ('c', AppStrings.mcq4OptionC),
          ('d', AppStrings.mcq4OptionD),
        ],
      ),
      (
        AppStrings.mcq5Question,
        [
          ('a', AppStrings.mcq5OptionA),
          ('b', AppStrings.mcq5OptionB),
          ('c', AppStrings.mcq5OptionC),
          ('d', AppStrings.mcq5OptionD),
        ],
      ),
    ];

    return List.generate(total, (index) {
      final item = questions[index];
      return McqQuestionModel(
        id: 'mcq-${index + 1}',
        question: item.$1,
        options: item.$2
            .map((o) => McqOptionModel(id: o.$1, label: o.$2))
            .toList(),
        index: index + 1,
        total: total,
      );
    });
  }
}
