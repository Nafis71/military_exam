import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/app/routes/app_routes.dart';
import 'package:military_exam/features/exam_session/domain/utils/exam_question_splitter.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  final questions = [
    const ExamQuestion(
      id: 'mcq-1',
      questionNumber: 1,
      type: ExamQuestionType.mcq,
      text: 'MCQ',
      mark: 1,
      options: [ExamQuestionOption(key: 'a', text: 'A')],
    ),
    const ExamQuestion(
      id: 'fill-1',
      questionNumber: 2,
      type: ExamQuestionType.fillInBlank,
      text: 'Fill ____',
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

  test('ExamQuestionSplitter maps each type with section-local indexes', () {
    final mcqs = ExamQuestionSplitter.toMcqQuestions(questions);
    final fillBlanks = ExamQuestionSplitter.toFillBlankQuestions(questions);
    final descriptive = ExamQuestionSplitter.toDescriptiveQuestions(questions);

    expect(mcqs, hasLength(1));
    expect(mcqs.first.index, 1);
    expect(mcqs.first.total, 1);
    expect(mcqs.first.options.first.id, 'a');

    expect(fillBlanks, hasLength(1));
    expect(fillBlanks.first.index, 1);
    expect(fillBlanks.first.total, 1);

    expect(descriptive, hasLength(1));
    expect(descriptive.first.index, 1);
    expect(descriptive.first.total, 1);
  });

  test('nextRouteAfterPhase skips empty sections', () {
    expect(
      ExamQuestionSplitter.nextRouteAfterPhase(
        completedPhase: ExamPhase.mcq,
        mcqCount: 2,
        fillBlankCount: 0,
        descriptiveCount: 1,
      ),
      AppRoutes.writtenExam,
    );

    expect(
      ExamQuestionSplitter.nextRouteAfterPhase(
        completedPhase: ExamPhase.mcq,
        mcqCount: 2,
        fillBlankCount: 3,
        descriptiveCount: 1,
      ),
      AppRoutes.fillBlankExam,
    );

    expect(
      ExamQuestionSplitter.nextRouteAfterPhase(
        completedPhase: ExamPhase.fillBlank,
        mcqCount: 2,
        fillBlankCount: 3,
        descriptiveCount: 0,
      ),
      AppRoutes.examSubmitReview,
    );
  });
}
