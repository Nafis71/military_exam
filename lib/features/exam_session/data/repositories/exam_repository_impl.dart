import '../../../../core/config/deployment.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../onboarding/domain/repositories/onboarding_repository.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../domain/utils/exam_question_splitter.dart';
import '../../domain/utils/finalize_payload_builder.dart';
import '../datasources/demo_exam_memory_store.dart';
import '../datasources/exam_answers_hive_datasource.dart';
import '../datasources/exam_local_datasource.dart';
import '../datasources/exam_remote_datasource.dart';
import '../models/exam_answer_draft_model.dart';
import '../models/exam_session_model.dart';

class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._answersHive,
    this._examRunContext,
    this._demoMemoryStore,
    this._onboardingRepository,
  );

  final ExamRemoteDataSource _remoteDataSource;
  final ExamLocalDataSource _localDataSource;
  final ExamAnswersHiveDataSource _answersHive;
  final ExamRunContext _examRunContext;
  final DemoExamMemoryStore _demoMemoryStore;
  final OnboardingRepository _onboardingRepository;
  CurrentExam? _cachedCurrentExam;

  bool get _isOnboardingDemo => _examRunContext.isOnboardingDemo;

  @override
  Future<Result<CurrentExam>> getCurrentExam() async {
    if (_cachedCurrentExam != null) {
      return Success(_cachedCurrentExam!);
    }

    final result = await _remoteDataSource.fetchCurrentExam();
    return switch (result) {
      Success(:final data) => () {
          _cachedCurrentExam = data;
          return Success<CurrentExam>(data);
        }(),
      ErrorResult(:final failure) => ErrorResult(failure),
    };
  }

  @override
  Future<Result<CurrentExam>> refreshCurrentExam() async {
    _cachedCurrentExam = null;
    return getCurrentExam();
  }

  @override
  Future<Result<bool>> hasCachedExamAnswers({
    Set<String> questionIdsWithImages = const {},
  }) async {
    if (_isOnboardingDemo) {
      return const Success(false);
    }

    final draftsResult = await _readAllDrafts();
    if (draftsResult is ErrorResult<Map<String, ExamAnswerDraftModel>>) {
      return ErrorResult(draftsResult.failure);
    }

    final drafts = (draftsResult as Success).data;
    final hasSubstantiveDrafts = drafts.values.any(
      (draft) => FinalizePayloadBuilder.shouldIncludeDraftForRecovery(
        draft,
        questionIdsWithImages: questionIdsWithImages,
      ),
    );
    if (hasSubstantiveDrafts) return const Success(true);

    final mcqResult = await _localDataSource.readMcqAnswers();
    if (mcqResult is ErrorResult<Map<String, String>>) {
      return ErrorResult(mcqResult.failure);
    }
    if ((mcqResult as Success).data.isNotEmpty) return const Success(true);

    final fillBlankResult = await _localDataSource.readFillBlankAnswers();
    if (fillBlankResult is ErrorResult<Map<String, String>>) {
      return ErrorResult(fillBlankResult.failure);
    }
    if ((fillBlankResult as Success).data.isNotEmpty) return const Success(true);

    return const Success(false);
  }

  @override
  Future<Result<ExamSession>> startSession(String authSessionId) async {
    final result = await _remoteDataSource.startSession(authSessionId);
    if (result is ErrorResult<ExamSessionModel>) {
      return ErrorResult(result.failure);
    }

    final model = (result as Success<ExamSessionModel>).data;
    if (!_isOnboardingDemo) {
      _cachedCurrentExam = null;
    }
    if (_isOnboardingDemo) {
      _demoMemoryStore.setSession(model);
    } else {
      await _localDataSource.saveExamSession(model);
    }
    return Success(model.toEntity());
  }

  @override
  Future<Result<ExamSession?>> getCurrentSession() async {
    if (_isOnboardingDemo) {
      return Success(_demoMemoryStore.session?.toEntity());
    }

    final local = await _localDataSource.readExamSession();
    if (local.dataOrNull != null) {
      return Success(local.dataOrNull!.toEntity());
    }

    if (Deployment.instance.isDemo) {
      return const Success(null);
    }

    final remote = await _remoteDataSource.fetchCurrentSession();
    if (remote is ErrorResult<ExamSessionModel?>) {
      return ErrorResult(remote.failure);
    }

    final model = (remote as Success<ExamSessionModel?>).data;
    if (model != null) {
      await _localDataSource.saveExamSession(model);
    }
    return Success(model?.toEntity());
  }

  @override
  Future<Result<ExamTimer>> getTimer(String sessionId) async {
    if (_isOnboardingDemo) {
      final session = _demoMemoryStore.session;
      if (session != null) {
        final remaining = session.startedAt
            .add(Duration(minutes: session.durationMinutes))
            .difference(DateTime.now())
            .inSeconds;
        return Success(ExamTimer(remainingSeconds: remaining.clamp(0, 86400)));
      }
    }

    if (Deployment.instance.isDemo) {
      final sessionResult = await _localDataSource.readExamSession();
      final session = sessionResult.dataOrNull;
      if (session != null) {
        final remaining = session.startedAt
            .add(Duration(minutes: session.durationMinutes))
            .difference(DateTime.now())
            .inSeconds;
        return Success(ExamTimer(remainingSeconds: remaining.clamp(0, 86400)));
      }
    }

    final examResult = await getCurrentExam();
    if (examResult is Success<CurrentExam>) {
      final exam = examResult.data;
      final remainingMinutes = exam.window.remainingExamMinutes;
      if (remainingMinutes > 0) {
        return Success(ExamTimer(remainingSeconds: remainingMinutes * 60));
      }
      final sessionResult = await _localDataSource.readExamSession();
      final session = sessionResult.dataOrNull;
      if (session != null && exam.durationMinutes > 0) {
        final remaining = session.startedAt
            .add(Duration(minutes: exam.durationMinutes))
            .difference(DateTime.now())
            .inSeconds;
        return Success(ExamTimer(remainingSeconds: remaining.clamp(0, 86400)));
      }
    }

    final result = await _remoteDataSource.fetchRemainingSeconds(sessionId);
    return switch (result) {
      Success(:final data) => Success(ExamTimer(remainingSeconds: data)),
      ErrorResult(:final failure) => ErrorResult(failure),
    };
  }

  @override
  Future<Result<List<McqQuestion>>> getMcqQuestions(String sessionId) async {
    final examResult = await getCurrentExam();
    if (examResult is ErrorResult<CurrentExam>) {
      return ErrorResult(examResult.failure);
    }

    final exam = (examResult as Success<CurrentExam>).data;
    return Success(ExamQuestionSplitter.toMcqQuestions(exam.questions));
  }

  @override
  Future<Result<List<FillBlankQuestion>>> getFillBlankQuestions(
    String sessionId,
  ) async {
    final examResult = await getCurrentExam();
    if (examResult is ErrorResult<CurrentExam>) {
      return ErrorResult(examResult.failure);
    }

    final exam = (examResult as Success<CurrentExam>).data;
    return Success(ExamQuestionSplitter.toFillBlankQuestions(exam.questions));
  }

  @override
  Future<Result<McqAnswer>> saveMcqAnswerLocally(McqAnswer answer) async {
    final examResult = await getCurrentExam();
    final questionNumber = _questionNumber(
      examResult.dataOrNull,
      answer.questionId,
    );
    final draft = ExamAnswerDraftModel(
      questionId: answer.questionId,
      type: ExamQuestionType.mcq,
      optionKey: answer.selectedOptionId,
      questionNumber: questionNumber,
    );
    final result = await _upsertDraft(draft);
    if (result is ErrorResult<void>) {
      return ErrorResult(result.failure);
    }
    return Success(answer);
  }

  @override
  Future<Result<FillBlankAnswer>> saveFillBlankAnswerLocally(
    FillBlankAnswer answer,
  ) async {
    final examResult = await getCurrentExam();
    final questionNumber = _questionNumber(
      examResult.dataOrNull,
      answer.questionId,
    );
    final draft = ExamAnswerDraftModel(
      questionId: answer.questionId,
      type: ExamQuestionType.fillInBlank,
      answerText: answer.text,
      questionNumber: questionNumber,
    );
    final result = await _upsertDraft(draft);
    if (result is ErrorResult<void>) {
      return ErrorResult(result.failure);
    }
    return Success(answer);
  }

  @override
  Future<Result<void>> saveDescriptiveDraft(String questionId) async {
    final examResult = await getCurrentExam();
    final questionNumber = _questionNumber(examResult.dataOrNull, questionId);
    final draft = ExamAnswerDraftModel(
      questionId: questionId,
      type: ExamQuestionType.descriptive,
      questionNumber: questionNumber,
    );
    return _upsertDraft(draft);
  }

  @override
  Future<Result<Map<String, String>>> getMcqProgress(String sessionId) async {
    final drafts = await _readAllDrafts();
    if (drafts is ErrorResult<Map<String, ExamAnswerDraftModel>>) {
      return ErrorResult(drafts.failure);
    }
    final map = <String, String>{};
    for (final entry in (drafts as Success).data.entries) {
      if (entry.value.type == ExamQuestionType.mcq &&
          entry.value.optionKey != null) {
        map[entry.key] = entry.value.optionKey!;
      }
    }
    return Success(map);
  }

  @override
  Future<Result<Map<String, String>>> getFillBlankProgress(String sessionId) async {
    final drafts = await _readAllDrafts();
    if (drafts is ErrorResult<Map<String, ExamAnswerDraftModel>>) {
      return ErrorResult(drafts.failure);
    }
    final map = <String, String>{};
    for (final entry in (drafts as Success).data.entries) {
      if (entry.value.type == ExamQuestionType.fillInBlank) {
        map[entry.key] = entry.value.answerText ?? '';
      }
    }
    return Success(map);
  }

  @override
  Future<Result<void>> saveRollNumber(String rollNumber) {
    if (_isOnboardingDemo) {
      return Future.value(const Success(null));
    }
    return _answersHive.saveRollNumber(rollNumber);
  }

  @override
  Future<Result<String?>> getRollNumber() {
    if (_isOnboardingDemo) {
      return Future.value(const Success(null));
    }
    return _answersHive.readRollNumber();
  }

  @override
  Future<Result<Map<String, ExamAnswerDraft>>> getAnswerDrafts() async {
    final draftsResult = await _readAllDrafts();
    if (draftsResult is ErrorResult<Map<String, ExamAnswerDraftModel>>) {
      return ErrorResult(draftsResult.failure);
    }
    return Success((draftsResult as Success).data);
  }

  @override
  Future<Result<SubmissionReceipt>> finalizeExam(
    CurrentExam? currentExam, {
    Set<String> questionIdsWithImages = const {},
  }) async {
    final rollNumberResult = await _resolveRollNumber();
    if (rollNumberResult is ErrorResult<String>) {
      return ErrorResult(rollNumberResult.failure);
    }
    final rollNumber = (rollNumberResult as Success<String>).data;

    final draftsResult = await _readAllDrafts();
    if (draftsResult is ErrorResult<Map<String, ExamAnswerDraftModel>>) {
      return ErrorResult(draftsResult.failure);
    }

    final answers = FinalizePayloadBuilder.build(
      drafts: (draftsResult as Success).data,
      orderedQuestions: currentExam?.questions,
      questionIdsWithImages: questionIdsWithImages,
    );

    final request = FinalizeExamRequest(
      rollNumber: rollNumber,
      answers: answers,
    );

    return _remoteDataSource.finalizeCurrentExam(request);
  }

  @override
  Future<Result<WrittenImageUploadResult>> uploadDescriptiveAnswerImage({
    required String questionId,
    required String filePath,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final rollNumberResult = await _resolveRollNumber();
    if (rollNumberResult is ErrorResult<String>) {
      return ErrorResult(rollNumberResult.failure);
    }
    final rollNumber = (rollNumberResult as Success<String>).data;

    final result = await _remoteDataSource.uploadDescriptiveAnswerImage(
      questionId: questionId,
      rollNumber: rollNumber,
      filePath: filePath,
      onSendProgress: onSendProgress,
    );

    return switch (result) {
      Success(:final data) => Success(data),
      ErrorResult(:final failure) => ErrorResult(failure),
    };
  }

  @override
  Future<Result<void>> clearLocalExamData() async {
    _cachedCurrentExam = null;
    _demoMemoryStore.clear();
    await _answersHive.clearAll();
    await _localDataSource.clearLegacyAnswerData();
    return const Success(null);
  }

  @override
  Future<Result<SubmissionReceipt>> autoSubmit(String sessionId) =>
      _remoteDataSource.autoSubmit(sessionId);

  @override
  Future<Result<SubmissionReceipt>> finishExam(String sessionId) =>
      _remoteDataSource.finishExam(sessionId);

  @override
  Future<Result<ExamLockState>> lockSession(
    String sessionId,
    String reason,
  ) async {
    if (_isOnboardingDemo) {
      return Success(
        ExamLockState(
          isLocked: true,
          reason: reason,
          lockedAt: DateTime.now(),
        ),
      );
    }

    await _localDataSource.setExamLocked(true, reason: reason);
    final sessionResult = await _localDataSource.readExamSession();
    final session = sessionResult.dataOrNull;
    if (session != null) {
      final locked = ExamSessionModel(
        sessionId: session.sessionId,
        examineeId: session.examineeId,
        startedAt: session.startedAt,
        durationMinutes: session.durationMinutes,
        isLocked: true,
        currentPhase: session.currentPhase,
      );
      await _localDataSource.saveExamSession(locked);
    }

    return Success(
      ExamLockState(
        isLocked: true,
        reason: reason,
        lockedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void>> reportViolation(SecurityViolation violation) =>
      _remoteDataSource.reportViolation(violation);

  Future<Result<String>> _resolveRollNumber() async {
    if (_isOnboardingDemo) {
      final session = _demoMemoryStore.session;
      final examineeId = session?.examineeId;
      if (examineeId != null && examineeId.isNotEmpty) {
        return Success(examineeId);
      }
      return const ErrorResult(ValidationFailure('Roll number missing'));
    }

    final rollResult = await getRollNumber();
    if (rollResult is ErrorResult<String?>) {
      return ErrorResult(rollResult.failure);
    }

    var rollNumber = rollResult.dataOrNull;
    if (rollNumber == null || rollNumber.isEmpty) {
      final stateResult = await _onboardingRepository.getState();
      switch (stateResult) {
        case ErrorResult(:final failure):
          return ErrorResult(failure);
        case Success(:final data):
          rollNumber = data.candidate?.candidateId;
      }
    }
    if (rollNumber == null || rollNumber.isEmpty) {
      return const ErrorResult(ValidationFailure('Roll number missing'));
    }
    return Success(rollNumber);
  }

  Future<Result<Map<String, ExamAnswerDraftModel>>> _readAllDrafts() async {
    if (_isOnboardingDemo) {
      return Success(_demoMemoryStore.drafts);
    }
    return _answersHive.readAllDrafts();
  }

  Future<Result<void>> _upsertDraft(ExamAnswerDraftModel draft) async {
    if (_isOnboardingDemo) {
      _demoMemoryStore.upsertDraft(draft);
      return const Success(null);
    }
    return _answersHive.upsertDraft(draft);
  }

  int _questionNumber(CurrentExam? exam, String questionId) {
    if (exam == null) return 0;
    for (final q in exam.questions) {
      if (q.id == questionId) return q.questionNumber;
    }
    return 0;
  }
}
