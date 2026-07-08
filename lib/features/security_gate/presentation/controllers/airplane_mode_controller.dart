import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../domain/usecases/check_airplane_mode_usecase.dart';
import '../../domain/usecases/open_airplane_mode_settings_usecase.dart';
import '../routes/security_routes.dart';

enum AirplaneModeGateStatus {
  checking,
  enabled,
  disabled,
  error,
}

class AirplaneModeController extends GetxController {
  AirplaneModeController(
    this._checkAirplaneMode,
    this._openSettings,
    this._lifecycleService,
    this._logger,
  );

  final CheckAirplaneModeUseCase _checkAirplaneMode;
  final OpenAirplaneModeSettingsUseCase _openSettings;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final Rx<AirplaneModeGateStatus> status = AirplaneModeGateStatus.checking.obs;
  final RxBool isOpeningSettings = false.obs;

  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;
  Timer? _pollTimer;
  AppLifecycleState? _lastLifecycleState;

  @override
  void onInit() {
    super.onInit();
    _lastLifecycleState = _lifecycleService.currentState;
    unawaited(_checkInitialStatus());
    _listenForResume();
    _startPolling();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    unawaited(_lifecycleSubscription?.cancel());
    super.onClose();
  }

  void _listenForResume() {
    _lifecycleSubscription = _lifecycleService.lifecycleStream.listen((state) {
      final wasBackgrounded = _lastLifecycleState ==
              AppLifecycleState.paused ||
          _lastLifecycleState == AppLifecycleState.hidden ||
          _lastLifecycleState == AppLifecycleState.inactive;
      _lastLifecycleState = state;

      if (state == AppLifecycleState.resumed && wasBackgrounded) {
        unawaited(_recheckAfterReturningToForeground());
      }
    });
  }

  Future<void> _recheckAfterReturningToForeground() async {
    await Future<void>.delayed(AppConstants.settingsReturnRecheckDelay);
    await _checkInitialStatus();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      AppConstants.airplaneModePollInterval,
      (_) => unawaited(_pollStatus()),
    );
  }

  Future<void> _pollStatus() async {
    final result = await _checkAirplaneMode();
    if (result.isFailure) return;
    _updateStatus(result.dataOrNull!);
  }

  Future<void> _checkInitialStatus() async {
    status.value = AirplaneModeGateStatus.checking;
    final result = await _checkAirplaneMode();
    if (result.isFailure) {
      status.value = AirplaneModeGateStatus.error;
      _logger.error(
        result.failureOrNull?.message ?? AppStrings.unableToVerifyAirplaneMode,
      );
      return;
    }

    _updateStatus(result.dataOrNull!);
  }

  void _updateStatus(AirplaneModeStatus airplaneStatus) {
    status.value = airplaneStatus.isEnabled
        ? AirplaneModeGateStatus.enabled
        : AirplaneModeGateStatus.disabled;
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
    if (status.value != AirplaneModeGateStatus.enabled) return;
    Get.offNamed(SecurityRoutes.wifiModeRequired);
  }

  Future<void> refreshStatus() => _checkInitialStatus();
}
