import '../../../../core/config/deployment.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_local_datasource.dart';
import '../datasources/exam_remote_datasource.dart';
import '../models/exam_session_model.dart';
import '../models/mcq_answer_model.dart';

class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final ExamRemoteDataSource _remoteDataSource;
  final ExamLocalDataSource _localDataSource;

  @override
  Future<Result<ExamSession>> startSession(String authSessionId) async {
    final result = await _remoteDataSource.startSession(authSessionId);
    if (result is ErrorResult<ExamSessionModel>) {
      return ErrorResult(result.failure);
    }

    final model = (result as Success<ExamSessionModel>).data;
    await _localDataSource.saveExamSession(model);
    return Success(model.toEntity());
  }

  @override
  Future<Result<ExamSession?>> getCurrentSession() async {
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

    final result = await _remoteDataSource.fetchRemainingSeconds(sessionId);
    return switch (result) {
      Success(:final data) => Success(ExamTimer(remainingSeconds: data)),
      ErrorResult(:final failure) => ErrorResult(failure),
    };
  }

  @override
  Future<Result<List<McqQuestion>>> getMcqQuestions(String sessionId) async {
    final result = await _remoteDataSource.fetchMcqQuestions(sessionId);
    return switch (result) {
      Success(:final data) =>
        Success(data.map((q) => q.toEntity()).toList()),
      ErrorResult(:final failure) => ErrorResult(failure),
    };
  }

  @override
  Future<Result<McqAnswer>> submitMcqAnswer(McqAnswer answer) async {
    final sessionResult = await _localDataSource.readExamSession();
    final sessionId = sessionResult.dataOrNull?.sessionId ?? 'local';

    final model = McqAnswerModel.fromEntity(answer);
    final remoteResult =
        await _remoteDataSource.submitMcqAnswer(sessionId, model);
    if (remoteResult is ErrorResult<McqAnswerModel>) {
      return ErrorResult(remoteResult.failure);
    }

    await _localDataSource.saveMcqAnswer(model);
    return Success(answer);
  }

  @override
  Future<Result<Map<String, String>>> getMcqProgress(String sessionId) =>
      _localDataSource.readMcqAnswers();

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
}
