import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/get_current_session_usecase.dart';
import '../../../exam_session/domain/usecases/enter_exam_after_credentials_usecase.dart';
import '../../presentation/routes/security_routes.dart';

/// Advances past security gate checks into the exam session.
class CompleteSecurityPreExamUseCase {
  const CompleteSecurityPreExamUseCase(
    this._cameraPermissionService,
    this._getCurrentSession,
    this._enterExam,
    this._logger,
  );

  final CameraPermissionService _cameraPermissionService;
  final GetCurrentSessionUseCase _getCurrentSession;
  final EnterExamAfterCredentialsUseCase _enterExam;
  final AppLogger _logger;

  Future<void> call() async {
    if (!await _cameraPermissionService.isGranted) {
      Get.offNamed(SecurityRoutes.cameraPermissionRequired);
      return;
    }

    final sessionResult = await _getCurrentSession();
    switch (sessionResult) {
      case ErrorResult(:final failure):
        _logger.error('getCurrentSession failed', error: failure.message);
        Get.offNamed(AppRoutes.login);
        return;
      case Success(:final data):
        if (data == null) {
          Get.offNamed(AppRoutes.login);
          return;
        }
        final enterResult = await _enterExam(authSessionId: data.sessionId);
        switch (enterResult) {
          case ErrorResult(:final failure):
            _logger.error('enterExam failed', error: failure.message);
            Get.offNamed(AppRoutes.login);
          case Success():
            break;
        }    }
  }
}
