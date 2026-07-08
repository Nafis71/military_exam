import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../exam_session/domain/repositories/exam_repository.dart';

class GetMcqQuestionsUseCase {
  GetMcqQuestionsUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<List<McqQuestion>>> call(String sessionId) =>
      _examRepository.getMcqQuestions(sessionId);
}
