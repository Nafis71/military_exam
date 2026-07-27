import '../../../../core/errors/failure.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/services/identity_verification_session.dart';
import '../../../../core/services/screen_security_service.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/clear_session_usecase.dart';
import '../../../exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import '../../../security_gate/domain/usecases/stop_exam_vpn_lockdown_usecase.dart';
import '../../../security_gate/domain/usecases/stop_security_watchdog_usecase.dart';
import '../../domain/repositories/onboarding_repository.dart';

class UnbindDeviceUseCase {
  UnbindDeviceUseCase(
    this._stopWatchdog,
    this._stopVpnLockdown,
    this._screenSecurity,
    this._clearExamLocalData,
    this._clearSession,
    this._onboardingRepository,
    this._verificationSession,
    this._examRunContext,
  );

  final StopSecurityWatchdogUseCase _stopWatchdog;
  final StopExamVpnLockdownUseCase _stopVpnLockdown;
  final ScreenSecurityService _screenSecurity;
  final ClearExamLocalDataUseCase _clearExamLocalData;
  final ClearSessionUseCase _clearSession;
  final OnboardingRepository _onboardingRepository;
  final IdentityVerificationSession _verificationSession;
  final ExamRunContext _examRunContext;

  Future<Result<void>> call() async {
    try {
      await _stopWatchdog();
      await _stopVpnLockdown();
      if (_screenSecurity.isEnabled) {
        await _screenSecurity.disable();
      }

      final clearExamResult = await _clearExamLocalData();
      if (clearExamResult is ErrorResult<void>) {
        return ErrorResult(clearExamResult.failure);
      }

      final clearSessionResult = await _clearSession();
      if (clearSessionResult is ErrorResult<void>) {
        return ErrorResult(clearSessionResult.failure);
      }

      final clearOnboardingResult = await _onboardingRepository.clearAll();
      if (clearOnboardingResult is ErrorResult<void>) {
        return ErrorResult(clearOnboardingResult.failure);
      }

      _verificationSession.clear();
      _examRunContext.reset();

      return const Success(null);
    } catch (error) {
      return ErrorResult(UnexpectedFailure(error.toString()));
    }
  }
}
