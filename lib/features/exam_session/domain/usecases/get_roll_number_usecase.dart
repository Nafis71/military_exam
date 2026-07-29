import '../../../../core/utils/result.dart';
import '../repositories/exam_repository.dart';

class GetRollNumberUseCase {
  const GetRollNumberUseCase(this._examRepository);

  final ExamRepository _examRepository;

  Future<Result<String?>> call() => _examRepository.getRollNumber();
}
