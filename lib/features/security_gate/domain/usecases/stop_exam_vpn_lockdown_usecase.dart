import '../../../../core/services/exam_vpn_lockdown_service.dart';

class StopExamVpnLockdownUseCase {
  const StopExamVpnLockdownUseCase(this._vpnLockdownService);

  final ExamVpnLockdownService _vpnLockdownService;

  Future<void> call() => _vpnLockdownService.stopLockdown();
}
