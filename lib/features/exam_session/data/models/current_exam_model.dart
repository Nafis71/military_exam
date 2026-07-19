import '../../../../shared/domain/entities/exam_entities.dart';
import 'exam_question_model.dart';
import 'exam_window_model.dart';

class CurrentExamModel extends CurrentExam {
  const CurrentExamModel({
    required super.examId,
    required super.examName,
    required super.batchName,
    required super.batchStatus,
    required super.batchId,
    required super.totalQuestions,
    required super.durationMinutes,
    required super.window,
    required super.questions,
  });

  factory CurrentExamModel.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    return CurrentExamModel(
      examId: json['exam_id'] as String? ?? '',
      examName: json['exam_name'] as String? ?? '',
      batchName: json['batch_name'] as String? ?? '',
      batchStatus: json['batch_status'] as String? ?? '',
      batchId: json['batch_id'] as String? ?? '',
      totalQuestions: json['total_questions'] as int? ?? 0,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      window: ExamWindowModel.fromJson(
        json['window'] as Map<String, dynamic>? ?? {},
      ),
      questions: questionsJson
          .map(
            (e) => ExamQuestionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'exam_id': examId,
        'exam_name': examName,
        'batch_name': batchName,
        'batch_status': batchStatus,
        'batch_id': batchId,
        'total_questions': totalQuestions,
        'duration_minutes': durationMinutes,
        'window': (window as ExamWindowModel).toJson(),
        'questions': questions
            .map((q) => (q as ExamQuestionModel).toJson())
            .toList(),
      };
}
