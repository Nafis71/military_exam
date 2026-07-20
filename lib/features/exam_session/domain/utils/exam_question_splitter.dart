import '../../../../app/routes/app_routes.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';

abstract final class ExamQuestionSplitter {
  static List<McqQuestion> toMcqQuestions(List<ExamQuestion> questions) {
    final mcqs =
        questions.where((q) => q.type == ExamQuestionType.mcq).toList();
    final total = mcqs.length;
    return List.generate(total, (index) {
      final question = mcqs[index];
      return McqQuestion(
        id: question.id,
        question: question.text,
        options: question.options
            .map((o) => McqOption(id: o.key, label: o.text))
            .toList(),
        index: index + 1,
        total: total,
      );
    });
  }

  static List<FillBlankQuestion> toFillBlankQuestions(
    List<ExamQuestion> questions,
  ) {
    final fillBlanks = questions
        .where((q) => q.type == ExamQuestionType.fillInBlank)
        .toList();
    final total = fillBlanks.length;
    return List.generate(total, (index) {
      final question = fillBlanks[index];
      return FillBlankQuestion(
        id: question.id,
        question: question.text,
        index: index + 1,
        total: total,
        mark: question.mark,
      );
    });
  }

  static int totalQuestionCount(List<ExamQuestion> questions) {
    var count = 0;
    for (final question in questions) {
      switch (question.type) {
        case ExamQuestionType.mcq:
        case ExamQuestionType.fillInBlank:
        case ExamQuestionType.descriptive:
          count++;
        default:
          break;
      }
    }
    return count;
  }

  static List<WrittenQuestion> toDescriptiveQuestions(
    List<ExamQuestion> questions,
  ) {
    final descriptive = questions
        .where((q) => q.type == ExamQuestionType.descriptive)
        .toList();
    final total = descriptive.length;
    return List.generate(total, (index) {
      final question = descriptive[index];
      return WrittenQuestion(
        id: question.id,
        index: index + 1,
        total: total,
        text: question.text,
      );
    });
  }

  static String? nextRouteAfterPhase({
    required ExamPhase completedPhase,
    required int mcqCount,
    required int fillBlankCount,
    required int descriptiveCount,
  }) {
    switch (completedPhase) {
      case ExamPhase.mcq:
        if (fillBlankCount > 0) return AppRoutes.fillBlankExam;
        if (descriptiveCount > 0) return AppRoutes.writtenExam;
        return AppRoutes.finishExam;
      case ExamPhase.fillBlank:
        if (descriptiveCount > 0) return AppRoutes.writtenExam;
        return AppRoutes.finishExam;
      case ExamPhase.written:
        return AppRoutes.finishExam;
      default:
        return null;
    }
  }

  static ExamPhase? nextPhaseAfter({
    required ExamPhase completedPhase,
    required int fillBlankCount,
    required int descriptiveCount,
  }) {
    switch (completedPhase) {
      case ExamPhase.mcq:
        if (fillBlankCount > 0) return ExamPhase.fillBlank;
        if (descriptiveCount > 0) return ExamPhase.written;
        return ExamPhase.finished;
      case ExamPhase.fillBlank:
        if (descriptiveCount > 0) return ExamPhase.written;
        return ExamPhase.finished;
      case ExamPhase.written:
        return ExamPhase.finished;
      default:
        return null;
    }
  }
}
