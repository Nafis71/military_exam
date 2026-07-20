import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/domain/ports/pending_exam_answers_flusher.dart';
import 'package:military_exam/features/exam_session/domain/repositories/exam_repository.dart';
import 'package:military_exam/features/exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/finalize_exam_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/submit_saved_exam_answers_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/upload_pending_written_images_usecase.dart';
import 'package:military_exam/features/written_exam/domain/repositories/written_exam_repository.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

class _RecordingFlusher implements PendingExamAnswersFlusher {
  ExamPhase? flushedPhase;

  @override
  Future<void> flush(ExamPhase phase) async {
    flushedPhase = phase;
  }
}

class _FakeExamRepository implements ExamRepository {
  _FakeExamRepository(this.currentExam, this.receipt);

  final CurrentExam currentExam;
  final SubmissionReceipt receipt;
  int finalizeCalls = 0;
  int clearCalls = 0;
  int refreshCalls = 0;
  int uploadCalls = 0;

  @override
  Future<Result<CurrentExam>> refreshCurrentExam() async {
    refreshCalls += 1;
    return Success(currentExam);
  }

  @override
  Future<Result<SubmissionReceipt>> finalizeExam(CurrentExam? exam) async {
    finalizeCalls += 1;
    return Success(receipt);
  }

  @override
  Future<Result<void>> clearLocalExamData() async {
    clearCalls += 1;
    return const Success(null);
  }

  @override
  Future<Result<WrittenImageUploadResult>> uploadDescriptiveAnswerImage({
    required String questionId,
    required String filePath,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    uploadCalls += 1;
    return Success(
      WrittenImageUploadResult(
        answerId: 'answer-$questionId',
        questionId: questionId,
        imagePath: filePath,
        gradingStatus: 'PENDING',
      ),
    );
  }

  @override
  Future<Result<void>> saveDescriptiveDraft(String questionId) async =>
      const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWrittenExamRepository implements WrittenExamRepository {
  @override
  Future<Result<List<WrittenAnswerImage>>> getImages() async =>
      const Success([]);

  @override
  Future<Result<void>> clearStoredImages() async => const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('SubmitSavedExamAnswersUseCase flushes, uploads, finalizes, and clears',
      () async {
    final flusher = _RecordingFlusher();
    const exam = CurrentExam(
      examId: 'exam-1',
      examName: 'Test Exam',
      batchName: 'Batch',
      batchStatus: 'ACTIVE',
      batchId: 'batch-1',
      totalQuestions: 1,
      durationMinutes: 60,
      window: ExamWindow(
        startTime: null,
        examEndTime: null,
        submitEndTime: null,
        bufferTimeMinutes: 0,
        canAccessQuestions: true,
        canSubmit: true,
        remainingExamMinutes: 30,
        remainingSubmitMinutes: 30,
      ),
      questions: [],
    );
    final submittedAt = DateTime(2026, 7, 19, 19, 0);
    final receipt = SubmissionReceipt(
      submissionId: 'sub-1',
      submittedAt: submittedAt,
      message: 'ok',
    );
    final repository = _FakeExamRepository(exam, receipt);
    final writtenRepo = _FakeWrittenExamRepository();
    final uploadUseCase =
        UploadPendingWrittenImagesUseCase(repository, writtenRepo);

    final useCase = SubmitSavedExamAnswersUseCase(
      flusher,
      repository,
      uploadUseCase,
      FinalizeExamUseCase(repository),
      ClearExamLocalDataUseCase(repository, writtenRepo),
    );

    final result = await useCase(ExamPhase.mcq);

    expect(result, isA<Success<SubmissionReceipt>>());
    expect(flusher.flushedPhase, ExamPhase.mcq);
    expect(repository.refreshCalls, 1);
    expect(repository.finalizeCalls, 1);
    expect(repository.clearCalls, 1);
  });

  test('SubmitSavedExamAnswersUseCase returns error when finalize fails', () async {
    final flusher = _RecordingFlusher();
    final repository = _FailingFinalizeRepository();
    final writtenRepo = _FakeWrittenExamRepository();
    final uploadUseCase =
        UploadPendingWrittenImagesUseCase(repository, writtenRepo);

    final useCase = SubmitSavedExamAnswersUseCase(
      flusher,
      repository,
      uploadUseCase,
      FinalizeExamUseCase(repository),
      ClearExamLocalDataUseCase(repository, writtenRepo),
    );

    final result = await useCase(ExamPhase.fillBlank);

    expect(result, isA<ErrorResult<SubmissionReceipt>>());
    expect(flusher.flushedPhase, ExamPhase.fillBlank);
    expect(repository.clearCalls, 0);
  });
}

class _FailingFinalizeRepository implements ExamRepository {
  int clearCalls = 0;
  int refreshCalls = 0;

  @override
  Future<Result<CurrentExam>> refreshCurrentExam() async {
    refreshCalls += 1;
    return const Success(
      CurrentExam(
        examId: 'exam-1',
        examName: 'Test Exam',
        batchName: 'Batch',
        batchStatus: 'ACTIVE',
        batchId: 'batch-1',
        totalQuestions: 1,
        durationMinutes: 60,
        window: ExamWindow(
          startTime: null,
          examEndTime: null,
          submitEndTime: null,
          bufferTimeMinutes: 0,
          canAccessQuestions: true,
          canSubmit: true,
          remainingExamMinutes: 30,
          remainingSubmitMinutes: 30,
        ),
        questions: [],
      ),
    );
  }

  @override
  Future<Result<SubmissionReceipt>> finalizeExam(CurrentExam? exam) async {
    return const ErrorResult(ValidationFailure('finalize failed'));
  }

  @override
  Future<Result<void>> clearLocalExamData() async {
    clearCalls += 1;
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
