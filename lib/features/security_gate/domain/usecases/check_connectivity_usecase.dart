import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/security_repository.dart';

class CheckConnectivityUseCase {
  const CheckConnectivityUseCase(this._repository);

  final SecurityRepository _repository;

  Future<Result<ConnectivityStatus>> call() => _repository.checkConnectivity();
}
