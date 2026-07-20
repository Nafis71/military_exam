import '../../../../core/utils/result.dart';
import '../repositories/written_exam_repository.dart';

class MarkWrittenImageUploadedUseCase {
  MarkWrittenImageUploadedUseCase(this._repository);

  final WrittenExamRepository _repository;

  Future<Result<void>> call({
    required String localId,
    required String remoteId,
  }) =>
      _repository.markImageUploaded(localId: localId, remoteId: remoteId);
}
