import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../domain/usecases/check_connectivity_usecase.dart';
import '../../domain/usecases/observe_connectivity_usecase.dart';
import '../../domain/usecases/open_wifi_settings_usecase.dart';
import '../routes/security_routes.dart';

enum WifiModeGateStatus {
  checking,
  enabled,
  disabled,
  error,
}

class WifiModeController extends GetxController {
  WifiModeController(
    this._checkConnectivity,
    this._observeConnectivity,
    this._openSettings,
    this._lifecycleService,
    this._logger,
  );

  final CheckConnectivityUseCase _checkConnectivity;
  final ObserveConnectivityUseCase _observeConnectivity;
  final OpenWifiSettingsUseCase _openSettings;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final Rx<WifiModeGateStatus> status = WifiModeGateStatus.checking.obs;
  final RxBool isOpeningSettings = false.obs;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;

  @override
  void onInit() {
    super.onInit();
    _checkInitialStatus();
    _listenForChanges();
    _listenForResume();
  }

  @override
  void onClose() {
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_lifecycleSubscription?.cancel());
    super.onClose();
  }

  void _listenForResume() {
    _lifecycleSubscription = _lifecycleService.lifecycleStream
        .where((state) => state == AppLifecycleState.resumed)
        .listen((_) => _checkInitialStatus());
  }

  Future<void> _checkInitialStatus() async {
    status.value = WifiModeGateStatus.checking;
    final result = await _checkConnectivity();
    if (result.isFailure) {
      status.value = WifiModeGateStatus.error;
      _logger.error(
        result.failureOrNull?.message ?? AppStrings.unableToVerifyConnectivity,
      );
      return;
    }

    _updateStatus(result.dataOrNull!);
  }

  void _listenForChanges() {
    _connectivitySubscription = _observeConnectivity().listen(
      _updateStatus,
      onError: (Object error) {
        status.value = WifiModeGateStatus.error;
        _logger.error('${AppStrings.connectivityMonitoringFailed}: $error');
      },
    );
  }

  void _updateStatus(ConnectivityStatus connectivityStatus) {
    status.value = connectivityStatus.isOnline
        ? WifiModeGateStatus.enabled
        : WifiModeGateStatus.disabled;
  }

  Future<void> openSettings() async {
    isOpeningSettings.value = true;
    final result = await _openSettings();
    isOpeningSettings.value = false;

    if (result.isFailure) {
      _logger.error(
        result.failureOrNull?.message ?? AppStrings.unableToOpenWifiSettings,
      );
    }
  }

  Future<void> continueWhenReady() async {
    if (status.value != WifiModeGateStatus.enabled) return;
    Get.offNamed(SecurityRoutes.securityGate);
  }

  Future<void> refreshStatus() => _checkInitialStatus();
}
