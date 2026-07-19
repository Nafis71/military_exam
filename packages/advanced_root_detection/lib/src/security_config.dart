/// Which detectors [AdvanceRootDetection.performCheck] runs.
enum SecurityCheckScope {
  /// Root, jailbreak, developer mode, and custom ROM only.
  essential,

  /// All detectors (hooks, emulator, native, tampering, etc.).
  full,
}

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

  /// When true, skip root detection on Android emulators (demo/staging QA).
  final bool skipRootOnEmulator;

  /// When true, skip developer-mode detection on Android emulators (demo/staging QA).
  final bool skipDeveloperModeOnEmulator;

  /// When true, skip developer-mode detection on all Android devices.
  final bool skipDeveloperMode;

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
    this.skipRootOnEmulator = false,
    this.skipDeveloperModeOnEmulator = false,
    this.skipDeveloperMode = false,
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
        'skipRootOnEmulator': skipRootOnEmulator,
        'skipDeveloperModeOnEmulator': skipDeveloperModeOnEmulator,
        'skipDeveloperMode': skipDeveloperMode,
      };
}

/// iOS-specific configuration for security checks.
class IOSConfig {
  /// Expected bundle identifiers.
  final List<String> bundleIds;

  /// Expected Apple Developer Team ID.
  final String? teamId;

  /// When true, skip jailbreak detection on iOS simulator (demo/staging QA).
  final bool skipJailbreakOnSimulator;

  /// Creates an [IOSConfig].
  const IOSConfig({
    this.bundleIds = const [],
    this.teamId,
    this.skipJailbreakOnSimulator = false,
  });

  /// Converts to a map for passing over the MethodChannel.
  Map<String, dynamic> toMap() => {
        'bundleIds': bundleIds,
        'teamId': teamId,
        'skipJailbreakOnSimulator': skipJailbreakOnSimulator,
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
  /// Which integrity checks to run. Defaults to [SecurityCheckScope.essential].
  final SecurityCheckScope scope;

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
    this.scope = SecurityCheckScope.essential,
    this.android = const AndroidConfig(),
    this.ios = const IOSConfig(),
    this.monitoringInterval = const Duration(seconds: 30),
  });

  /// Converts to a map for passing over the MethodChannel.
  Map<String, dynamic> toMap() => {
        'scope': scope.name,
        'android': android.toMap(),
        'ios': ios.toMap(),
        'monitoringIntervalSeconds': monitoringInterval.inSeconds,
      };
}
