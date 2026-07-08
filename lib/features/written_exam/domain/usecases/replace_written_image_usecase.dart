import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/written_exam_repository.dart';

class ReplaceWrittenImageUseCase {
  ReplaceWrittenImageUseCase(this._repository);

  final WrittenExamRepository _repository;

  Future<Result<WrittenAnswerImage>> call(String localId, String newLocalPath) =>
      _repository.replaceImage(localId, newLocalPath);
}
