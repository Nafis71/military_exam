import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/security_repository.dart';

class ObserveAirplaneModeUseCase {
  const ObserveAirplaneModeUseCase(this._repository);

  final SecurityRepository _repository;

  Stream<AirplaneModeStatus> call() => _repository.observeAirplaneMode();
}
