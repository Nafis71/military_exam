import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/written_exam_repository.dart';

class AddWrittenImageUseCase {
  AddWrittenImageUseCase(this._repository);

  final WrittenExamRepository _repository;

  Future<Result<WrittenAnswerImage>> call(
    String localPath,
    String questionId,
  ) =>
      _repository.addImage(localPath, questionId);
}
