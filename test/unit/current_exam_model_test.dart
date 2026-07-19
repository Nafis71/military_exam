import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/features/exam_session/data/models/current_exam_model.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  test('CurrentExamModel parses mixed question types from API payload', () {
    final model = CurrentExamModel.fromJson({
      'exam_id': 'exam-1',
      'exam_name': 'exam-1',
      'batch_name': 'batch-1',
      'batch_status': 'active',
      'batch_id': 'batch-1',
      'total_questions': 3,
      'duration_minutes': 60,
      'window': {
        'can_access_questions': true,
        'can_submit': false,
        'remaining_exam_minutes': 45,
        'remaining_submit_minutes': 50,
        'buffer_time_minutes': 5,
      },
      'questions': [
        {
          'id': 'q1',
          'question_number': 1,
          'question_type': 'MCQ',
          'question_text': 'MCQ question',
          'mark': 1,
          'options': [
            {'option_key': 'a', 'text': 'A'},
          ],
        },
        {
          'id': 'q2',
          'question_number': 2,
          'question_type': 'FILL_IN_BLANK',
          'question_text': 'Fill ____ blank',
          'mark': 1,
        },
        {
          'id': 'q3',
          'question_number': 3,
          'question_type': 'DESCRIPTIVE',
          'question_text': 'Describe impact',
          'mark': 10,
        },
      ],
    });

    expect(model.examId, 'exam-1');
    expect(model.durationMinutes, 60);
    expect(model.window.canSubmit, isFalse);
    expect(model.questions, hasLength(3));
    expect(model.questions[0].type, ExamQuestionType.mcq);
    expect(model.questions[1].type, ExamQuestionType.fillInBlank);
    expect(model.questions[2].type, ExamQuestionType.descriptive);
    expect(model.questions[0].options.first.key, 'a');
  });
}
