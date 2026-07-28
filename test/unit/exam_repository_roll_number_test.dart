import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_answers_hive_datasource.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_local_datasource.dart';
import 'package:military_exam/features/exam_session/data/datasources/exam_remote_datasource.dart';
import 'package:military_exam/features/exam_session/data/models/exam_session_model.dart';
import 'package:military_exam/features/exam_session/data/models/written_image_upload_result_model.dart';
import 'package:military_exam/features/exam_session/data/repositories/exam_repository_impl.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

void main() {
  group('ExamRepositoryImpl roll number resolution', () {
    test(
      'uploadDescriptiveAnswerImage falls back to session examineeId when Hive roll missing',
      () async {
        final remote = _FakeExamRemoteDataSource();
        final local = _FakeExamLocalDataSource(
          session: ExamSessionModel(
            sessionId: 'session-1',
            examineeId: 'onboarding-demo-auth',
            startedAt: DateTime(2026, 7, 28),
            durationMinutes: 30,
            isLocked: false,
            currentPhase: 'mcq',
          ),
        );
        final hive = _FakeExamAnswersHiveDataSource();
        final repository = ExamRepositoryImpl(remote, local, hive);

        final result = await repository.uploadDescriptiveAnswerImage(
          questionId: 'written-1',
          filePath: '/tmp/answer.jpg',
        );

        expect(result, isA<Success<WrittenImageUploadResult>>());
        expect(remote.lastRollNumber, 'onboarding-demo-auth');
      },
    );

    test(
      'uploadDescriptiveAnswerImage prefers Hive roll number over session examineeId',
      () async {
        final remote = _FakeExamRemoteDataSource();
        final local = _FakeExamLocalDataSource(
          session: ExamSessionModel(
            sessionId: 'session-1',
            examineeId: 'onboarding-demo-auth',
            startedAt: DateTime(2026, 7, 28),
            durationMinutes: 30,
            isLocked: false,
            currentPhase: 'mcq',
          ),
        );
        final hive = _FakeExamAnswersHiveDataSource(rollNumber: '12345');
        final repository = ExamRepositoryImpl(remote, local, hive);

        final result = await repository.uploadDescriptiveAnswerImage(
          questionId: 'written-1',
          filePath: '/tmp/answer.jpg',
        );

        expect(result, isA<Success<WrittenImageUploadResult>>());
        expect(remote.lastRollNumber, '12345');
      },
    );

    test(
      'uploadDescriptiveAnswerImage returns ValidationFailure when roll and session missing',
      () async {
        final remote = _FakeExamRemoteDataSource();
        final local = _FakeExamLocalDataSource();
        final hive = _FakeExamAnswersHiveDataSource();
        final repository = ExamRepositoryImpl(remote, local, hive);

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
