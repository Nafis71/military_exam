import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
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
import 'package:military_exam/features/exam_session/presentation/controllers/exam_session_controller.dart';
import 'package:military_exam/features/written_exam/domain/repositories/written_exam_repository.dart';
import 'package:military_exam/features/written_exam/domain/usecases/add_written_image_usecase.dart';
import 'package:military_exam/features/written_exam/domain/usecases/delete_written_image_usecase.dart';
import 'package:military_exam/features/written_exam/domain/usecases/get_written_images_usecase.dart';
import 'package:military_exam/features/written_exam/domain/usecases/save_descriptive_draft_usecase.dart';
import 'package:military_exam/features/written_exam/domain/usecases/upload_descriptive_answer_image_usecase.dart';
import 'package:military_exam/features/written_exam/presentation/controllers/written_exam_controller.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  late ExamSessionController sessionController;
  late WrittenExamController controller;

  setUp(() {
    Get.testMode = true;
    final examRepo = _StubExamRepository();
    final writtenRepo = _StubWrittenExamRepository();
    sessionController = ExamSessionController(
      startExamSessionUseCase: StartExamSessionUseCase(examRepo),
      getCurrentExamUseCase: GetCurrentExamUseCase(examRepo),
      getExamTimerUseCase: GetExamTimerUseCase(examRepo),
      submitSavedExamAnswersUseCase: SubmitSavedExamAnswersUseCase(
        _StubPendingExamAnswersFlusher(),
        GetCurrentExamUseCase(examRepo),
        FinalizeExamUseCase(examRepo),
        ClearExamLocalDataUseCase(examRepo),
      ),
      finalizeExamUseCase: FinalizeExamUseCase(examRepo),
      clearExamLocalDataUseCase: ClearExamLocalDataUseCase(examRepo),
      finishExamUseCase: FinishExamUseCase(examRepo),
      lockExamSessionUseCase: LockExamSessionUseCase(examRepo),
      reportSecurityViolationUseCase: ReportSecurityViolationUseCase(
        examRepo,
        _StubPenaltyRepository(),
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
    expect(controller.currentQuestionHasUploadedImage, isFalse);
  });
}

class _StubExamRepository implements ExamRepository {
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
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
