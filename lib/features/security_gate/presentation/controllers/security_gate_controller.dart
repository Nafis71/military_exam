import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';

import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../domain/usecases/check_airplane_mode_usecase.dart';
import '../../domain/usecases/check_connectivity_usecase.dart';
import '../../domain/usecases/check_device_integrity_usecase.dart';
import '../../domain/usecases/complete_security_pre_exam_usecase.dart';
import '../routes/security_routes.dart';

enum SecurityGateStatus {
  checking,
  passed,
  deviceCompromised,
  airplaneModeRequired,
  failed,
}

class SecurityGateController extends GetxController {
  SecurityGateController(
    this._checkDeviceIntegrity,
    this._checkAirplaneMode,
    this._checkConnectivity,
    this._completePreExam,
    this._logger,
  );

  final CheckDeviceIntegrityUseCase _checkDeviceIntegrity;
  final CheckAirplaneModeUseCase _checkAirplaneMode;
  final CheckConnectivityUseCase _checkConnectivity;
  final CompleteSecurityPreExamUseCase _completePreExam;
  final AppLogger _logger;

  final Rx<SecurityGateStatus> status = SecurityGateStatus.checking.obs;

  @override
  void onInit() {
    super.onInit();
    runChecks();
  }

  Future<void> runChecks() async {
    status.value = SecurityGateStatus.checking;
    final startedAt = DateTime.now();

    final integrityResult = await _checkDeviceIntegrity();
    if (integrityResult.isFailure) {
      status.value = SecurityGateStatus.failed;
      _logger.error(
        integrityResult.failureOrNull?.message ?? AppStrings.integrityCheckFailed,
      );
      return;
    }

    final integrity = integrityResult.dataOrNull!;
    if (integrity.isRooted || integrity.isJailbroken) {
      status.value = SecurityGateStatus.deviceCompromised;
      _logger.error(_compromisedMessage(integrity));
      return;
    }

    if (integrity.isDeveloperModeEnabled) {
      Get.offNamed(SecurityRoutes.developerModeRequired);
      return;
    }

    final airplaneResult = await _checkAirplaneMode();
    if (airplaneResult.isFailure) {
      status.value = SecurityGateStatus.failed;
      _logger.error(
        airplaneResult.failureOrNull?.message ??
            AppStrings.airplaneModeCheckFailed,
      );
      return;
    }

    final airplane = airplaneResult.dataOrNull!;
    if (!airplane.isEnabled) {
      Get.offNamed(SecurityRoutes.airplaneModeRequired);
      return;
    }

    final connectivityResult = await _checkConnectivity();
    if (connectivityResult.isFailure) {
      status.value = SecurityGateStatus.failed;
      _logger.error(
        connectivityResult.failureOrNull?.message ??
            AppStrings.connectivityCheckFailedWithError,
      );
      return;
    }

    final connectivity = connectivityResult.dataOrNull!;
    if (!connectivity.isOnline) {
      Get.offNamed(SecurityRoutes.wifiModeRequired);
      return;
    }

    await _ensureMinCheckingDuration(startedAt);
    status.value = SecurityGateStatus.passed;
  }

  Future<void> _ensureMinCheckingDuration(DateTime startedAt) async {
    final elapsed = DateTime.now().difference(startedAt);
    final remaining =
        AppConstants.securityGateMinCheckingDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  Future<void> continueToNext() async {
    if (status.value != SecurityGateStatus.passed) return;
    await _completePreExam();
  }

  String _compromisedMessage(DeviceIntegrityStatus integrity) {
    if (integrity.isRooted) return ViolationType.rootedDevice.displayMessage;
    if (integrity.isJailbroken) {
      return ViolationType.jailbreakDetected.displayMessage;
    }
    return ViolationType.developerModeEnabled.displayMessage;
  }
}
