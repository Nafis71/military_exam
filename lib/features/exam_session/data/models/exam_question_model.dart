import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import 'exam_question_option_model.dart';

class ExamQuestionModel extends ExamQuestion {
  const ExamQuestionModel({
    required super.id,
    required super.questionNumber,
    required super.type,
    required super.text,
    required super.mark,
    super.options = const [],
  });

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>?;
    return ExamQuestionModel(
      id: json['id'] as String,
      questionNumber: json['question_number'] as int? ?? 0,
      type: _parseType(json['question_type'] as String?),
      text: json['question_text'] as String? ?? '',
      mark: json['mark'] as int? ?? 1,
      options: optionsJson
              ?.map(
                (e) => ExamQuestionOptionModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }

  static ExamQuestionType _parseType(String? raw) {
    return switch (raw?.toUpperCase()) {
      'MCQ' => ExamQuestionType.mcq,
      'FILL_IN_BLANK' => ExamQuestionType.fillInBlank,
      'DESCRIPTIVE' => ExamQuestionType.descriptive,
      _ => ExamQuestionType.mcq,
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question_number': questionNumber,
        'question_type': type.name.toUpperCase(),
        'question_text': text,
        'mark': mark,
        if (options.isNotEmpty)
          'options': options
              .map(
                (o) => ExamQuestionOptionModel(key: o.key, text: o.text).toJson(),
              )
              .toList(),
      };
}
