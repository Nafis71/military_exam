import '../../../../core/utils/result.dart';
import '../../domain/repositories/exam_repository.dart';

class SaveRollNumberUseCase {
  SaveRollNumberUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<void>> call(String rollNumber) =>
      _examRepository.saveRollNumber(rollNumber);
}
