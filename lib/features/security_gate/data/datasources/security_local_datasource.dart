import 'package:airplane_mode_checker/airplane_mode_checker.dart' as amc;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/services/platform_settings_service.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/config/deployment.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

class SecurityLocalDataSource {
  SecurityLocalDataSource(this._platformSettings, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final PlatformSettingsService _platformSettings;
  final Connectivity _connectivity;
  final amc.AirplaneModeChecker _airplaneChecker =
      amc.AirplaneModeChecker.instance;

  Future<DeviceIntegrityStatus> checkDeviceIntegrity() async {
    final rasp = await SecurityService.instance.recheck();
    final isDeveloperMode = detectDeveloperMode(rasp.detectedThreats);
    final blockEmulator = Deployment.instance.isProduction;
    final isDeveloperModeOnly = isDeveloperModeOnlyIssue(
      status: rasp,
      blockEmulator: blockEmulator,
    );
    final isCompromised = !isDeveloperModeOnly &&
        (rasp.hasCriticalThreat ||
            rasp.posture == SecurityPosture.checkFailed ||
            rasp.isEnvironmentSpoofed ||
            (Deployment.instance.strictExamIntegrity && rasp.isCustomRom));

    return DeviceIntegrityStatus(
      isRooted: rasp.isRooted,
      isJailbroken: rasp.isJailbroken,
      isDeveloperModeEnabled: isDeveloperMode,
      isHooked: rasp.isHooked,
      isDebuggerAttached: rasp.isDebuggerAttached,
      isEmulator: rasp.isEmulator,
      hasTestKeys: rasp.hasTestKeys,
      isIntegrityViolated: rasp.isIntegrityViolated,
      isEnvironmentSpoofed: rasp.isEnvironmentSpoofed,
      isCustomRom: rasp.isCustomRom,
      checkFailed: rasp.posture == SecurityPosture.checkFailed,
      isCompromised: isCompromised,
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
