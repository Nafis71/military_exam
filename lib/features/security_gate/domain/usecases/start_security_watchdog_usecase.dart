import '../../../../core/services/exam_run_context.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../shared/domain/enums/exam_enums.dart';

class StartSecurityWatchdogUseCase {
  StartSecurityWatchdogUseCase(
    this._watchdogService,
    this._examRunContext,
  );

  final SecurityWatchdogService _watchdogService;
  final ExamRunContext _examRunContext;

  Future<void> call({
    required SecurityPolicy policy,
    required ExamPhase phase,
    String? sessionId,
  }) async {
    if (_examRunContext.isOnboardingDemo) return;

    await _watchdogService.start(
      policy: policy,
      phase: phase,
      sessionId: sessionId,
    );
  }
}
