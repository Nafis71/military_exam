import '../../../../shared/domain/entities/exam_entities.dart';

class FillBlankAnswerModel extends FillBlankAnswer {
  const FillBlankAnswerModel({
    required super.questionId,
    required super.text,
    required super.isFinal,
  });

  factory FillBlankAnswerModel.fromEntity(FillBlankAnswer answer) {
    return FillBlankAnswerModel(
      questionId: answer.questionId,
      text: answer.text,
      isFinal: answer.isFinal,
    );
  }

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'text': text,
        'is_final': isFinal,
      };
}
