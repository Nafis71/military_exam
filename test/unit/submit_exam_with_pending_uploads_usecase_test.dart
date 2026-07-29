import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/domain/repositories/exam_repository.dart';
import 'package:military_exam/features/exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/finalize_exam_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/submit_exam_with_pending_uploads_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/upload_pending_written_images_usecase.dart';
import 'package:military_exam/features/written_exam/domain/repositories/written_exam_repository.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

import '../helpers/demo_exam_test_support.dart';

void main() {
  test('SubmitExamWithPendingUploadsUseCase returns error when image file missing',
      () async {
    final examRepo = _FakeExamRepository();
    final writtenRepo = _FakeWrittenExamRepository(
      images: [
        WrittenAnswerImage(
          localId: '1',
          localPath: '/tmp/missing.jpg',
          questionId: 'q1',
        ),
      ],
    );
    final uploadUseCase = UploadPendingWrittenImagesUseCase(
      examRepo,
      writtenRepo,
      createExamRunContext(),
    );

    final useCase = SubmitExamWithPendingUploadsUseCase(
      examRepo,
      uploadUseCase,
      FinalizeExamUseCase(examRepo, writtenRepo),
      ClearExamLocalDataUseCase(examRepo, writtenRepo),
    );

    final result = await useCase();

    expect(result, isA<ErrorResult>());
    expect(examRepo.uploadCalls, 0);
    expect(examRepo.finalizeCalls, 0);
    expect(examRepo.clearCalls, 0);
  });

  test('SubmitExamWithPendingUploadsUseCase uploads then finalizes and clears',
      () async {
    final tempFile = File(
      '${Directory.systemTemp.path}/pending_upload_test_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes([1, 2, 3]);

    final examRepo = _FakeExamRepository();
    final writtenRepo = _FakeWrittenExamRepository(
      images: [
        WrittenAnswerImage(
          localId: '1',
          localPath: tempFile.path,
          questionId: 'q1',
        ),
      ],
    );
    final uploadUseCase = UploadPendingWrittenImagesUseCase(
      examRepo,
      writtenRepo,
      createExamRunContext(),
    );

    final useCase = SubmitExamWithPendingUploadsUseCase(
      examRepo,
      uploadUseCase,
      FinalizeExamUseCase(examRepo, writtenRepo),
      ClearExamLocalDataUseCase(examRepo, writtenRepo),
    );

    final result = await useCase();

    expect(result, isA<Success>());
    expect(examRepo.uploadCalls, 1);
    expect(writtenRepo.markCalls, 1);
    expect(examRepo.draftCalls, 1);
    expect(examRepo.refreshCalls, 1);
    expect(examRepo.finalizeCalls, 1);
    expect(examRepo.clearCalls, 1);
    expect(writtenRepo.clearCalls, 1);

    await tempFile.delete();
  });

  test('SubmitExamWithPendingUploadsUseCase finalizes when no pending uploads',
      () async {
    final examRepo = _FakeExamRepository();
    final writtenRepo = _FakeWrittenExamRepository(images: const []);
    final uploadUseCase = UploadPendingWrittenImagesUseCase(
      examRepo,
      writtenRepo,
      createExamRunContext(),
    );

    final useCase = SubmitExamWithPendingUploadsUseCase(
      examRepo,
      uploadUseCase,
      FinalizeExamUseCase(examRepo, writtenRepo),
      ClearExamLocalDataUseCase(examRepo, writtenRepo),
    );

    final result = await useCase();

    expect(result, isA<Success>());
    expect(examRepo.uploadCalls, 0);
    expect(examRepo.refreshCalls, 1);
    expect(examRepo.finalizeCalls, 1);
    expect(examRepo.clearCalls, 1);
    expect(writtenRepo.clearCalls, 1);
  });
}

class _FakeExamRepository implements ExamRepository {
  int uploadCalls = 0;
  int finalizeCalls = 0;
  int clearCalls = 0;
  int refreshCalls = 0;
  int draftCalls = 0;

  @override
  Future<Result<CurrentExam>> refreshCurrentExam() async {
    refreshCalls++;
    return Success(
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
  Future<Result<SubmissionReceipt>> finalizeExam(
    CurrentExam? currentExam, {
    Set<String> questionIdsWithImages = const {},
  }) async {
    finalizeCalls++;
    return Success(
      SubmissionReceipt(
        submissionId: 'sub-1',
        submittedAt: DateTime(2026, 7, 20, 12),
        message: 'ok',
      ),
    );
  }

  @override
  Future<Result<void>> clearLocalExamData() async {
    clearCalls++;
    return const Success(null);
  }

  @override
  Future<Result<void>> saveDescriptiveDraft(String questionId) async {
    draftCalls++;
    return const Success(null);
  }

  @override
  Future<Result<WrittenImageUploadResult>> uploadDescriptiveAnswerImage({
    required String questionId,
    required String filePath,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    uploadCalls++;
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
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeWrittenExamRepository implements WrittenExamRepository {
  _FakeWrittenExamRepository({required this.images});

  final List<WrittenAnswerImage> images;
  int markCalls = 0;
  int clearCalls = 0;

  @override
  Future<Result<List<WrittenAnswerImage>>> getImages() async => Success(images);

  @override
  Future<Result<void>> markImageUploaded({
    required String localId,
    required String remoteId,
  }) async {
    markCalls++;
    return const Success(null);
  }

  @override
  Future<Result<void>> clearStoredImages() async {
    clearCalls++;
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
