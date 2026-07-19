import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/written_exam_repository.dart';

class GetWrittenImagesUseCase {
  GetWrittenImagesUseCase(this._repository);

  final WrittenExamRepository _repository;

  Future<Result<List<WrittenAnswerImage>>> call() => _repository.getImages();
}
