import '../../../../core/utils/result.dart';
import '../repositories/security_repository.dart';

class OpenDeveloperModeSettingsUseCase {
  const OpenDeveloperModeSettingsUseCase(this._repository);

  final SecurityRepository _repository;

  Future<Result<void>> call() => _repository.openDeveloperModeSettings();
}
