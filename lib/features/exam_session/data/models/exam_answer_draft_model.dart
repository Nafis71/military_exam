import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';

class ExamAnswerDraftModel extends ExamAnswerDraft {
  const ExamAnswerDraftModel({
    required super.questionId,
    required super.type,
    super.optionKey,
    super.answerText,
    super.questionNumber = 0,
  });

  factory ExamAnswerDraftModel.fromJson(
    Map<String, dynamic> json, {
    String? questionId,
  }) {
    final resolvedQuestionId = json['question_id'] as String? ??
        json['questionId'] as String? ??
        questionId;
    if (resolvedQuestionId == null || resolvedQuestionId.isEmpty) {
      throw const FormatException('Exam answer draft missing question_id');
    }

    return ExamAnswerDraftModel(
      questionId: resolvedQuestionId,
      type: _parseType(json['type'] as String?),
      optionKey: json['option_key'] as String?,
      answerText: json['answer_text'] as String?,
      questionNumber: json['question_number'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'type': type.name,
        if (optionKey != null) 'option_key': optionKey,
        if (answerText != null) 'answer_text': answerText,
        'question_number': questionNumber,
      };

  static ExamQuestionType _parseType(String? raw) {
    return ExamQuestionType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => ExamQuestionType.mcq,
    );
  }
}
