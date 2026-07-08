import 'dart:io' show Platform;

import 'package:airplane_mode_checker/airplane_mode_checker.dart' as amc;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:root_checker_plus/root_checker_plus.dart';

import '../../../../core/services/platform_settings_service.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

class SecurityLocalDataSource {
  SecurityLocalDataSource(this._platformSettings, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final PlatformSettingsService _platformSettings;
  final Connectivity _connectivity;
  final amc.AirplaneModeChecker _airplaneChecker =
      amc.AirplaneModeChecker.instance;

  Future<DeviceIntegrityStatus> checkDeviceIntegrity() async {
    final isRooted = Platform.isAndroid
        ? (await RootCheckerPlus.isRootChecker()) ?? false
        : false;
    final isJailbroken = Platform.isIOS
        ? (await RootCheckerPlus.isJailbreak()) ?? false
        : false;
    final isDeveloperMode = Platform.isAndroid
        ? (await RootCheckerPlus.isDeveloperMode()) ?? false
        : false;

    return DeviceIntegrityStatus(
      isRooted: isRooted,
      isJailbroken: isJailbroken,
      isDeveloperModeEnabled: isDeveloperMode,
      isCompromised: isRooted || isJailbroken || isDeveloperMode,
    );
  }

  Future<AirplaneModeStatus> checkAirplaneMode() async {
    final status = await _airplaneChecker.checkAirplaneMode(
      defaultValue: amc.AirplaneModeStatus.off,
    );
    return AirplaneModeStatus(isEnabled: status == amc.AirplaneModeStatus.on);
  }

  Stream<AirplaneModeStatus> observeAirplaneMode() {
    return _airplaneChecker
        .listenAirplaneMode(defaultValue: amc.AirplaneModeStatus.off)
        .map(
          (status) => AirplaneModeStatus(
            isEnabled: status == amc.AirplaneModeStatus.on,
          ),
        );
  }

  Future<ConnectivityStatus> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return _mapConnectivityResults(results);
  }

  Stream<ConnectivityStatus> observeConnectivity() {
    return _connectivity.onConnectivityChanged.map(_mapConnectivityResults);
  }

  ConnectivityStatus _mapConnectivityResults(List<ConnectivityResult> results) {
    final hasWifi = results.contains(ConnectivityResult.wifi);
    return ConnectivityStatus(isOnline: hasWifi);
  }

  Future<void> openWifiSettings() =>
      _platformSettings.openWifiSettings();

  Future<void> openAirplaneModeSettings() =>
      _platformSettings.openAirplaneModeSettings();

  Future<void> openDeveloperModeSettings() =>
      _platformSettings.openDeveloperModeSettings();
}
