import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../exam_session/domain/repositories/exam_repository.dart';

class SaveFillBlankAnswerUseCase {
  SaveFillBlankAnswerUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<FillBlankAnswer>> call(FillBlankAnswer answer) =>
      _examRepository.saveFillBlankAnswerLocally(answer);
}
