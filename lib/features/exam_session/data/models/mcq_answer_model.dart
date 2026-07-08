import '../../../../shared/domain/entities/exam_entities.dart';

class McqAnswerModel {
  const McqAnswerModel({
    required this.questionId,
    required this.selectedOptionId,
    required this.isFinal,
  });

  final String questionId;
  final String selectedOptionId;
  final bool isFinal;

  factory McqAnswerModel.fromEntity(McqAnswer entity) {
    return McqAnswerModel(
      questionId: entity.questionId,
      selectedOptionId: entity.selectedOptionId,
      isFinal: entity.isFinal,
    );
  }

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
        'is_final': isFinal,
      };

  McqAnswer toEntity() {
    return McqAnswer(
      questionId: questionId,
      selectedOptionId: selectedOptionId,
      isFinal: isFinal,
    );
  }
}
