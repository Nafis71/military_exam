import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/deployment.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/services/exam_vpn_lockdown_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../onboarding_demo/data/datasources/onboarding_demo_exam_datasource.dart';
import '../../../security_gate/domain/usecases/start_security_watchdog_usecase.dart';
import '../../domain/usecases/clear_exam_local_data_usecase.dart';
import '../../presentation/controllers/exam_session_controller.dart';

/// Orchestrates exam entry after credentials (real) or demo bootstrap.
class EnterExamAfterCredentialsUseCase {
  EnterExamAfterCredentialsUseCase(
    this._sessionController,
    this._cameraPermissionService,
    this._startWatchdog,
    this._vpnLockdownService,
  );

  final ExamSessionController _sessionController;
  final CameraPermissionService _cameraPermissionService;
  final StartSecurityWatchdogUseCase _startWatchdog;
  final ExamVpnLockdownService _vpnLockdownService;

  Future<Result<void>> call({
    required String authSessionId,
    bool skipSecurity = false,
  }) async {
    try {
      final cameraGranted = await _cameraPermissionService.ensureGranted();
      if (!cameraGranted) {
        return const ErrorResult(
          UnexpectedFailure(AppStrings.cameraPermissionRequiredBeforeExam),
        );
      }

      await _sessionController.startSession(authSessionId);
      if (_sessionController.errorMessage.value != null) {
        return ErrorResult(
          UnexpectedFailure(
            _sessionController.errorMessage.value ??
                AppStrings.somethingWentWrong,
          ),
        );
      }

      final examSession = _sessionController.examSession.value;
      if (examSession == null) {
        return const ErrorResult(UnexpectedFailure(AppStrings.somethingWentWrong));
      }
      if (_sessionController.currentExam.value == null) {
        return const ErrorResult(UnexpectedFailure(AppStrings.somethingWentWrong));
      }

      final sessionId = examSession.sessionId;

      if (skipSecurity) {
        final route = _sessionController.initialExamRouteOrNull;
        if (route == null) {
          return const ErrorResult(
            UnexpectedFailure(AppStrings.noQuestionsAvailable),
          );
        }
        Get.offAllNamed(route, arguments: sessionId);
        return const Success(null);
      }

      if (!Deployment.instance.isDemo) {
        final vpnReady = await _vpnLockdownService.ensureActive();
        if (!vpnReady) {
          return const ErrorResult(
            UnexpectedFailure(AppStrings.networkLockdownMustBeEnabled),
          );
        }
      }

      final vpnPolicy = SecurityPolicy(
        requireAirplaneMode: true,
        requireVpnLockdown: !Deployment.instance.isDemo,
      );

      if (_sessionController.isWaitingForExamStart) {
        await _startWatchdog(
          policy: vpnPolicy.copyWith(monitoredPhases: const []),
          phase: ExamPhase.mcq,
          sessionId: sessionId,
        );
        Get.offAllNamed(AppRoutes.examWaiting, arguments: sessionId);
        return const Success(null);
      }

      await _startWatchdog(
        policy: vpnPolicy.copyWith(
          monitoredPhases: const [
            ExamPhase.mcq,
            ExamPhase.fillBlank,
            ExamPhase.written,
          ],
        ),
        phase: ExamPhase.mcq,
        sessionId: sessionId,
      );
      final route = _sessionController.initialExamRouteOrNull;
      if (route == null) {
        return const ErrorResult(
          UnexpectedFailure(AppStrings.noQuestionsAvailable),
        );
      }
      Get.offAllNamed(route, arguments: sessionId);
      return const Success(null);
    } catch (error) {
      return ErrorResult(UnexpectedFailure(error.toString()));
    }
  }
}

class StartOnboardingDemoExamUseCase {
  StartOnboardingDemoExamUseCase(
    this._examRunContext,
    this._enterExam,
    this._clearExamLocalData,
  );

  final ExamRunContext _examRunContext;
  final EnterExamAfterCredentialsUseCase _enterExam;
  final ClearExamLocalDataUseCase _clearExamLocalData;

  Future<Result<void>> call() async {
    _examRunContext.setOnboardingDemo();
    final clearResult = await _clearExamLocalData();
    if (clearResult is ErrorResult<void>) {
      return ErrorResult(clearResult.failure);
    }
    return _enterExam(
      authSessionId: OnboardingDemoExamDataSource.authSessionId,
      skipSecurity: true,
    );
  }
}
