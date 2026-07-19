import '../../../../shared/domain/entities/exam_entities.dart';

class ExamQuestionOptionModel extends ExamQuestionOption {
  const ExamQuestionOptionModel({
    required super.key,
    required super.text,
  });

  factory ExamQuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return ExamQuestionOptionModel(
      key: json['option_key'] as String? ?? json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'option_key': key,
        'text': text,
      };
}
