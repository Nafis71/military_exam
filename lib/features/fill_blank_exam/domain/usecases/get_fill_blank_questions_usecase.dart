import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../exam_session/domain/repositories/exam_repository.dart';

class GetFillBlankQuestionsUseCase {
  GetFillBlankQuestionsUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<List<FillBlankQuestion>>> call(String sessionId) =>
      _examRepository.getFillBlankQuestions(sessionId);
}
