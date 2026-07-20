import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/domain/repositories/exam_repository.dart';
import 'package:military_exam/features/fill_blank_exam/domain/usecases/get_fill_blank_progress_usecase.dart';
import 'package:military_exam/features/fill_blank_exam/domain/usecases/get_fill_blank_questions_usecase.dart';
import 'package:military_exam/features/fill_blank_exam/domain/usecases/save_fill_blank_answer_usecase.dart';
import 'package:military_exam/features/fill_blank_exam/presentation/controllers/fill_blank_exam_controller.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

void main() {
  late _TrackingExamRepository repository;
  late FillBlankExamController controller;

  setUp(() {
    Get.testMode = true;
    repository = _TrackingExamRepository();
    controller = FillBlankExamController(
      getFillBlankQuestionsUseCase: GetFillBlankQuestionsUseCase(repository),
      saveFillBlankAnswerUseCase: SaveFillBlankAnswerUseCase(repository),
      getFillBlankProgressUseCase: GetFillBlankProgressUseCase(repository),
    );
    controller.questions.assignAll([
      const FillBlankQuestion(
        id: 'q1',
        question: 'Fill 1',
        index: 1,
        total: 2,
      ),
      const FillBlankQuestion(
        id: 'q2',
        question: 'Fill 2',
        index: 2,
        total: 2,
      ),
    ]);
  });

  tearDown(() {
    Get.reset();
  });

  test('skipCurrentQuestion advances without saving', () {
    controller.answerText.value = 'draft answer';

    controller.skipCurrentQuestion();

    expect(controller.currentIndex.value, 1);
    expect(controller.answerText.value, '');
    expect(repository.saveFillBlankCallCount, 0);
    expect(controller.answers.containsKey('q1'), isFalse);
  });

  test('skipCurrentQuestion preserves saved answer in map', () {
    controller.answers['q1'] = 'saved';
    controller.answerText.value = 'unsaved edit';

    controller.skipCurrentQuestion();

    expect(controller.currentIndex.value, 1);
    expect(controller.answers['q1'], 'saved');
    expect(repository.saveFillBlankCallCount, 0);
  });

  test('skipCurrentQuestion does nothing on last question', () {
    controller.currentIndex.value = 1;
    controller.answerText.value = 'answer';

    controller.skipCurrentQuestion();

    expect(controller.currentIndex.value, 1);
    expect(repository.saveFillBlankCallCount, 0);
  });
}

class _TrackingExamRepository implements ExamRepository {
  int saveFillBlankCallCount = 0;

  @override
  Future<Result<FillBlankAnswer>> saveFillBlankAnswerLocally(
    FillBlankAnswer answer,
  ) async {
    saveFillBlankCallCount++;
    return Success(answer);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
