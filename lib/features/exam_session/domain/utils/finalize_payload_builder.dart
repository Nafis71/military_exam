import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';

abstract final class FinalizePayloadBuilder {
  static List<ExamAnswerDraft> build({
    required Map<String, ExamAnswerDraft> drafts,
    List<ExamQuestion>? orderedQuestions,
  }) {
    final entries = drafts.values.toList();
    if (orderedQuestions != null && orderedQuestions.isNotEmpty) {
      final order = {
        for (final q in orderedQuestions) q.id: q.questionNumber,
      };
      entries.sort(
        (a, b) =>
            (order[a.questionId] ?? 0).compareTo(order[b.questionId] ?? 0),
      );
    }

    return entries.where(_shouldInclude).toList();
  }

  static bool _shouldInclude(ExamAnswerDraft draft) {
    return switch (draft.type) {
      ExamQuestionType.mcq =>
        draft.optionKey != null && draft.optionKey!.isNotEmpty,
      ExamQuestionType.fillInBlank =>
        draft.answerText != null && draft.answerText!.trim().isNotEmpty,
      ExamQuestionType.descriptive => true,
    };
  }
}
