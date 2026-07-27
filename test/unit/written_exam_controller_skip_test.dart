import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/core/services/exam_run_context.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/domain/ports/pending_exam_answers_flusher.dart';
import 'package:military_exam/features/exam_session/domain/repositories/exam_repository.dart';
import 'package:military_exam/features/exam_session/domain/repositories/penalty_repository.dart';
import 'package:military_exam/features/exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/finalize_exam_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/finish_exam_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/get_current_exam_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/get_exam_timer_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/lock_exam_session_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/report_security_violation_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/start_exam_session_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/submit_saved_exam_answers_usecase.dart';
import 'package:military_exam/features/exam_session/domain/usecases/upload_pending_written_images_usecase.dart';
import 'package:military_exam/features/exam_session/presentation/controllers/exam_session_controller.dart';
import 'package:military_exam/features/written_exam/domain/repositories/written_exam_repository.dart';
import 'package:military_exam/features/written_exam/domain/usecases/add_written_image_usecase.dart';
import 'package:military_exam/features/written_exam/domain/usecases/delete_written_image_usecase.dart';
import 'package:military_exam/features/written_exam/domain/usecases/get_written_images_usecase.dart';
import 'package:military_exam/features/written_exam/domain/usecases/mark_written_image_uploaded_usecase.dart';
import 'package:military_exam/features/written_exam/domain/usecases/save_descriptive_draft_usecase.dart';
import 'package:military_exam/features/written_exam/domain/usecases/upload_descriptive_answer_image_usecase.dart';
import 'package:military_exam/features/written_exam/presentation/controllers/written_exam_controller.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  late ExamSessionController sessionController;
  late WrittenExamController controller;
  late _StubWrittenExamRepository writtenRepo;

  setUp(() {
    Get.testMode = true;
    final examRepo = _StubExamRepository();
    writtenRepo = _StubWrittenExamRepository();
    final uploadUseCase = UploadPendingWrittenImagesUseCase(examRepo, writtenRepo);
    sessionController = ExamSessionController(
      startExamSessionUseCase: StartExamSessionUseCase(examRepo),
      getCurrentExamUseCase: GetCurrentExamUseCase(examRepo),
      getExamTimerUseCase: GetExamTimerUseCase(examRepo),
      submitSavedExamAnswersUseCase: SubmitSavedExamAnswersUseCase(
        _StubPendingExamAnswersFlusher(),
        examRepo,
        uploadUseCase,
        FinalizeExamUseCase(examRepo),
        ClearExamLocalDataUseCase(examRepo, writtenRepo),
      ),
      uploadPendingWrittenImagesUseCase: uploadUseCase,
      finalizeExamUseCase: FinalizeExamUseCase(examRepo),
      clearExamLocalDataUseCase: ClearExamLocalDataUseCase(examRepo, writtenRepo),
      finishExamUseCase: FinishExamUseCase(examRepo),
      lockExamSessionUseCase: LockExamSessionUseCase(examRepo),
      reportSecurityViolationUseCase: ReportSecurityViolationUseCase(
        examRepo,
        _StubPenaltyRepository(),
        ExamRunContext(),
      ),
    );
    sessionController.descriptiveQuestions.assignAll([
      const WrittenQuestion(id: 'w1', index: 1, total: 2, text: 'Q1'),
      const WrittenQuestion(id: 'w2', index: 2, total: 2, text: 'Q2'),
    ]);
    controller = WrittenExamController(
      sessionController: sessionController,
      addWrittenImageUseCase: AddWrittenImageUseCase(writtenRepo),
      deleteWrittenImageUseCase: DeleteWrittenImageUseCase(writtenRepo),
      getWrittenImagesUseCase: GetWrittenImagesUseCase(writtenRepo),
      uploadDescriptiveAnswerImageUseCase:
          UploadDescriptiveAnswerImageUseCase(examRepo),
      saveDescriptiveDraftUseCase: SaveDescriptiveDraftUseCase(examRepo),
      markWrittenImageUploadedUseCase:
          MarkWrittenImageUploadedUseCase(writtenRepo),
    );
  });

  tearDown(() {
    Get.reset();
  });

  test('skipCurrentQuestion advances and clears error', () {
    controller.errorMessage.value = 'error';

    controller.skipCurrentQuestion();

    expect(controller.currentIndex.value, 1);
    expect(controller.errorMessage.value, isNull);
  });

  test('skipCurrentQuestion does nothing on last question', () {
    controller.currentIndex.value = 1;

    controller.skipCurrentQuestion();

    expect(controller.currentIndex.value, 1);
  });

  test('canSubmit is true with partial uploaded images', () {
    controller.images.add(
      const WrittenAnswerImage(
        localId: '1',
        localPath: '/tmp/a.jpg',
        questionId: 'w1',
        uploadStatus: ImageUploadStatus.uploaded,
      ),
    );
    controller.currentIndex.value = 1;

    expect(controller.canSubmit, isTrue);
    expect(controller.currentQuestionHasStagedImage, isFalse);
  });

  test('goToNext advances when current question has localOnly image', () async {
    controller.images.add(
      const WrittenAnswerImage(
        localId: '1',
        localPath: '/tmp/a.jpg',
        questionId: 'w1',
        uploadStatus: ImageUploadStatus.localOnly,
      ),
    );

    await controller.goToNext();

    expect(controller.currentIndex.value, 1);
    expect(controller.errorMessage.value, isNull);
  });

  test('goToNext blocks when current question has no staged image', () async {
    await controller.goToNext();

    expect(controller.currentIndex.value, 0);
    expect(
      controller.errorMessage.value,
      AppStrings.writtenExamRequireUploadedImage,
    );
  });
}

class _StubExamRepository implements ExamRepository {
  @override
  Future<Result<CurrentExam>> refreshCurrentExam() async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> saveDescriptiveDraft(String questionId) async =>
      const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StubPenaltyRepository implements PenaltyRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StubPendingExamAnswersFlusher implements PendingExamAnswersFlusher {
  @override
  Future<void> flush(ExamPhase phase) async {}
}

class _StubWrittenExamRepository implements WrittenExamRepository {
  @override
  Future<Result<List<WrittenAnswerImage>>> getImages() async =>
      const Success([]);

  @override
  Future<Result<void>> markImageUploaded({
    required String localId,
    required String remoteId,
  }) async =>
      const Success(null);

  @override
  Future<Result<void>> clearStoredImages() async => const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
