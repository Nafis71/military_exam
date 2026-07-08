import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../presentation/routes/security_routes.dart';
import 'start_security_watchdog_usecase.dart';

/// Advances past security gate checks into login, routing through camera
/// permission when it is still missing.
class CompleteSecurityPreExamUseCase {
  const CompleteSecurityPreExamUseCase(
    this._cameraPermissionService,
    this._startWatchdog,
  );

  final CameraPermissionService _cameraPermissionService;
  final StartSecurityWatchdogUseCase _startWatchdog;

  Future<void> call() async {
    if (!await _cameraPermissionService.isGranted) {
      Get.offNamed(SecurityRoutes.cameraPermissionRequired);
      return;
    }

    await _startWatchdog(
      policy: const SecurityPolicy(requireAirplaneMode: true),
      phase: ExamPhase.securityGate,
    );
    Get.offNamed(AppRoutes.login);
  }
}
