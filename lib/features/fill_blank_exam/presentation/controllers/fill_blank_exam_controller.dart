import 'package:get/get.dart';

import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../domain/usecases/get_fill_blank_progress_usecase.dart';
import '../../domain/usecases/get_fill_blank_questions_usecase.dart';
import '../../domain/usecases/save_fill_blank_answer_usecase.dart';

class FillBlankExamController extends GetxController {
  FillBlankExamController({
    required GetFillBlankQuestionsUseCase getFillBlankQuestionsUseCase,
    required SaveFillBlankAnswerUseCase saveFillBlankAnswerUseCase,
    required GetFillBlankProgressUseCase getFillBlankProgressUseCase,
  })  : _getFillBlankQuestionsUseCase = getFillBlankQuestionsUseCase,
        _saveFillBlankAnswerUseCase = saveFillBlankAnswerUseCase,
        _getFillBlankProgressUseCase = getFillBlankProgressUseCase;

  final GetFillBlankQuestionsUseCase _getFillBlankQuestionsUseCase;
  final SaveFillBlankAnswerUseCase _saveFillBlankAnswerUseCase;
  final GetFillBlankProgressUseCase _getFillBlankProgressUseCase;

  final questions = <FillBlankQuestion>[].obs;
  final currentIndex = 0.obs;
  final answerText = ''.obs;
  final answers = <String, String>{}.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  FillBlankQuestion? get currentQuestion {
    if (questions.isEmpty || currentIndex.value >= questions.length) {
      return null;
    }
    return questions[currentIndex.value];
  }

  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex.value >= questions.length - 1;

  Future<void> loadQuestions(String sessionId) async {
    isLoading.value = true;
    errorMessage.value = null;

    final questionsResult = await _getFillBlankQuestionsUseCase(sessionId);
    final progressResult = await _getFillBlankProgressUseCase(sessionId);

    isLoading.value = false;

    switch (questionsResult) {
      case Success(:final data):
        questions.assignAll(data);
        _restoreProgress(progressResult.dataOrNull ?? {});
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  void _restoreProgress(Map<String, String> progress) {
    answers.assignAll(Map<String, String>.from(progress));
    if (progress.isEmpty) {
      currentIndex.value = 0;
      answerText.value = '';
      return;
    }

    final firstUnanswered = questions.indexWhere(
      (q) => !progress.containsKey(q.id),
    );
    currentIndex.value = firstUnanswered >= 0 ? firstUnanswered : 0;
    _syncAnswerForCurrent();
  }

  void updateAnswer(String text) {
    answerText.value = text;
  }

  Future<void> saveCurrentAnswer({bool advance = true}) async {
    final question = currentQuestion;
    if (question == null) return;

    isSaving.value = true;
    final answer = FillBlankAnswer(
      questionId: question.id,
      text: answerText.value.trim(),
      isFinal: isLastQuestion,
    );

    final result = await _saveFillBlankAnswerUseCase(answer);
    isSaving.value = false;

    switch (result) {
      case Success():
        answers[question.id] = answer.text;
        if (advance && !isLastQuestion) {
          currentIndex.value += 1;
          _syncAnswerForCurrent();
        }
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  void goToPrevious() {
    if (currentIndex.value <= 0) return;
    currentIndex.value -= 1;
    _syncAnswerForCurrent();
  }

  void _syncAnswerForCurrent() {
    final question = currentQuestion;
    answerText.value = question != null ? (answers[question.id] ?? '') : '';
  }
}
