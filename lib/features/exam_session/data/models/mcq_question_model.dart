import '../../../../shared/domain/entities/exam_entities.dart';
import 'mcq_option_model.dart';

class McqQuestionModel {
  const McqQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.index,
    required this.total,
  });

  final String id;
  final String question;
  final List<McqOptionModel> options;
  final int index;
  final int total;

  factory McqQuestionModel.fromJson(Map<String, dynamic> json) {
    return McqQuestionModel(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => McqOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      index: json['index'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'index': index,
        'total': total,
      };

  McqQuestion toEntity() {
    return McqQuestion(
      id: id,
      question: question,
      options: options.map((o) => o.toEntity()).toList(),
      index: index,
      total: total,
    );
  }
}
