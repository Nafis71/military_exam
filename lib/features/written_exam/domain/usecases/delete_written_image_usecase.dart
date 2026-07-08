import '../../../../core/utils/result.dart';
import '../repositories/written_exam_repository.dart';

class DeleteWrittenImageUseCase {
  DeleteWrittenImageUseCase(this._repository);

  final WrittenExamRepository _repository;

  Future<Result<void>> call(String localId) => _repository.deleteImage(localId);
}
