import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/utils/result.dart';
import 'package:military_exam/features/exam_session/data/models/exam_answer_draft_model.dart';
import 'package:military_exam/features/exam_session/domain/usecases/get_exam_submit_summary_usecase.dart';
import 'package:military_exam/features/exam_session/domain/repositories/exam_repository.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';
import 'package:military_exam/shared/domain/enums/exam_enums.dart';

void main() {
  test('GetExamSubmitSummaryUseCase counts included drafts across types', () async {
    final exam = CurrentExam(
      examId: 'exam-1',
      examName: 'Written Exam',
      batchName: 'Batch A',
      batchStatus: 'active',
      batchId: 'batch-1',
      totalQuestions: 12,
      durationMinutes: 60,
      window: const ExamWindow(
        startTime: null,
        examEndTime: null,
        submitEndTime: null,
        bufferTimeMinutes: 0,
        canAccessQuestions: true,
        canSubmit: true,
        remainingExamMinutes: 40,
        remainingSubmitMinutes: 40,
      ),
      questions: const [
        ExamQuestion(
          id: 'mcq-1',
          questionNumber: 1,
          type: ExamQuestionType.mcq,
          text: 'MCQ 1',
          mark: 1,
        ),
      ],
    );

    final useCase = GetExamSubmitSummaryUseCase(
      _FakeExamRepository(
        drafts: {
          'mcq-1': const ExamAnswerDraftModel(
            questionId: 'mcq-1',
            type: ExamQuestionType.mcq,
            questionNumber: 1,
            optionKey: 'A',
          ),
          'blank-1': const ExamAnswerDraftModel(
            questionId: 'blank-1',
            type: ExamQuestionType.fillInBlank,
            questionNumber: 2,
            answerText: 'answer',
          ),
          'written-1': const ExamAnswerDraftModel(
            questionId: 'written-1',
            type: ExamQuestionType.descriptive,
            questionNumber: 3,
          ),
          'blank-empty': const ExamAnswerDraftModel(
            questionId: 'blank-empty',
            type: ExamQuestionType.fillInBlank,
            questionNumber: 4,
            answerText: '   ',
          ),
        },
      ),
    );

    final result = await useCase(exam: exam, timerRemainingSeconds: 45 * 60);

    expect(result, isA<Success>());
    final summary = (result as Success).data;
    expect(summary.examName, 'Written Exam');
    expect(summary.batchName, 'Batch A');
    expect(summary.totalQuestions, 12);
    expect(summary.answeredQuestions, 3);
    expect(summary.elapsedSeconds, 15 * 60);
    expect(summary.totalDurationMinutes, 60);
  });
}

class _FakeExamRepository implements ExamRepository {
  _FakeExamRepository({required this.drafts});

  final Map<String, ExamAnswerDraft> drafts;

  @override
  Future<Result<Map<String, ExamAnswerDraft>>> getAnswerDrafts() async =>
      Success(drafts);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
