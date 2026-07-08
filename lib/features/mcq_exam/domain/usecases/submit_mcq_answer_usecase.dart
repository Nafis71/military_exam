import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../exam_session/domain/repositories/exam_repository.dart';

class SubmitMcqAnswerUseCase {
  SubmitMcqAnswerUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<McqAnswer>> call(McqAnswer answer) =>
      _examRepository.submitMcqAnswer(answer);
}
