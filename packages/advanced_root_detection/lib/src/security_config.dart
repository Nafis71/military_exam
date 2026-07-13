/// Allowlist of trusted app stores / install sources.
enum AppStore {
  /// Google Play Store.
  googlePlay,

  /// Amazon Appstore.
  amazonAppstore,

  /// Huawei AppGallery.
  huaweiAppGallery,

  /// Samsung Galaxy Store.
  samsungGalaxyStore,

  /// MDM / enterprise deployment.
  mdm,

  /// TestFlight (iOS).
  testFlight,

  /// Apple App Store.
  appleAppStore,
}

/// Android-specific configuration for security checks.
class AndroidConfig {
  /// Expected package name of the application.
  ///
  /// If provided, the plugin verifies at runtime that the running package
  /// matches this value (repackaging detection).
  final String? packageName;

  /// List of expected APK signing certificate SHA-256 fingerprints (hex, no colons).
  ///
  /// Example: `['A1B2C3...']`
  final List<String> signingCertHashes;

  /// Trusted install sources. Installs from sources not in this list are
  /// flagged as [ThreatCategory.untrustedSource].
  final List<AppStore> allowedInstallers;

  /// Whether to check if VPN is active (informational by default).
  final bool checkVpn;

  /// Whether to report developer mode / ADB as a threat.
  ///
  /// Defaults to `false` (informational only) because many legitimate
  /// developer devices have ADB enabled.
  final bool treatDeveloperModeAsThreat;

  /// When true, installs from unknown sources are not flagged.
  final bool allowSideload;

  /// When true, block unlocked bootloader, custom ROM, and spoofing signals.
  final bool strictExamIntegrity;

  /// Creates an [AndroidConfig].
  const AndroidConfig({
    this.packageName,
    this.signingCertHashes = const [],
    this.allowedInstallers = const [
      AppStore.googlePlay,
      AppStore.amazonAppstore,
    ],
    this.checkVpn = false,
    this.treatDeveloperModeAsThreat = false,
    this.allowSideload = false,
    this.strictExamIntegrity = false,
  });

  /// Converts to a map for passing over the MethodChannel.
  Map<String, dynamic> toMap() => {
        'packageName': packageName,
        'signingCertHashes': signingCertHashes,
        'allowedInstallers': allowedInstallers.map((e) => e.name).toList(),
        'checkVpn': checkVpn,
        'treatDeveloperModeAsThreat': treatDeveloperModeAsThreat,
        'allowSideload': allowSideload,
        'strictExamIntegrity': strictExamIntegrity,
      };
}

/// iOS-specific configuration for security checks.
class IOSConfig {
  /// Expected bundle identifiers.
  final List<String> bundleIds;

  /// Expected Apple Developer Team ID.
  final String? teamId;

  /// Creates an [IOSConfig].
  const IOSConfig({
    this.bundleIds = const [],
    this.teamId,
  });

  /// Converts to a map for passing over the MethodChannel.
  Map<String, dynamic> toMap() => {
        'bundleIds': bundleIds,
        'teamId': teamId,
      };
}

/// Top-level configuration passed to [AdvanceRootDetection.performCheck].
///
/// Example:
/// ```dart
/// final config = SecurityConfig(
///   android: AndroidConfig(
///     packageName: 'com.example.app',
///     signingCertHashes: ['A1B2C3...'],
///   ),
///   ios: IOSConfig(bundleIds: ['com.example.app'], teamId: 'ABC123'),
///   monitoringInterval: Duration(seconds: 30),
/// );
/// ```
class SecurityConfig {
  /// Android-specific settings. If `null`, defaults are used.
  final AndroidConfig android;

  /// iOS-specific settings. If `null`, defaults are used.
  final IOSConfig ios;

  /// How often background monitoring re-checks for threats.
  ///
  /// Defaults to 30 seconds. Set to `Duration.zero` to disable periodic checks.
  final Duration monitoringInterval;

  /// Creates a [SecurityConfig].
  const SecurityConfig({
    this.android = const AndroidConfig(),
    this.ios = const IOSConfig(),
    this.monitoringInterval = const Duration(seconds: 30),
  });

  /// Converts to a map for passing over the MethodChannel.
  Map<String, dynamic> toMap() => {
        'android': android.toMap(),
        'ios': ios.toMap(),
        'monitoringIntervalSeconds': monitoringInterval.inSeconds,
      };
}
