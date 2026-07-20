import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/domain/repositories/exam_repository.dart';
import 'package:military_exam/features/mcq_exam/domain/usecases/get_current_mcq_progress_usecase.dart';
import 'package:military_exam/features/mcq_exam/domain/usecases/get_mcq_questions_usecase.dart';
import 'package:military_exam/features/mcq_exam/domain/usecases/save_mcq_answer_usecase.dart';
import 'package:military_exam/features/mcq_exam/presentation/controllers/mcq_exam_controller.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

void main() {
  late _TrackingExamRepository repository;
  late McqExamController controller;

  setUp(() {
    Get.testMode = true;
    repository = _TrackingExamRepository();
    controller = McqExamController(
      getMcqQuestionsUseCase: GetMcqQuestionsUseCase(repository),
      saveMcqAnswerUseCase: SaveMcqAnswerUseCase(repository),
      getCurrentMcqProgressUseCase: GetCurrentMcqProgressUseCase(repository),
    );
    controller.questions.assignAll([
      const McqQuestion(
        id: 'q1',
        question: 'Question 1',
        options: [McqOption(id: 'a', label: 'A')],
        index: 1,
        total: 2,
      ),
      const McqQuestion(
        id: 'q2',
        question: 'Question 2',
        options: [McqOption(id: 'b', label: 'B')],
        index: 2,
        total: 2,
      ),
    ]);
  });

  tearDown(() {
    Get.reset();
  });

  test('skipCurrentQuestion advances without saving', () {
    controller.selectedOptionId.value = 'a';

    controller.skipCurrentQuestion();

    expect(controller.currentIndex.value, 1);
    expect(controller.selectedOptionId.value, isNull);
    expect(repository.saveMcqCallCount, 0);
    expect(controller.answers.containsKey('q1'), isFalse);
  });

  test('skipCurrentQuestion does not clear previously saved answer on revisit',
      () {
    controller.answers['q1'] = 'a';
    controller.selectedOptionId.value = 'a';
    controller.currentIndex.value = 1;
    controller.goToPrevious();
    controller.selectedOptionId.value = 'a';

    controller.skipCurrentQuestion();

    expect(controller.currentIndex.value, 1);
    expect(controller.answers['q1'], 'a');
    expect(repository.saveMcqCallCount, 0);
  });

  test('skipCurrentQuestion does nothing on last question', () {
    controller.currentIndex.value = 1;
    controller.selectedOptionId.value = 'b';

    controller.skipCurrentQuestion();

    expect(controller.currentIndex.value, 1);
    expect(repository.saveMcqCallCount, 0);
  });
}

class _TrackingExamRepository implements ExamRepository {
  int saveMcqCallCount = 0;

  @override
  Future<Result<McqAnswer>> saveMcqAnswerLocally(McqAnswer answer) async {
    saveMcqCallCount++;
    return Success(answer);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
