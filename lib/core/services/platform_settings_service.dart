import 'dart:io' show Platform;

import 'package:app_settings/app_settings.dart';

/// Opens system settings (e.g. for Airplane Mode or Developer Mode).
class PlatformSettingsService {
  /// Settings can be opened on Android and iOS. Developer mode has no direct
  /// deep link on iOS, so the default Settings page is opened instead.
  bool get isDeveloperModeSettingsSupported =>
      Platform.isAndroid || Platform.isIOS;

  /// Settings can be opened on Android and iOS. Airplane mode has no direct
  /// deep link on iOS, so the default Settings page is opened instead.
  bool get isAirplaneModeSettingsSupported =>
      Platform.isAndroid || Platform.isIOS;

  Future<void> openDeveloperModeSettings() async {
    if (Platform.isAndroid) {
      await AppSettings.openAppSettings(
        type: AppSettingsType.developer,
        asAnotherTask: true,
      );
      return;
    }

    if (Platform.isIOS) {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
      return;
    }

    throw UnsupportedError(
      'Developer mode settings are only available on Android and iOS.',
    );
  }

  /// Opens WiFi / wireless settings on Android and iOS.
  bool get isWifiSettingsSupported => Platform.isAndroid || Platform.isIOS;

  Future<void> openWifiSettings() async {
    if (Platform.isAndroid) {
      await AppSettings.openAppSettings(
        type: AppSettingsType.wifi,
        asAnotherTask: true,
      );
      return;
    }

    if (Platform.isIOS) {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
      return;
    }

    throw UnsupportedError(
      'WiFi settings are only available on Android and iOS.',
    );
  }

  Future<void> openAirplaneModeSettings() async {
    if (Platform.isAndroid) {
      await AppSettings.openAppSettings(
        type: AppSettingsType.wireless,
        asAnotherTask: true,
      );
      return;
    }

    if (Platform.isIOS) {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
      return;
    }

    throw UnsupportedError(
      'Airplane mode settings are only available on Android and iOS.',
    );
  }
}
