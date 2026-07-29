import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';

abstract final class FinalizePayloadBuilder {
  static List<ExamAnswerDraft> build({
    required Map<String, ExamAnswerDraft> drafts,
    List<ExamQuestion>? orderedQuestions,
    Set<String> questionIdsWithImages = const {},
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

    return entries
        .where(
          (draft) => shouldIncludeDraft(
            draft,
            questionIdsWithImages: questionIdsWithImages,
          ),
        )
        .toList();
  }

  static bool shouldIncludeDraft(
    ExamAnswerDraft draft, {
    Set<String> questionIdsWithImages = const {},
  }) =>
      _shouldInclude(draft, questionIdsWithImages: questionIdsWithImages);

  static bool shouldIncludeDraftForRecovery(
    ExamAnswerDraft draft, {
    required Set<String> questionIdsWithImages,
  }) =>
      _shouldInclude(draft, questionIdsWithImages: questionIdsWithImages);

  static bool _shouldInclude(
    ExamAnswerDraft draft, {
    required Set<String> questionIdsWithImages,
  }) {
    return switch (draft.type) {
      ExamQuestionType.mcq =>
        draft.optionKey != null && draft.optionKey!.isNotEmpty,
      ExamQuestionType.fillInBlank =>
        draft.answerText != null && draft.answerText!.trim().isNotEmpty,
      ExamQuestionType.descriptive =>
        questionIdsWithImages.contains(draft.questionId),
    };
  }
}
