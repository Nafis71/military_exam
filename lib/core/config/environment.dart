import 'build_mode.dart';
import '../constants/app_strings.dart';

class Environment {
  const Environment({
    required this.appName,
    required this.baseUrl,
    required this.uploadBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.enableNetworkLogs,
    required this.enableMockExamData,
    required this.isDemo,
    required this.allowSideload,
    required this.strictExamIntegrity,
    required this.securityPollingIntervalSeconds,
    required this.examAutoSubmitTimeoutSeconds,
  });

  final String appName;
  final String baseUrl;
  final String uploadBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableNetworkLogs;
  final bool enableMockExamData;

  /// When true, no API calls are made; all data is served from on-device storage.
  final bool isDemo;

  /// When true, APK sideload / unknown install sources are allowed for RASP.
  final bool allowSideload;

  /// When true, block unlocked bootloader, custom ROM, and spoofing signals.
  /// Enabled for all build modes; sideload policy is separate via [allowSideload].
  final bool strictExamIntegrity;

  final int securityPollingIntervalSeconds;
  final int examAutoSubmitTimeoutSeconds;

  static Environment forMode(BuildMode mode) {
    switch (mode) {
      case BuildMode.development:
        return const Environment(
          appName: AppStrings.appNameDev,
          baseUrl: 'https://ex-api.divergenttechbd.com',
          uploadBaseUrl: 'https://staging-upload.military-exam.local',
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
          enableNetworkLogs: true,
          enableMockExamData: true,
          isDemo: false,
          allowSideload: true,
          strictExamIntegrity: true,
          securityPollingIntervalSeconds: 3,
          examAutoSubmitTimeoutSeconds: 30,
        );
      case BuildMode.staging:
        return const Environment(
          appName: AppStrings.appNameStaging,
          baseUrl: 'https://ex-api.divergenttechbd.com',
          uploadBaseUrl: 'https://staging-upload.military-exam.local',
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
          enableNetworkLogs: true,
          enableMockExamData: false,
          isDemo: false,
          allowSideload: true,
          strictExamIntegrity: true,
          securityPollingIntervalSeconds: 3,
          examAutoSubmitTimeoutSeconds: 30,
        );
      case BuildMode.production:
        return const Environment(
          appName: AppStrings.appName,
          baseUrl: 'https://ex-api.divergenttechbd.com',
          uploadBaseUrl: 'https://upload.military-exam.local',
          connectTimeout: Duration(seconds: 15),
          receiveTimeout: Duration(seconds: 15),
          enableNetworkLogs: false,
          enableMockExamData: false,
          isDemo: false,
          allowSideload: false,
          strictExamIntegrity: true,
          securityPollingIntervalSeconds: 3,
          examAutoSubmitTimeoutSeconds: 15,
        );
      case BuildMode.demo:
        return const Environment(
          appName: AppStrings.appNameDemo,
          baseUrl: '',
          uploadBaseUrl: '',
          connectTimeout: Duration(seconds: 1),
          receiveTimeout: Duration(seconds: 1),
          enableNetworkLogs: false,
          enableMockExamData: true,
          isDemo: true,
          allowSideload: true,
          strictExamIntegrity: true,
          securityPollingIntervalSeconds: 3,
          examAutoSubmitTimeoutSeconds: 30,
        );
    }
  }
}
