import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/security_repository.dart';

class CheckDeviceIntegrityUseCase {
  const CheckDeviceIntegrityUseCase(this._repository);

  final SecurityRepository _repository;

  Future<Result<DeviceIntegrityStatus>> call() =>
      _repository.checkDeviceIntegrity();
}
