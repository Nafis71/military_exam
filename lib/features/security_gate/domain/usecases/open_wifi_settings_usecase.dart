import '../../../../core/utils/result.dart';
import '../repositories/security_repository.dart';

class OpenWifiSettingsUseCase {
  const OpenWifiSettingsUseCase(this._repository);

  final SecurityRepository _repository;

  Future<Result<void>> call() => _repository.openWifiSettings();
}
