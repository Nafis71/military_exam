import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/features/exam_session/data/models/written_image_upload_result_model.dart';

void main() {
  test('WrittenImageUploadResultModel parses upload response', () {
    final model = WrittenImageUploadResultModel.fromJson({
      'answer_id': 'ans-1',
      'question_id': 'q-1',
      'image_path': '/uploads/ans-1.jpg',
      'grading_status': 'PENDING',
    });

    expect(model.answerId, 'ans-1');
    expect(model.questionId, 'q-1');
    expect(model.imagePath, '/uploads/ans-1.jpg');
    expect(model.gradingStatus, 'PENDING');
  });

  test('WrittenImageUploadResultModel defaults missing optional fields', () {
    final model = WrittenImageUploadResultModel.fromJson({
      'answer_id': 'ans-2',
      'question_id': 'q-2',
    });

    expect(model.imagePath, '');
    expect(model.gradingStatus, 'PENDING');
  });
}
