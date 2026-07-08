import '../../../../core/services/security_watchdog_service.dart';
import '../../../../shared/domain/enums/exam_enums.dart';

class StartSecurityWatchdogUseCase {
  const StartSecurityWatchdogUseCase(this._watchdogService);

  final SecurityWatchdogService _watchdogService;

  Future<void> call({
    required SecurityPolicy policy,
    required ExamPhase phase,
    String? sessionId,
  }) =>
      _watchdogService.start(
        policy: policy,
        phase: phase,
        sessionId: sessionId,
      );
}
