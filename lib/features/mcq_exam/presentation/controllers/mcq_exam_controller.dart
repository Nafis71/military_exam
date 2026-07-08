import 'package:get/get.dart';

import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../domain/usecases/get_current_mcq_progress_usecase.dart';
import '../../domain/usecases/get_mcq_questions_usecase.dart';
import '../../domain/usecases/submit_mcq_answer_usecase.dart';

class McqExamController extends GetxController {
  McqExamController({
    required GetMcqQuestionsUseCase getMcqQuestionsUseCase,
    required SubmitMcqAnswerUseCase submitMcqAnswerUseCase,
    required GetCurrentMcqProgressUseCase getCurrentMcqProgressUseCase,
  })  : _getMcqQuestionsUseCase = getMcqQuestionsUseCase,
        _submitMcqAnswerUseCase = submitMcqAnswerUseCase,
        _getCurrentMcqProgressUseCase = getCurrentMcqProgressUseCase;

  final GetMcqQuestionsUseCase _getMcqQuestionsUseCase;
  final SubmitMcqAnswerUseCase _submitMcqAnswerUseCase;
  final GetCurrentMcqProgressUseCase _getCurrentMcqProgressUseCase;

  final questions = <McqQuestion>[].obs;
  final currentIndex = 0.obs;
  final selectedOptionId = RxnString();
  final answers = <String, String>{}.obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();

  McqQuestion? get currentQuestion {
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

    final questionsResult = await _getMcqQuestionsUseCase(sessionId);
    final progressResult = await _getCurrentMcqProgressUseCase(sessionId);

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
      selectedOptionId.value = null;
      return;
    }

    final firstUnanswered = questions.indexWhere(
      (q) => !progress.containsKey(q.id),
    );
    currentIndex.value = firstUnanswered >= 0 ? firstUnanswered : 0;
    _syncSelectionForCurrent();
  }

  void selectOption(String optionId) {
    selectedOptionId.value = optionId;
  }

  Future<void> submitCurrentAnswer({bool advance = true}) async {
    final question = currentQuestion;
    final optionId = selectedOptionId.value;
    if (question == null || optionId == null) return;

    isSubmitting.value = true;
    final answer = McqAnswer(
      questionId: question.id,
      selectedOptionId: optionId,
      isFinal: isLastQuestion,
    );

    final result = await _submitMcqAnswerUseCase(answer);
    isSubmitting.value = false;

    switch (result) {
      case Success():
        answers[question.id] = optionId;
        if (advance && !isLastQuestion) {
          currentIndex.value += 1;
          _syncSelectionForCurrent();
        }
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  void goToPrevious() {
    if (currentIndex.value <= 0) return;
    currentIndex.value -= 1;
    _syncSelectionForCurrent();
  }

  void _syncSelectionForCurrent() {
    final question = currentQuestion;
    selectedOptionId.value =
        question != null ? answers[question.id] : null;
  }
}
