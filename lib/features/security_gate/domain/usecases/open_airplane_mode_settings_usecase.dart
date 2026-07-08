import '../../../../core/utils/result.dart';
import '../repositories/security_repository.dart';

class OpenAirplaneModeSettingsUseCase {
  const OpenAirplaneModeSettingsUseCase(this._repository);

  final SecurityRepository _repository;

  Future<Result<void>> call() => _repository.openAirplaneModeSettings();
}
