import '../../../../core/utils/result.dart';
import '../../../exam_session/domain/repositories/exam_repository.dart';

class SaveDescriptiveDraftUseCase {
  SaveDescriptiveDraftUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<void>> call(String questionId) =>
      _examRepository.saveDescriptiveDraft(questionId);
}
