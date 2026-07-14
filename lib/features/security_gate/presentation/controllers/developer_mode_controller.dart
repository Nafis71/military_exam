import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/deployment.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../domain/usecases/check_device_integrity_usecase.dart';
import '../../domain/usecases/open_developer_mode_settings_usecase.dart';

enum DeveloperModeGateStatus {
  checking,
  cleared,
  developerModeEnabled,
  deviceCompromised,
  error,
}

class DeveloperModeController extends GetxController {
  DeveloperModeController(
    this._checkDeviceIntegrity,
    this._openSettings,
    this._lifecycleService,
    this._logger,
  );

  final CheckDeviceIntegrityUseCase _checkDeviceIntegrity;
  final OpenDeveloperModeSettingsUseCase _openSettings;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final Rx<DeveloperModeGateStatus> status =
      DeveloperModeGateStatus.checking.obs;
  final RxBool isOpeningSettings = false.obs;

  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;

  @override
  void onInit() {
    super.onInit();
    _checkIntegrity();
    _listenForResume();
  }

  @override
  void onClose() {
    unawaited(_lifecycleSubscription?.cancel());
    super.onClose();
  }

  void _listenForResume() {
    _lifecycleSubscription = _lifecycleService.lifecycleStream
        .where((state) => state == AppLifecycleState.resumed)
        .listen((_) => _checkIntegrity());
  }

  Future<void> _checkIntegrity() async {
    status.value = DeveloperModeGateStatus.checking;

    final result = await _checkDeviceIntegrity();
    if (result.isFailure) {
      status.value = DeveloperModeGateStatus.error;
      _logger.error(
        result.failureOrNull?.message ?? AppStrings.integrityCheckFailed,
      );
      return;
    }

    _updateStatus(result.dataOrNull!);
  }

  void _updateStatus(DeviceIntegrityStatus integrity) {
    if (integrity.checkFailed ||
        integrity.isRooted ||
        integrity.isJailbroken ||
        (integrity.isCustomRom && Deployment.instance.strictExamIntegrity)) {
      status.value = DeveloperModeGateStatus.deviceCompromised;
      _logger.error(
        integrity.isCustomRom
            ? SecurityService.instance.lastStatus?.primaryBlockReason ??
                AppStrings.deviceCompromisedGeneric
            : integrity.isRooted
                ? ViolationType.rootedDevice.displayMessage
                : integrity.isJailbroken
                    ? ViolationType.jailbreakDetected.displayMessage
                    : AppStrings.deviceCompromisedGeneric,
      );
      return;
    }

    if (integrity.isDeveloperModeEnabled) {
      status.value = DeveloperModeGateStatus.developerModeEnabled;
      return;
    }

    status.value = DeveloperModeGateStatus.cleared;
  }

  Future<void> openSettings() async {
    isOpeningSettings.value = true;
    final result = await _openSettings();
    isOpeningSettings.value = false;

    if (result.isFailure) {
      _logger.error(
        result.failureOrNull?.message ?? AppStrings.unableToOpenSettings,
      );
    }
  }

  Future<void> continueWhenReady() async {
    if (status.value != DeveloperModeGateStatus.cleared) return;
    Get.offNamed(AppRoutes.securityGate);
  }

  Future<void> refreshStatus() => _checkIntegrity();
}
