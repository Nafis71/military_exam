import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/written_exam_repository.dart';

class SubmitWrittenExamUseCase {
  SubmitWrittenExamUseCase(this._repository);

  final WrittenExamRepository _repository;

  Future<Result<SubmissionReceipt>> call(String sessionId) =>
      _repository.submitExam(sessionId);
}
