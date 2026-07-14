import 'package:get/get.dart';

import '../../../../core/config/deployment.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/security_service.dart';

import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../domain/usecases/check_airplane_mode_usecase.dart';
import '../../domain/usecases/check_connectivity_usecase.dart';
import '../../domain/usecases/check_device_integrity_usecase.dart';
import '../../domain/usecases/complete_security_pre_exam_usecase.dart';
import '../routes/security_routes.dart';
import '../widgets/security_checklist.dart';

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
  final Rx<DeviceIntegrityStatus?> integrity = Rx<DeviceIntegrityStatus?>(null);
  final RxList<SecurityChecklistItemData> checklistItems =
      <SecurityChecklistItemData>[].obs;

  bool get blockEmulator => Deployment.instance.isProduction;

  @override
  void onInit() {
    super.onInit();
    runChecks();
  }

  Future<void> runChecks() async {
    status.value = SecurityGateStatus.checking;
    integrity.value = null;
    checklistItems.assignAll(SecurityChecklist.initialCheckingItems());
    final startedAt = DateTime.now();

    final integrityResult = await _checkDeviceIntegrity();
    if (integrityResult.isFailure) {
      status.value = SecurityGateStatus.failed;
      _logger.error(
        integrityResult.failureOrNull?.message ?? AppStrings.integrityCheckFailed,
      );
      return;
    }

    final deviceIntegrity = integrityResult.dataOrNull!;
    integrity.value = deviceIntegrity;
    _updateChecklistAfterIntegrity(deviceIntegrity);

    if (_isDeviceCompromised(deviceIntegrity)) {
      status.value = SecurityGateStatus.deviceCompromised;
      _logger.error(_compromisedMessage(deviceIntegrity));
      return;
    }

    if (deviceIntegrity.isEnvironmentSpoofed || deviceIntegrity.isCustomRom) {
      status.value = SecurityGateStatus.deviceCompromised;
      _logger.error(_compromisedMessage(deviceIntegrity));
      return;
    }

    if (_isDeveloperModeOnlyIssue(deviceIntegrity)) {
      Get.offNamed(SecurityRoutes.developerModeRequired);
      return;
    }

    _setAirplaneChecking();

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
    _updateChecklistAfterAirplane(deviceIntegrity, airplane.isEnabled);

    if (!airplane.isEnabled) {
      Get.offNamed(SecurityRoutes.airplaneModeRequired);
      return;
    }

    _setWifiChecking();

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
    _updateChecklistAfterWifi(
      deviceIntegrity,
      airplane.isEnabled,
      connectivity.isOnline,
    );

    if (!connectivity.isOnline) {
      Get.offNamed(SecurityRoutes.wifiModeRequired);
      return;
    }

    await _ensureMinCheckingDuration(startedAt);
    status.value = SecurityGateStatus.passed;
  }

  void _updateChecklistAfterIntegrity(DeviceIntegrityStatus deviceIntegrity) {
    checklistItems.assignAll(
      SecurityChecklist.fromIntegrity(
        integrity: deviceIntegrity,
        blockEmulator: blockEmulator,
        pendingTailState: SecurityChecklistState.pending,
      ),
    );
  }

  void _setAirplaneChecking() {
    if (integrity.value == null) return;
    checklistItems.assignAll(
      SecurityChecklist.fromIntegrity(
        integrity: integrity.value!,
        blockEmulator: blockEmulator,
        pendingTailState: SecurityChecklistState.pending,
      ).map((item) {
        if (item.label == AppStrings.airplaneModeActive) {
          return SecurityChecklistItemData(
            label: item.label,
            state: SecurityChecklistState.checking,
          );
        }
        return item;
      }),
    );
  }

  void _updateChecklistAfterAirplane(
    DeviceIntegrityStatus deviceIntegrity,
    bool airplaneEnabled,
  ) {
    checklistItems.assignAll(
      SecurityChecklist.fromIntegrity(
        integrity: deviceIntegrity,
        blockEmulator: blockEmulator,
        airplaneEnabled: airplaneEnabled,
        pendingTailState: SecurityChecklistState.pending,
      ),
    );
  }

  void _setWifiChecking() {
    if (integrity.value == null) return;
    final current = checklistItems.toList();
    final wifiIndex = current.indexWhere(
      (item) => item.label == AppStrings.wifiConnected,
    );
    if (wifiIndex == -1) return;
    current[wifiIndex] = SecurityChecklistItemData(
      label: AppStrings.wifiConnected,
      state: SecurityChecklistState.checking,
    );
    checklistItems.assignAll(current);
  }

  void _updateChecklistAfterWifi(
    DeviceIntegrityStatus deviceIntegrity,
    bool airplaneEnabled,
    bool wifiOnline,
  ) {
    checklistItems.assignAll(
      SecurityChecklist.fromIntegrity(
        integrity: deviceIntegrity,
        blockEmulator: blockEmulator,
        airplaneEnabled: airplaneEnabled,
        wifiOnline: wifiOnline,
      ),
    );
  }

  bool _isDeviceCompromised(DeviceIntegrityStatus deviceIntegrity) =>
      deviceIntegrity.isCompromised;

  bool _isDeveloperModeOnlyIssue(DeviceIntegrityStatus deviceIntegrity) {
    final rasp = SecurityService.instance.lastStatus;
    if (rasp == null) return deviceIntegrity.isDeveloperModeEnabled;
    return isDeveloperModeOnlyIssue(
      status: rasp,
      strictExamIntegrity: Deployment.instance.strictExamIntegrity,
    );
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

  String _compromisedMessage(DeviceIntegrityStatus deviceIntegrity) {
    final primaryReason =
        SecurityService.instance.lastStatus?.primaryBlockReason;
    if (primaryReason != null && primaryReason.isNotEmpty) {
      return primaryReason;
    }
    if (deviceIntegrity.checkFailed) return AppStrings.deviceCompromisedGeneric;
    if (deviceIntegrity.isEnvironmentSpoofed) {
      return SecurityService.instance.lastStatus?.primaryBlockReason ??
          AppStrings.deviceCompromisedGeneric;
    }
    if (deviceIntegrity.isCustomRom) {
      return SecurityService.instance.lastStatus?.primaryBlockReason ??
          AppStrings.deviceCompromisedGeneric;
    }
    if (deviceIntegrity.isRooted) {
      return ViolationType.rootedDevice.displayMessage;
    }
    if (deviceIntegrity.isJailbroken) {
      return ViolationType.jailbreakDetected.displayMessage;
    }
    if (deviceIntegrity.isHooked) return AppStrings.runtimeManipulationDetected;
    if (deviceIntegrity.isDebuggerAttached) {
      return AppStrings.debuggerAttachedDetected;
    }
    if (deviceIntegrity.isEmulator && blockEmulator) {
      return AppStrings.emulatorDetected;
    }
    if (deviceIntegrity.hasTestKeys) return AppStrings.testKeysDetected;
    if (deviceIntegrity.isIntegrityViolated) {
      return AppStrings.appIntegrityViolated;
    }
    return AppStrings.deviceCompromisedGeneric;
  }
}
