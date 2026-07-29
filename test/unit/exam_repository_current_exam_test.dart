import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_answers_hive_datasource.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_local_datasource.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_remote_datasource.dart';
import 'package:military_exam/features/exam_session/data/models/current_exam_model.dart';
import 'package:military_exam/features/exam_session/data/models/exam_session_model.dart';
import 'package:military_exam/features/exam_session/data/models/exam_window_model.dart';
import 'package:military_exam/features/exam_session/data/repositories/exam_repository_impl.dart';
import 'package:military_exam/features/onboarding/domain/entities/onboarding_state.dart';
import 'package:military_exam/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

import '../helpers/demo_exam_test_support.dart';

void main() {
  group('ExamRepositoryImpl current exam cache', () {
    test('getCurrentExam reuses in-memory cache until refresh', () async {
      final remote = _CountingExamRemoteDataSource();
      final repository = _buildRepository(remote);

      final first = await repository.getCurrentExam();
      final second = await repository.getCurrentExam();

      expect(first, isA<Success<CurrentExam>>());
      expect(second, isA<Success<CurrentExam>>());
      expect(remote.fetchCurrentExamCalls, 1);
    });

    test('refreshCurrentExam fetches from remote again', () async {
      final remote = _CountingExamRemoteDataSource();
      final repository = _buildRepository(remote);

      await repository.getCurrentExam();
      await repository.refreshCurrentExam();

      expect(remote.fetchCurrentExamCalls, 2);
    });

    test('startSession clears cached current exam for real exams', () async {
      final remote = _CountingExamRemoteDataSource();
      final repository = _buildRepository(remote);

      await repository.getCurrentExam();
      await repository.startSession('auth-session-1');
      await repository.getCurrentExam();

      expect(remote.fetchCurrentExamCalls, 2);
      expect(remote.startSessionCalls, 1);
    });

    test('propagates fetchCurrentExam failure without demo fallback', () async {
      final remote = _CountingExamRemoteDataSource(
        fetchResult: const ErrorResult(
          UnexpectedFailure('Current exam unavailable'),
        ),
      );
      final repository = _buildRepository(remote);

      final result = await repository.getCurrentExam();

      expect(result, isA<ErrorResult<CurrentExam>>());
      expect(
        (result as ErrorResult<CurrentExam>).failure.message,
        'Current exam unavailable',
      );
    });
  });
}

ExamRepositoryImpl _buildRepository(_CountingExamRemoteDataSource remote) {
  final deps = createLinkedDemoExamDependencies();
  return ExamRepositoryImpl(
    remote,
    _FakeExamLocalDataSource(),
    _FakeExamAnswersHiveDataSource(),
    deps.examRunContext,
    deps.demoMemoryStore,
    _FakeOnboardingRepository(),
  );
}

class _CountingExamRemoteDataSource implements ExamRemoteDataSource {
  _CountingExamRemoteDataSource({this.fetchResult});

  int fetchCurrentExamCalls = 0;
  int startSessionCalls = 0;
  final Result<CurrentExamModel>? fetchResult;

  static final _sampleExam = CurrentExamModel(
    examId: 'exam-1',
    examName: 'Sample Exam',
    batchName: 'batch-a',
    batchStatus: 'active',
    batchId: 'batch-1',
    totalQuestions: 1,
    durationMinutes: 60,
    window: const ExamWindowModel(
      startTime: null,
      examEndTime: null,
      submitEndTime: null,
      bufferTimeMinutes: 5,
      canAccessQuestions: true,
      canSubmit: true,
      remainingExamMinutes: 60,
      remainingSubmitMinutes: 65,
    ),
    questions: const [],
  );

  @override
  Future<Result<CurrentExamModel>> fetchCurrentExam() async {
    fetchCurrentExamCalls++;
    return fetchResult ?? Success(_sampleExam);
  }

  @override
  Future<Result<ExamSessionModel>> startSession(String authSessionId) async {
    startSessionCalls++;
    return Success(
      ExamSessionModel(
        sessionId: authSessionId,
        examineeId: authSessionId,
        startedAt: DateTime(2026, 7, 29),
        durationMinutes: 60,
        isLocked: false,
        currentPhase: 'mcq',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeExamLocalDataSource implements ExamLocalDataSource {
  @override
  Future<Result<void>> saveExamSession(ExamSessionModel session) async =>
      const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeExamAnswersHiveDataSource implements ExamAnswersHiveDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeOnboardingRepository implements OnboardingRepository {
  @override
  Future<Result<OnboardingState>> getState() async =>
      const Success(OnboardingState(isLoggedIn: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
