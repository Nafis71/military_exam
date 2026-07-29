import '../../../../core/constants/app_strings.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/data/models/current_exam_model.dart';
import '../../../exam_session/data/models/exam_question_model.dart';
import '../../../exam_session/data/models/exam_question_option_model.dart';
import '../../../exam_session/data/models/exam_session_model.dart';
import '../../../exam_session/data/models/exam_window_model.dart';
import '../../../exam_session/data/models/mcq_option_model.dart';
import '../../../exam_session/data/models/mcq_question_model.dart';
import '../../../exam_session/data/mappers/submission_receipt_mapper.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

/// Mock exam data for the onboarding demo flow (separate from API demo).
abstract final class OnboardingDemoExamDataSource {
  static const authSessionId = 'onboarding-demo-auth';
  static const durationMinutes = 30;

  static ExamSessionModel session(String authSessionId) {
    return ExamSessionModel(
      sessionId: 'onboarding-exam-${DateTime.now().millisecondsSinceEpoch}',
      examineeId: authSessionId,
      startedAt: DateTime.now(),
      durationMinutes: durationMinutes,
      isLocked: false,
      currentPhase: ExamPhase.mcq.name,
    );
  }

  static CurrentExamModel get currentExam {
    return CurrentExamModel(
      examId: 'onboarding-demo-exam',
      examName: AppStrings.onboardingDemoExamName,
      batchName: 'onboarding-demo-batch',
      batchStatus: 'active',
      batchId: 'onboarding-demo-batch-id',
      totalQuestions: 10,
      durationMinutes: durationMinutes,
      window: const ExamWindowModel(
        startTime: null,
        examEndTime: null,
        submitEndTime: null,
        bufferTimeMinutes: 5,
        canAccessQuestions: true,
        canSubmit: true,
        remainingExamMinutes: durationMinutes,
        remainingSubmitMinutes: durationMinutes + 5,
      ),
      questions: examQuestions,
    );
  }

  static List<ExamQuestionModel> get examQuestions {
    var questionNumber = 1;
    final questions = <ExamQuestionModel>[
      for (final mcq in mcqQuestions)
        ExamQuestionModel(
          id: mcq.id,
          questionNumber: questionNumber++,
          type: ExamQuestionType.mcq,
          text: mcq.question,
          mark: 1,
          options: mcq.options
              .map(
                (option) => ExamQuestionOptionModel(
                  key: option.id,
                  text: option.label,
                ),
              )
              .toList(),
        ),
      ExamQuestionModel(
        id: 'onboarding-fill-1',
        questionNumber: questionNumber++,
        type: ExamQuestionType.fillInBlank,
        text: AppStrings.onboardingDemoFillBlank1,
        mark: 1,
      ),
      ExamQuestionModel(
        id: 'onboarding-fill-2',
        questionNumber: questionNumber++,
        type: ExamQuestionType.fillInBlank,
        text: AppStrings.onboardingDemoFillBlank2,
        mark: 1,
      ),
      ExamQuestionModel(
        id: 'onboarding-written-1',
        questionNumber: questionNumber++,
        type: ExamQuestionType.descriptive,
        text: AppStrings.onboardingDemoWritten1,
        mark: 5,
      ),
      ExamQuestionModel(
        id: 'onboarding-written-2',
        questionNumber: questionNumber++,
        type: ExamQuestionType.descriptive,
        text: AppStrings.onboardingDemoWritten2,
        mark: 5,
      ),
    ];
    return questions;
  }

  static List<McqQuestionModel> get mcqQuestions {
    const questions = [
      (
        'onboarding-mcq-1',
        AppStrings.onboardingDemoMcq1,
        [
          ('a', AppStrings.onboardingDemoMcq1A),
          ('b', AppStrings.onboardingDemoMcq1B),
          ('c', AppStrings.onboardingDemoMcq1C),
          ('d', AppStrings.onboardingDemoMcq1D),
        ],
      ),
      (
        'onboarding-mcq-2',
        AppStrings.onboardingDemoMcq2,
        [
          ('a', AppStrings.onboardingDemoMcq2A),
          ('b', AppStrings.onboardingDemoMcq2B),
          ('c', AppStrings.onboardingDemoMcq2C),
          ('d', AppStrings.onboardingDemoMcq2D),
        ],
      ),
      (
        'onboarding-mcq-3',
        AppStrings.onboardingDemoMcq3,
        [
          ('a', AppStrings.onboardingDemoMcq3A),
          ('b', AppStrings.onboardingDemoMcq3B),
          ('c', AppStrings.onboardingDemoMcq3C),
          ('d', AppStrings.onboardingDemoMcq3D),
        ],
      ),
      (
        'onboarding-mcq-4',
        AppStrings.onboardingDemoMcq4,
        [
          ('a', AppStrings.onboardingDemoMcq4A),
          ('b', AppStrings.onboardingDemoMcq4B),
          ('c', AppStrings.onboardingDemoMcq4C),
          ('d', AppStrings.onboardingDemoMcq4D),
        ],
      ),
      (
        'onboarding-mcq-5',
        AppStrings.onboardingDemoMcq5,
        [
          ('a', AppStrings.onboardingDemoMcq5A),
          ('b', AppStrings.onboardingDemoMcq5B),
          ('c', AppStrings.onboardingDemoMcq5C),
          ('d', AppStrings.onboardingDemoMcq5D),
        ],
      ),
      (
        'onboarding-mcq-6',
        AppStrings.onboardingDemoMcq6,
        [
          ('a', AppStrings.onboardingDemoMcq6A),
          ('b', AppStrings.onboardingDemoMcq6B),
          ('c', AppStrings.onboardingDemoMcq6C),
          ('d', AppStrings.onboardingDemoMcq6D),
        ],
      ),
    ];

    final total = questions.length;
    return List.generate(total, (index) {
      final item = questions[index];
      return McqQuestionModel(
        id: item.$1,
        question: item.$2,
        options: item.$3
            .map((o) => McqOptionModel(id: o.$1, label: o.$2))
            .toList(),
        index: index + 1,
        total: total,
      );
    });
  }

  static SubmissionReceipt receipt(String message) {
    return SubmissionReceiptMapper.fromJson({
      'message': message,
      'submitted_at': DateTime.now().toIso8601String(),
    });
  }
}
