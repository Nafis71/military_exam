import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/exam_repository.dart';

class FinishExamUseCase {
  FinishExamUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<SubmissionReceipt>> call(String sessionId) =>
      _examRepository.finishExam(sessionId);
}
