import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/security_repository.dart';

class ObserveConnectivityUseCase {
  const ObserveConnectivityUseCase(this._repository);

  final SecurityRepository _repository;

  Stream<ConnectivityStatus> call() => _repository.observeConnectivity();
}
