import '../../../../core/utils/result.dart';
import '../../../exam_session/domain/repositories/exam_repository.dart';

class GetCurrentMcqProgressUseCase {
  GetCurrentMcqProgressUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<Map<String, String>>> call(String sessionId) =>
      _examRepository.getMcqProgress(sessionId);
}
