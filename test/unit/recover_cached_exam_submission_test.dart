import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/domain/usecases/has_cached_exam_answers_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/finalize_exam_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/recover_cached_exam_submission_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/submit_exam_with_pending_uploads_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/upload_pending_written_images_usecase.dart';
import 'package:military_exam/features/exam_session/domain/repositories/exam_repository.dart';
import 'package:military_exam/features/written_exam/domain/repositories/written_exam_repository.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

void main() {
  test('HasCachedExamAnswersUseCase returns true when exam repository has cache',
      () async {
    final examRepo = _FakeExamRepository(hasCache: true);
    final writtenRepo = _FakeWrittenExamRepository(images: const []);
    final useCase = HasCachedExamAnswersUseCase(examRepo, writtenRepo);

    final result = await useCase();

    expect(result, isA<Success<bool>>());
    expect((result as Success<bool>).data, isTrue);
  });

  test('HasCachedExamAnswersUseCase returns true when written images exist',
      () async {
    final examRepo = _FakeExamRepository(hasCache: false);
    final writtenRepo = _FakeWrittenExamRepository(
      images: [
        WrittenAnswerImage(
          localId: '1',
          localPath: '/tmp/a.jpg',
          questionId: 'q1',
        ),
      ],
    );
    final useCase = HasCachedExamAnswersUseCase(examRepo, writtenRepo);

    final result = await useCase();

    expect((result as Success<bool>).data, isTrue);
  });

  test('RecoverCachedExamSubmissionUseCase returns NetworkFailure unchanged',
      () async {
    final examRepo = _FakeExamRepository(
      refreshResult: const ErrorResult(NetworkFailure('offline')),
    );
    final writtenRepo = _FakeWrittenExamRepository(images: const []);
    final useCase = RecoverCachedExamSubmissionUseCase(
      SubmitExamWithPendingUploadsUseCase(
        examRepo,
        UploadPendingWrittenImagesUseCase(examRepo, writtenRepo),
        FinalizeExamUseCase(examRepo),
        ClearExamLocalDataUseCase(examRepo, writtenRepo),
      ),
    );

    final result = await useCase();

    expect(result, isA<ErrorResult>());
    expect((result as ErrorResult).failure, isA<NetworkFailure>());
  });
}

class _FakeExamRepository implements ExamRepository {
  _FakeExamRepository({
    this.hasCache = false,
    this.refreshResult,
  });

  final bool hasCache;
  final Result<CurrentExam>? refreshResult;

  @override
  Future<Result<bool>> hasCachedExamAnswers() async => Success(hasCache);

  @override
  Future<Result<CurrentExam>> refreshCurrentExam() async {
    return refreshResult ??
        Success(
          CurrentExam(
            examId: 'exam-1',
            examName: 'Exam',
            batchName: 'Batch',
            batchStatus: 'active',
            batchId: 'batch-1',
            totalQuestions: 1,
            durationMinutes: 60,
            window: const ExamWindow(
              startTime: null,
              examEndTime: null,
              submitEndTime: null,
              bufferTimeMinutes: 0,
              canAccessQuestions: true,
              canSubmit: true,
              remainingExamMinutes: 60,
              remainingSubmitMinutes: 60,
            ),
            questions: const [],
          ),
        );
  }

  @override
  Future<Result<SubmissionReceipt>> finalizeExam(CurrentExam? currentExam) async {
    return Success(
      SubmissionReceipt(
        submissionId: 'sub-1',
        submittedAt: DateTime(2026, 7, 20, 12),
        message: 'ok',
      ),
    );
  }

  @override
  Future<Result<WrittenImageUploadResult>> uploadDescriptiveAnswerImage({
    required String questionId,
    required String filePath,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    return Success(
      WrittenImageUploadResult(
        answerId: 'a1',
        questionId: questionId,
        imagePath: filePath,
        gradingStatus: 'PENDING',
      ),
    );
  }

  @override
  Future<Result<ExamSession>> startSession(String authSessionId) =>
      throw UnimplementedError();

  @override
  Future<Result<ExamSession?>> getCurrentSession() => throw UnimplementedError();

  @override
  Future<Result<CurrentExam>> getCurrentExam() => refreshCurrentExam();

  @override
  Future<Result<ExamTimer>> getTimer(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<Result<List<McqQuestion>>> getMcqQuestions(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<Result<List<FillBlankQuestion>>> getFillBlankQuestions(
    String sessionId,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<McqAnswer>> saveMcqAnswerLocally(McqAnswer answer) =>
      throw UnimplementedError();

  @override
  Future<Result<FillBlankAnswer>> saveFillBlankAnswerLocally(
    FillBlankAnswer answer,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> saveDescriptiveDraft(String questionId) =>
      throw UnimplementedError();

  @override
  Future<Result<Map<String, String>>> getMcqProgress(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<Result<Map<String, String>>> getFillBlankProgress(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> saveRollNumber(String rollNumber) =>
      throw UnimplementedError();

  @override
  Future<Result<String?>> getRollNumber() async => const Success('123');

  @override
  Future<Result<Map<String, ExamAnswerDraft>>> getAnswerDrafts() async =>
      const Success({});

  @override
  Future<Result<void>> clearLocalExamData() async => const Success(null);

  @override
  Future<Result<SubmissionReceipt>> autoSubmit(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<Result<SubmissionReceipt>> finishExam(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<Result<ExamLockState>> lockSession(String sessionId, String reason) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> reportViolation(SecurityViolation violation) =>
      throw UnimplementedError();
}

class _FakeWrittenExamRepository implements WrittenExamRepository {
  _FakeWrittenExamRepository({required this.images});

  final List<WrittenAnswerImage> images;

  @override
  Future<Result<List<WrittenAnswerImage>>> getImages() async => Success(images);

  @override
  Future<Result<WrittenAnswerImage>> addImage(
    String localPath,
    String questionId,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<WrittenAnswerImage>> replaceImage(
    String localId,
    String newLocalPath,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteImage(String localId) => throw UnimplementedError();

  @override
  Future<Result<UploadProgress>> uploadImage(String localId) =>
      throw UnimplementedError();

  @override
  Future<Result<SubmissionReceipt>> submitExam(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> markImageUploaded({
    required String localId,
    required String remoteId,
  }) async =>
      const Success(null);

  @override
  Future<Result<void>> clearStoredImages() async => const Success(null);
}
