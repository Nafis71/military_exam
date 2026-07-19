import '../../../../shared/domain/enums/exam_enums.dart';

abstract class PendingExamAnswersFlusher {
  Future<void> flush(ExamPhase phase);
}
