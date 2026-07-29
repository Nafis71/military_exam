import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_answers_hive_datasource.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_local_datasource.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_remote_datasource.dart';
import 'package:military_exam/features/exam_session/data/models/exam_session_model.dart';
import 'package:military_exam/features/exam_session/data/models/written_image_upload_result_model.dart';
import 'package:military_exam/features/exam_session/data/repositories/exam_repository_impl.dart';
import 'package:military_exam/features/onboarding/domain/entities/onboarding_candidate.dart';
import 'package:military_exam/features/onboarding/domain/entities/onboarding_state.dart';
import 'package:military_exam/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

import '../helpers/demo_exam_test_support.dart';

void main() {
  group('ExamRepositoryImpl roll number resolution', () {
    test(
      'uploadDescriptiveAnswerImage falls back to onboarding candidateId when Hive roll missing',
      () async {
        final remote = _FakeExamRemoteDataSource();
        final local = _FakeExamLocalDataSource(
          session: ExamSessionModel(
            sessionId: 'session-1',
            examineeId: 'auth-session-uuid',
            startedAt: DateTime(2026, 7, 28),
            durationMinutes: 30,
            isLocked: false,
            currentPhase: 'mcq',
          ),
        );
        final hive = _FakeExamAnswersHiveDataSource();
        final onboarding = _FakeOnboardingRepository(
          candidateId: 'candidate-123',
        );
        final deps = createLinkedDemoExamDependencies();
        final repository = ExamRepositoryImpl(
          remote,
          local,
          hive,
          deps.examRunContext,
          deps.demoMemoryStore,
          onboarding,
        );

        final result = await repository.uploadDescriptiveAnswerImage(
          questionId: 'written-1',
          filePath: '/tmp/answer.jpg',
        );

        expect(result, isA<Success<WrittenImageUploadResult>>());
        expect(remote.lastRollNumber, 'candidate-123');
      },
    );

    test(
      'uploadDescriptiveAnswerImage prefers Hive roll number over onboarding candidateId',
      () async {
        final remote = _FakeExamRemoteDataSource();
        final local = _FakeExamLocalDataSource(
          session: ExamSessionModel(
            sessionId: 'session-1',
            examineeId: 'auth-session-uuid',
            startedAt: DateTime(2026, 7, 28),
            durationMinutes: 30,
            isLocked: false,
            currentPhase: 'mcq',
          ),
        );
        final hive = _FakeExamAnswersHiveDataSource(rollNumber: '12345');
        final onboarding = _FakeOnboardingRepository(
          candidateId: 'candidate-123',
        );
        final deps = createLinkedDemoExamDependencies();
        final repository = ExamRepositoryImpl(
          remote,
          local,
          hive,
          deps.examRunContext,
          deps.demoMemoryStore,
          onboarding,
        );

        final result = await repository.uploadDescriptiveAnswerImage(
          questionId: 'written-1',
          filePath: '/tmp/answer.jpg',
        );

        expect(result, isA<Success<WrittenImageUploadResult>>());
        expect(remote.lastRollNumber, '12345');
      },
    );

    test(
      'uploadDescriptiveAnswerImage uses onboarding candidateId not session examineeId',
      () async {
        final remote = _FakeExamRemoteDataSource();
        final local = _FakeExamLocalDataSource(
          session: ExamSessionModel(
            sessionId: '896ff5e9-3b30-4035-a84d-61e55de6c09d',
            examineeId: '896ff5e9-3b30-4035-a84d-61e55de6c09d',
            startedAt: DateTime(2026, 7, 28),
            durationMinutes: 30,
            isLocked: false,
            currentPhase: 'mcq',
          ),
        );
        final hive = _FakeExamAnswersHiveDataSource();
        final onboarding = _FakeOnboardingRepository(
          candidateId: 'CAND-9876',
        );
        final deps = createLinkedDemoExamDependencies();
        final repository = ExamRepositoryImpl(
          remote,
          local,
          hive,
          deps.examRunContext,
          deps.demoMemoryStore,
          onboarding,
        );

        final result = await repository.uploadDescriptiveAnswerImage(
          questionId: 'written-1',
          filePath: '/tmp/answer.jpg',
        );

        expect(result, isA<Success<WrittenImageUploadResult>>());
        expect(remote.lastRollNumber, 'CAND-9876');
        expect(remote.lastRollNumber, isNot('896ff5e9-3b30-4035-a84d-61e55de6c09d'));
      },
    );

    test(
      'uploadDescriptiveAnswerImage returns ValidationFailure when roll and onboarding missing',
      () async {
        final remote = _FakeExamRemoteDataSource();
        final local = _FakeExamLocalDataSource();
        final hive = _FakeExamAnswersHiveDataSource();
        final onboarding = _FakeOnboardingRepository();
        final deps = createLinkedDemoExamDependencies();
        final repository = ExamRepositoryImpl(
          remote,
          local,
          hive,
          deps.examRunContext,
          deps.demoMemoryStore,
          onboarding,
        );

        final result = await repository.uploadDescriptiveAnswerImage(
          questionId: 'written-1',
          filePath: '/tmp/answer.jpg',
        );

        expect(result, isA<ErrorResult<WrittenImageUploadResult>>());
        final failure = (result as ErrorResult<WrittenImageUploadResult>).failure;
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Roll number missing');
        expect(remote.uploadCalls, 0);
      },
    );
  });
}

class _FakeExamRemoteDataSource implements ExamRemoteDataSource {
  int uploadCalls = 0;
  String? lastRollNumber;

  @override
  Future<Result<WrittenImageUploadResultModel>> uploadDescriptiveAnswerImage({
    required String questionId,
    required String rollNumber,
    required String filePath,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    uploadCalls++;
    lastRollNumber = rollNumber;
    return Success(
      WrittenImageUploadResultModel(
        answerId: 'answer-$questionId',
        questionId: questionId,
        imagePath: filePath,
        gradingStatus: 'PENDING',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeExamLocalDataSource implements ExamLocalDataSource {
  _FakeExamLocalDataSource({this.session});

  final ExamSessionModel? session;

  @override
  Future<Result<ExamSessionModel?>> readExamSession() async => Success(session);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeExamAnswersHiveDataSource implements ExamAnswersHiveDataSource {
  _FakeExamAnswersHiveDataSource({this.rollNumber});

  final String? rollNumber;

  @override
  Future<Result<String?>> readRollNumber() async => Success(rollNumber);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository({this.candidateId});

  final String? candidateId;

  @override
  Future<Result<OnboardingState>> getState() async {
    final id = candidateId;
    if (id == null || id.isEmpty) {
      return const Success(OnboardingState(isLoggedIn: false));
    }
    return Success(
      OnboardingState(
        isLoggedIn: true,
        candidate: OnboardingCandidate(
          candidateId: id,
          fullName: 'Test Candidate',
          phoneNumber: '000',
          emailAddress: 'test@example.com',
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
