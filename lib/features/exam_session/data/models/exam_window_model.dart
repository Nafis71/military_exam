import '../../../../shared/domain/entities/exam_entities.dart';

class ExamWindowModel extends ExamWindow {
  const ExamWindowModel({
    required super.startTime,
    required super.examEndTime,
    required super.submitEndTime,
    required super.bufferTimeMinutes,
    required super.canAccessQuestions,
    required super.canSubmit,
    required super.remainingExamMinutes,
    required super.remainingSubmitMinutes,
  });

  factory ExamWindowModel.fromJson(Map<String, dynamic> json) {
    return ExamWindowModel(
      startTime: _parseDate(json['start_time']),
      examEndTime: _parseDate(json['exam_end_time']),
      submitEndTime: _parseDate(json['submit_end_time']),
      bufferTimeMinutes: json['buffer_time_minutes'] as int? ?? 0,
      canAccessQuestions: json['can_access_questions'] as bool? ?? true,
      canSubmit: json['can_submit'] as bool? ?? true,
      remainingExamMinutes: json['remaining_exam_minutes'] as int? ?? 0,
      remainingSubmitMinutes: json['remaining_submit_minutes'] as int? ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        'start_time': startTime?.toIso8601String(),
        'exam_end_time': examEndTime?.toIso8601String(),
        'submit_end_time': submitEndTime?.toIso8601String(),
        'buffer_time_minutes': bufferTimeMinutes,
        'can_access_questions': canAccessQuestions,
        'can_submit': canSubmit,
        'remaining_exam_minutes': remainingExamMinutes,
        'remaining_submit_minutes': remainingSubmitMinutes,
      };
}
