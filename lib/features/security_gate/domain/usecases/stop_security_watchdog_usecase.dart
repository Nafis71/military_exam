import '../../../../core/services/security_watchdog_service.dart';

class StopSecurityWatchdogUseCase {
  const StopSecurityWatchdogUseCase(this._watchdogService);

  final SecurityWatchdogService _watchdogService;

  Future<void> call() => _watchdogService.stop();
}
