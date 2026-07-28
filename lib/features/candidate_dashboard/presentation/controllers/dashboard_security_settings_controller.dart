import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/config/deployment.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/exam_vpn_lockdown_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_error_toast.dart';
import '../../../security_gate/domain/usecases/check_airplane_mode_usecase.dart';
import '../../../security_gate/domain/usecases/check_connectivity_usecase.dart';
import '../../../security_gate/domain/usecases/open_airplane_mode_settings_usecase.dart';
import '../../../security_gate/domain/usecases/open_wifi_settings_usecase.dart';
import '../../domain/entities/dashboard_security_setting_item.dart';

class DashboardSecuritySettingsController extends GetxController {
  DashboardSecuritySettingsController(
    this._checkAirplaneMode,
    this._checkConnectivity,
    this._openAirplaneSettings,
    this._openWifiSettings,
    this._vpnLockdownService,
    this._cameraPermissionService,
    this._watchdog,
    this._lifecycleService,
    this._logger,
  );

  final CheckAirplaneModeUseCase _checkAirplaneMode;
  final CheckConnectivityUseCase _checkConnectivity;
  final OpenAirplaneModeSettingsUseCase _openAirplaneSettings;
  final OpenWifiSettingsUseCase _openWifiSettings;
  final ExamVpnLockdownService _vpnLockdownService;
  final CameraPermissionService _cameraPermissionService;
  final SecurityWatchdogService _watchdog;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final settings = <DashboardSecuritySettingItem>[].obs;
  final isRefreshing = false.obs;

  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;
  Timer? _pollTimer;
  AppLifecycleState? _lastLifecycleState;

  bool get _showVpn => !Deployment.instance.isDemo;

  List<DashboardSecuritySettingType> get _settingTypes => [
        if (_showVpn) DashboardSecuritySettingType.vpn,
        DashboardSecuritySettingType.airplane,
        DashboardSecuritySettingType.wifi,
        DashboardSecuritySettingType.camera,
      ];

  bool get _isAnyBusy => settings.any((item) => item.isBusy);

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
    unawaited(refreshAll());
    _lastLifecycleState = _lifecycleService.currentState;
    _listenForResume();
    _startPolling();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    unawaited(_lifecycleSubscription?.cancel());
    super.onClose();
  }

  void _initializeSettings() {
    settings.assignAll(
      _settingTypes.map(
        (type) => DashboardSecuritySettingItem(type: type, isEnabled: false),
      ),
    );
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
    if (isClosed) return;
    await refreshAll();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      AppConstants.airplaneModePollInterval,
      (_) => unawaited(refreshAll(silent: true)),
    );
  }

  Future<void> refreshAll({bool silent = false}) async {
    if (isClosed) return;
    if (!silent) {
      isRefreshing.value = true;
    }

    try {
      final updated = <DashboardSecuritySettingItem>[];
      for (final type in _settingTypes) {
        updated.add(await _loadSettingState(type));
      }
      if (!isClosed) {
        settings.assignAll(updated);
      }
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error('refreshAll failed', error: e, stackTrace: st);
      }
    } finally {
      if (!isClosed && !silent) {
        isRefreshing.value = false;
      }
    }
  }

  Future<DashboardSecuritySettingItem> _loadSettingState(
    DashboardSecuritySettingType type,
  ) async {
    final existing = settings.firstWhereOrNull((item) => item.type == type);
    final isBusy = existing?.isBusy ?? false;

    try {
      switch (type) {
        case DashboardSecuritySettingType.vpn:
          final active = await _vpnLockdownService.isActiveNative();
          final vpnDisabled = _watchdog.isRunning;
          return DashboardSecuritySettingItem(
            type: type,
            isEnabled: active,
            isBusy: isBusy,
            isToggleDisabled: vpnDisabled && active,
            disabledHint: vpnDisabled && active
                ? AppStrings.securityVpnCannotDisableDuringExam
                : null,
          );
        case DashboardSecuritySettingType.airplane:
          final result = await _checkAirplaneMode();
          return switch (result) {
            Success(:final data) => DashboardSecuritySettingItem(
                type: type,
                isEnabled: data.isEnabled,
                isBusy: isBusy,
              ),
            ErrorResult() => DashboardSecuritySettingItem(
                type: type,
                isEnabled: false,
                isBusy: isBusy,
                hasError: true,
              ),
          };
        case DashboardSecuritySettingType.wifi:
          final result = await _checkConnectivity();
          return switch (result) {
            Success(:final data) => DashboardSecuritySettingItem(
                type: type,
                isEnabled: data.isOnline,
                isBusy: isBusy,
              ),
            ErrorResult() => DashboardSecuritySettingItem(
                type: type,
                isEnabled: false,
                isBusy: isBusy,
                hasError: true,
              ),
          };
        case DashboardSecuritySettingType.camera:
          final granted = await _cameraPermissionService.isGranted;
          return DashboardSecuritySettingItem(
            type: type,
            isEnabled: granted,
            isBusy: isBusy,
          );
      }
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error('loadSettingState failed', error: e, stackTrace: st);
      }
      return DashboardSecuritySettingItem(
        type: type,
        isEnabled: false,
        isBusy: isBusy,
        hasError: true,
      );
    }
  }

  Future<void> toggle(
    DashboardSecuritySettingType type,
    bool targetEnabled,
  ) async {
    if (isClosed || isRefreshing.value || _isAnyBusy) return;

    final index = settings.indexWhere((item) => item.type == type);
    if (index == -1) return;

    final current = settings[index];
    if (current.isToggleDisabled) return;

    _setRowBusy(type, true);

    try {
      switch (type) {
        case DashboardSecuritySettingType.vpn:
          await _toggleVpn(targetEnabled);
        case DashboardSecuritySettingType.airplane:
          final result = await _openAirplaneSettings();
          if (result is ErrorResult<void>) {
            AppErrorToast.show(AppStrings.unableToOpenSettings);
          }
        case DashboardSecuritySettingType.wifi:
          final wifiResult = await _openWifiSettings();
          if (wifiResult is ErrorResult<void>) {
            AppErrorToast.show(AppStrings.unableToOpenWifiSettings);
          }
        case DashboardSecuritySettingType.camera:
          await _toggleCamera(targetEnabled);
      }
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error('toggle failed', error: e, stackTrace: st);
      }
      AppErrorToast.show(AppStrings.somethingWentWrong);
    } finally {
      if (!isClosed) {
        _setRowBusy(type, false);
        await refreshAll(silent: true);
      }
    }
  }

  Future<void> _toggleVpn(bool targetEnabled) async {
    if (targetEnabled) {
      final prepared = await _vpnLockdownService.prepare();
      if (!prepared) {
        AppErrorToast.show(AppStrings.somethingWentWrong);
        return;
      }
      final started = await _vpnLockdownService.startLockdown();
      if (!started) {
        AppErrorToast.show(AppStrings.somethingWentWrong);
      }
      return;
    }

    if (_watchdog.isRunning) return;
    await _vpnLockdownService.stopLockdown();
  }

  Future<void> _toggleCamera(bool targetEnabled) async {
    if (targetEnabled) {
      if (await _cameraPermissionService.isPermanentlyDenied) {
        final opened = await _cameraPermissionService.openSettings();
        if (!opened) {
          AppErrorToast.show(AppStrings.unableToOpenSettings);
        }
        return;
      }

      final granted = await _cameraPermissionService.ensureGranted();
      if (!granted) {
        AppErrorToast.show(AppStrings.cameraPermissionMustBeGranted);
      }
      return;
    }

    final granted = await _cameraPermissionService.isGranted;
    if (!granted) return;

    final opened = await _cameraPermissionService.openSettings();
    if (!opened) {
      AppErrorToast.show(AppStrings.unableToOpenSettings);
    }
  }

  void _setRowBusy(DashboardSecuritySettingType type, bool isBusy) {
    final index = settings.indexWhere((item) => item.type == type);
    if (index == -1) return;
    settings[index] = settings[index].copyWith(isBusy: isBusy);
    settings.refresh();
  }

  static String titleFor(DashboardSecuritySettingType type) => switch (type) {
        DashboardSecuritySettingType.vpn => AppStrings.securityVpnTitle,
        DashboardSecuritySettingType.airplane => AppStrings.securityAirplaneTitle,
        DashboardSecuritySettingType.wifi => AppStrings.securityWifiTitle,
        DashboardSecuritySettingType.camera => AppStrings.securityCameraTitle,
      };

  static String descriptionFor(DashboardSecuritySettingType type) =>
      switch (type) {
        DashboardSecuritySettingType.vpn => AppStrings.securityVpnDescription,
        DashboardSecuritySettingType.airplane =>
          AppStrings.securityAirplaneDescription,
        DashboardSecuritySettingType.wifi => AppStrings.securityWifiDescription,
        DashboardSecuritySettingType.camera =>
          AppStrings.securityCameraDescription,
      };
}
