import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../presentation/routes/security_routes.dart';

/// Routes from security gate (or camera gate) to batch login after pre-checks.
class CompleteSecurityPreExamUseCase {
  const CompleteSecurityPreExamUseCase(this._cameraPermissionService);

  final CameraPermissionService _cameraPermissionService;

  Future<void> call() async {
    if (!await _cameraPermissionService.isGranted) {
      Get.offNamed(SecurityRoutes.cameraPermissionRequired);
      return;
    }

    Get.offNamed(AppRoutes.login);
  }
}
