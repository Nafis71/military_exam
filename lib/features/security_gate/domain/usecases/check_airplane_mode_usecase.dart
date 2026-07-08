import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/security_repository.dart';

class CheckAirplaneModeUseCase {
  const CheckAirplaneModeUseCase(this._repository);

  final SecurityRepository _repository;

  Future<Result<AirplaneModeStatus>> call() => _repository.checkAirplaneMode();
}
