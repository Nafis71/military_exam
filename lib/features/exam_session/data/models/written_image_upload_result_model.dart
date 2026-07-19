import '../../../../shared/domain/entities/exam_entities.dart';

class WrittenImageUploadResultModel extends WrittenImageUploadResult {
  const WrittenImageUploadResultModel({
    required super.answerId,
    required super.questionId,
    required super.imagePath,
    required super.gradingStatus,
  });

  factory WrittenImageUploadResultModel.fromJson(Map<String, dynamic> json) {
    return WrittenImageUploadResultModel(
      answerId: json['answer_id'] as String,
      questionId: json['question_id'] as String,
      imagePath: json['image_path'] as String? ?? '',
      gradingStatus: json['grading_status'] as String? ?? 'PENDING',
    );
  }
}
