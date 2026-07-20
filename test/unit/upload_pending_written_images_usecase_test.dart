import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/errors/failure.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/domain/repositories/exam_repository.dart';
import 'package:military_exam/features/exam_session/domain/usecases/upload_pending_written_images_usecase.dart';
import 'package:military_exam/features/written_exam/domain/repositories/written_exam_repository.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  test('UploadPendingWrittenImagesUseCase skips already uploaded images',
      () async {
    final examRepo = _FakeExamRepository();
    final writtenRepo = _FakeWrittenExamRepository(
      images: const [
        WrittenAnswerImage(
          localId: '1',
          localPath: '/tmp/uploaded.jpg',
          questionId: 'q1',
          uploadStatus: ImageUploadStatus.uploaded,
          remoteId: 'remote-1',
        ),
      ],
    );
    final useCase = UploadPendingWrittenImagesUseCase(examRepo, writtenRepo);

    final result = await useCase();

    expect(result, isA<Success<void>>());
    expect(examRepo.uploadCalls, 0);
    expect(writtenRepo.markCalls, 0);
    expect(examRepo.draftCalls, 0);
  });

  test('UploadPendingWrittenImagesUseCase uploads pending images and saves drafts',
      () async {
    final tempFile = File(
      '${Directory.systemTemp.path}/upload_pending_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
    final useCase = UploadPendingWrittenImagesUseCase(examRepo, writtenRepo);

    final result = await useCase();

    expect(result, isA<Success<void>>());
    expect(examRepo.uploadCalls, 1);
    expect(writtenRepo.markCalls, 1);
    expect(examRepo.draftCalls, 1);

    await tempFile.delete();
  });

  test('UploadPendingWrittenImagesUseCase returns error when file is missing',
      () async {
    final examRepo = _FakeExamRepository();
    final writtenRepo = _FakeWrittenExamRepository(
      images: const [
        WrittenAnswerImage(
          localId: '1',
          localPath: '/tmp/missing.jpg',
          questionId: 'q1',
        ),
      ],
    );
    final useCase = UploadPendingWrittenImagesUseCase(examRepo, writtenRepo);

    final result = await useCase();

    expect(result, isA<ErrorResult<void>>());
    expect(examRepo.uploadCalls, 0);
  });
}

class _FakeExamRepository implements ExamRepository {
  int uploadCalls = 0;
  int draftCalls = 0;

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

class _FakeWrittenExamRepository implements WrittenExamRepository {
  _FakeWrittenExamRepository({required this.images});

  final List<WrittenAnswerImage> images;
  int markCalls = 0;

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
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
