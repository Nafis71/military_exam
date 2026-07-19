import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/exam_repository.dart';

class FinalizeExamUseCase {
  FinalizeExamUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<SubmissionReceipt>> call(CurrentExam? currentExam) =>
      _examRepository.finalizeExam(currentExam);
}
