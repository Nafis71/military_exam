import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/config/deployment.dart';
import '../../../../core/constants/exam_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../models/current_exam_model.dart';
import '../models/exam_question_model.dart';
import '../models/exam_question_option_model.dart';
import '../models/exam_session_model.dart';
import '../models/exam_window_model.dart';
import '../mappers/submission_receipt_mapper.dart';
import '../models/written_image_upload_result_model.dart';
import '../models/mcq_answer_model.dart';
import '../models/mcq_option_model.dart';
import '../models/mcq_question_model.dart';
import '../../../onboarding_demo/data/datasources/onboarding_demo_exam_datasource.dart';

abstract class ExamRemoteDataSource {
  Future<Result<ExamSessionModel>> startSession(String authSessionId);

  Future<Result<ExamSessionModel?>> fetchCurrentSession();

  Future<Result<int>> fetchRemainingSeconds(String sessionId);

  Future<Result<CurrentExamModel>> fetchCurrentExam();

  Future<Result<List<McqQuestionModel>>> fetchMcqQuestions(String sessionId);

  Future<Result<McqAnswerModel>> submitMcqAnswer(
    String sessionId,
    McqAnswerModel answer,
  );

  Future<Result<SubmissionReceipt>> autoSubmit(String sessionId);

  Future<Result<SubmissionReceipt>> finishExam(String sessionId);

  Future<Result<SubmissionReceipt>> finalizeCurrentExam(
    FinalizeExamRequest request,
  );

  Future<Result<WrittenImageUploadResultModel>> uploadDescriptiveAnswerImage({
    required String questionId,
    required String rollNumber,
    required String filePath,
    void Function(int sent, int total)? onSendProgress,
  });

  Future<Result<void>> reportViolation(SecurityViolation violation);
}

class ExamRemoteDataSourceImpl implements ExamRemoteDataSource {
  ExamRemoteDataSourceImpl(
    this._apiClient,
    this._logger,
    this._examRunContext,
  );

  final ApiClient _apiClient;
  final AppLogger _logger;
  final ExamRunContext _examRunContext;

  bool get _isOnboardingDemo => _examRunContext.isOnboardingDemo;

  static const _demoDurationMinutes = 90;

  @override
  Future<Result<ExamSessionModel>> startSession(String authSessionId) async {
    if (_isOnboardingDemo) {
      _logger.info('Onboarding demo: exam session served locally');
      return Success(OnboardingDemoExamDataSource.session(authSessionId));
    }
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: exam session served from device (no API call)');
      return Success(_localSession(authSessionId));
    }

    _logger.info('Building local exam session from auth credentials');
    return Success(_localSession(authSessionId));
  }

  ExamSessionModel _localSession(String authSessionId) {
    return ExamSessionModel(
      sessionId: authSessionId,
      examineeId: authSessionId,
      startedAt: DateTime.now(),
      durationMinutes: 0,
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
    if (_isOnboardingDemo) {
      return Success(OnboardingDemoExamDataSource.durationMinutes * 60);
    }
    if (Deployment.instance.isDemo) {
      return Success(_demoDurationMinutes * 60);
    }

    final examResult = await fetchCurrentExam();
    if (examResult is Success<CurrentExamModel>) {
      final remainingMinutes = examResult.data.window.remainingExamMinutes;
      if (remainingMinutes > 0) {
        return Success(remainingMinutes * 60);
      }
      if (examResult.data.durationMinutes > 0) {
        return Success(examResult.data.durationMinutes * 60);
      }
    }

    return const Success(0);
  }

  @override
  Future<Result<CurrentExamModel>> fetchCurrentExam() async {
    if (_isOnboardingDemo) {
      _logger.info('Onboarding demo: current exam served locally');
      return Success(OnboardingDemoExamDataSource.currentExam);
    }
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: current exam served from device (no API call)');
      return Success(_demoCurrentExam);
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.currentExam,
    );

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data['data'];
      if (data is Map<String, dynamic>) {
        try {
          return Success(CurrentExamModel.fromJson(data));
        } catch (error, stackTrace) {
          _logger.error(
            'Current exam API returned invalid data',
            error: error,
            stackTrace: stackTrace,
          );
          return const ErrorResult(
            UnexpectedFailure(AppStrings.networkRequestFailed),
          );
        }
      }
      _logger.warning('Current exam API returned invalid data shape');
      return const ErrorResult(
        UnexpectedFailure(AppStrings.networkRequestFailed),
      );
    }

    if (result is ErrorResult<Map<String, dynamic>>) {
      return ErrorResult(result.failure);
    }

    _logger.warning('Current exam API failed');
    return const ErrorResult(UnexpectedFailure(AppStrings.networkRequestFailed));
  }

  @override
  Future<Result<List<McqQuestionModel>>> fetchMcqQuestions(
    String sessionId,
  ) async {
    if (_isOnboardingDemo) {
      return Success(OnboardingDemoExamDataSource.mcqQuestions);
    }
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
    if (_isOnboardingDemo || Deployment.instance.isDemo) {
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
    if (_isOnboardingDemo) {
      return Success(
        OnboardingDemoExamDataSource.receipt(AppStrings.onboardingDemoSubmitted),
      );
    }
    if (Deployment.instance.isDemo) {
      return Success(_demoReceipt(AppStrings.autoSubmittedDemo));
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.examAutoSubmit,
      data: {'session_id': sessionId},
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(_parseReceiptOrFallback(
        result.data,
        fallbackMessage: AppStrings.autoSubmittedTimeExpiry,
      ));
    }

    return Success(_demoReceipt(AppStrings.autoSubmittedTimeExpiry));
  }

  @override
  Future<Result<SubmissionReceipt>> finishExam(String sessionId) async {
    if (_isOnboardingDemo) {
      return Success(
        OnboardingDemoExamDataSource.receipt(AppStrings.onboardingDemoSubmitted),
      );
    }
    if (Deployment.instance.isDemo) {
      return Success(_demoReceipt(AppStrings.examSubmittedDemo));
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.examSubmit,
      data: {'session_id': sessionId},
    );

    if (result is Success<Map<String, dynamic>>) {
      return Success(_parseReceiptOrFallback(
        result.data,
        fallbackMessage: AppStrings.examSubmittedSuccessfully,
      ));
    }

    return Success(_demoReceipt(AppStrings.examSubmittedSuccessfully));
  }

  @override
  Future<Result<SubmissionReceipt>> finalizeCurrentExam(
    FinalizeExamRequest request,
  ) async {
    if (_isOnboardingDemo) {
      return Success(
        OnboardingDemoExamDataSource.receipt(AppStrings.onboardingDemoSubmitted),
      );
    }
    if (Deployment.instance.isDemo) {
      return Success(_demoReceipt(AppStrings.examSubmittedDemo));
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.examFinalize,
      data: request.toJson(),
    );

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data['data'] as Map<String, dynamic>? ?? result.data;
      return Success(_parseReceiptOrFallback(
        data,
        fallbackMessage: AppStrings.examSubmittedSuccessfully,
      ));
    }

    if (result is ErrorResult<Map<String, dynamic>>) {
      return ErrorResult(result.failure);
    }

    return const ErrorResult(UnexpectedFailure(AppStrings.networkRequestFailed));
  }

  @override
  Future<Result<WrittenImageUploadResultModel>> uploadDescriptiveAnswerImage({
    required String questionId,
    required String rollNumber,
    required String filePath,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    if (_isOnboardingDemo || Deployment.instance.isDemo) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return Success(
        WrittenImageUploadResultModel(
          answerId: 'demo-answer-${DateTime.now().millisecondsSinceEpoch}',
          questionId: questionId,
          imagePath: filePath,
          gradingStatus: 'PENDING',
        ),
      );
    }

    if (!File(filePath).existsSync()) {
      return const ErrorResult(UploadFailure(AppStrings.imageFileNotFound));
    }

    final formData = FormData.fromMap({
      'roll_number': rollNumber,
      'file': await MultipartFile.fromFile(filePath),
    });

    final result = await _apiClient.upload<Map<String, dynamic>>(
      ApiEndpoints.examAnswerImageUpload(questionId),
      formData: formData,
      onSendProgress: onSendProgress,
    );

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data['data'] as Map<String, dynamic>? ?? result.data;
      return Success(WrittenImageUploadResultModel.fromJson(data));
    }

    if (result is ErrorResult<Map<String, dynamic>>) {
      return ErrorResult(result.failure);
    }

    return const ErrorResult(UploadFailure(AppStrings.writtenExamImageUploadFailed));
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

  SubmissionReceipt _parseReceiptOrFallback(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    try {
      return SubmissionReceiptMapper.fromJson(json);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to parse submission receipt; using local fallback',
        error: error,
        stackTrace: stackTrace,
      );
      return _demoReceipt(fallbackMessage);
    }
  }

  static CurrentExamModel get _demoCurrentExam {
    return CurrentExamModel(
      examId: 'demo-exam-1',
      examName: AppStrings.finishExamDefaultName,
      batchName: 'demo-batch',
      batchStatus: 'active',
      batchId: 'demo-batch-id',
      totalQuestions: 9,
      durationMinutes: _demoDurationMinutes,
      window: const ExamWindowModel(
        startTime: null,
        examEndTime: null,
        submitEndTime: null,
        bufferTimeMinutes: 5,
        canAccessQuestions: true,
        canSubmit: true,
        remainingExamMinutes: _demoDurationMinutes,
        remainingSubmitMinutes: _demoDurationMinutes + 5,
      ),
      questions: _demoExamQuestions,
    );
  }

  static List<ExamQuestionModel> get _demoExamQuestions {
    var questionNumber = 1;
    final questions = <ExamQuestionModel>[
      for (final mcq in _demoMcqQuestions)
        ExamQuestionModel(
          id: mcq.id,
          questionNumber: questionNumber++,
          type: ExamQuestionType.mcq,
          text: mcq.question,
          mark: 1,
          options: mcq.options
              .map(
                (option) => ExamQuestionOptionModel(
                  key: option.id,
                  text: option.label,
                ),
              )
              .toList(),
        ),
      ExamQuestionModel(
        id: 'demo-fill-1',
        questionNumber: questionNumber++,
        type: ExamQuestionType.fillInBlank,
        text: AppStrings.demoFillBlankQuestion1,
        mark: 1,
      ),
      ExamQuestionModel(
        id: 'demo-fill-2',
        questionNumber: questionNumber++,
        type: ExamQuestionType.fillInBlank,
        text: AppStrings.demoFillBlankQuestion2,
        mark: 1,
      ),
      ExamQuestionModel(
        id: 'written-q1',
        questionNumber: questionNumber++,
        type: ExamQuestionType.descriptive,
        text: AppStrings.demoDescriptiveQuestion1,
        mark: 10,
      ),
      ExamQuestionModel(
        id: 'written-q2',
        questionNumber: questionNumber++,
        type: ExamQuestionType.descriptive,
        text: 'তোমার দেশ সম্পর্কে ৫টি বাক্য লেখ।',
        mark: 10,
      ),
    ];
    return questions;
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
