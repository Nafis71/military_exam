import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/written_exam_repository.dart';

class UploadWrittenImageUseCase {
  UploadWrittenImageUseCase(this._repository);

  final WrittenExamRepository _repository;

  Future<Result<UploadProgress>> call(String localId) =>
      _repository.uploadImage(localId);
}
