import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/features/exam_session/data/models/exam_answer_draft_model.dart';
import 'package:military_exam/features/exam_session/domain/utils/finalize_payload_builder.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  test('FinalizePayloadBuilder orders answers and maps finalize JSON', () {
    final drafts = {
      'desc-1': const ExamAnswerDraftModel(
        questionId: 'desc-1',
        type: ExamQuestionType.descriptive,
        questionNumber: 3,
      ),
      'mcq-1': const ExamAnswerDraftModel(
        questionId: 'mcq-1',
        type: ExamQuestionType.mcq,
        optionKey: 'b',
        questionNumber: 1,
      ),
      'fill-1': const ExamAnswerDraftModel(
        questionId: 'fill-1',
        type: ExamQuestionType.fillInBlank,
        answerText: 'answer',
        questionNumber: 2,
      ),
    };

    final orderedQuestions = [
      const ExamQuestion(
        id: 'mcq-1',
        questionNumber: 1,
        type: ExamQuestionType.mcq,
        text: 'MCQ',
        mark: 1,
        options: [ExamQuestionOption(key: 'b', text: 'B')],
      ),
      const ExamQuestion(
        id: 'fill-1',
        questionNumber: 2,
        type: ExamQuestionType.fillInBlank,
        text: 'Fill',
        mark: 1,
      ),
      const ExamQuestion(
        id: 'desc-1',
        questionNumber: 3,
        type: ExamQuestionType.descriptive,
        text: 'Describe',
        mark: 10,
      ),
    ];

    final payload = FinalizePayloadBuilder.build(
      drafts: drafts,
      orderedQuestions: orderedQuestions,
    );

    expect(payload, hasLength(3));
    expect(payload[0].questionId, 'mcq-1');
    expect(payload[1].questionId, 'fill-1');
    expect(payload[2].questionId, 'desc-1');

    expect(payload[0].toFinalizeJson(), {
      'question_id': 'mcq-1',
      'option_key': 'b',
    });
    expect(payload[1].toFinalizeJson(), {
      'question_id': 'fill-1',
      'answer_text': 'answer',
    });
    expect(payload[2].toFinalizeJson(), {
      'question_id': 'desc-1',
    });
  });

  test('FinalizePayloadBuilder skips empty MCQ and fill-blank drafts', () {
    final drafts = {
      'mcq-empty': const ExamAnswerDraftModel(
        questionId: 'mcq-empty',
        type: ExamQuestionType.mcq,
      ),
      'fill-empty': const ExamAnswerDraftModel(
        questionId: 'fill-empty',
        type: ExamQuestionType.fillInBlank,
        answerText: '   ',
      ),
      'desc-1': const ExamAnswerDraftModel(
        questionId: 'desc-1',
        type: ExamQuestionType.descriptive,
      ),
    };

    final payload = FinalizePayloadBuilder.build(drafts: drafts);

    expect(payload, hasLength(1));
    expect(payload.single.questionId, 'desc-1');
  });
}
