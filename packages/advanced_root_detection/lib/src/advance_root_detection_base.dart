import 'method_channel_impl.dart';
import 'platform_interface.dart';
import 'security_config.dart';
import 'threat_report.dart';

/// Entry point for the `advance_root_detection` plugin.
///
/// ## Usage
/// ```dart
/// final shield = AdvanceRootDetection();
///
/// // One-shot full check
/// final ThreatReport report = await shield.performCheck(SecurityConfig(
///   android: AndroidConfig(
///     packageName: 'com.example.app',
///     signingCertHashes: ['A1B2C3...'],
///   ),
///   ios: IOSConfig(bundleIds: ['com.example.app'], teamId: 'ABC123'),
/// ));
///
/// if (report.isPrivilegedAccess) {
///   // Root / jailbreak detected — block sensitive operations
/// }
///
/// // Stream-based monitoring
/// shield.threatStream.listen((threat) {
///   print('New threat: $threat');
/// });
/// await shield.startMonitoring(SecurityConfig());
///
/// // Verify before a payment
/// final safe = await shield.verifyBeforeSensitiveOp(SecurityConfig());
/// ```
class AdvanceRootDetection {
  /// Creates an [AdvanceRootDetection] instance.
  ///
  /// The first call sets up the [AdvanceRootDetectionPlatform] singleton.
  AdvanceRootDetection() {
    if (!_initialised) {
      AdvanceRootDetectionPlatform.instance =
          MethodChannelAdvanceRootDetection();
      _initialised = true;
    }
  }

  static bool _initialised = false;

  AdvanceRootDetectionPlatform get _platform =>
      AdvanceRootDetectionPlatform.instance;

  /// Performs a full security check and returns a [ThreatReport].
  ///
  /// Each call invokes all enabled detectors on the native side and aggregates
  /// results into a single report.
  ///
  /// ```dart
  /// final report = await shield.performCheck(SecurityConfig());
  /// print(report.detectedThreats);
  /// ```
  Future<ThreatReport> performCheck([SecurityConfig config = const SecurityConfig()]) =>
      _platform.performCheck(config);

  /// A broadcast [Stream] of [Threat] events emitted during background monitoring.
  ///
  /// Subscribe before calling [startMonitoring].
  ///
  /// ```dart
  /// shield.threatStream.listen((t) => print(t));
  /// await shield.startMonitoring(SecurityConfig());
  /// ```
  Stream<Threat> get threatStream => _platform.threatStream;

  /// Starts background monitoring. Threats are emitted via [threatStream].
  ///
  /// Monitoring runs at the interval specified in [config.monitoringInterval]
  /// (default 30 s). Calling this while monitoring is already active is a no-op.
  Future<void> startMonitoring([SecurityConfig config = const SecurityConfig()]) =>
      _platform.startMonitoring(config);

  /// Stops background monitoring.
  Future<void> stopMonitoring() => _platform.stopMonitoring();

  /// Quick safety check for use immediately before sensitive operations
  /// (e.g. payment flows, biometric prompts).
  ///
  /// Returns `true` when the environment is considered safe (no high/critical threats).
  ///
  /// ```dart
  /// if (await shield.verifyBeforeSensitiveOp()) {
  ///   proceedWithPayment();
  /// }
  /// ```
  Future<bool> verifyBeforeSensitiveOp([SecurityConfig config = const SecurityConfig()]) =>
      _platform.verifyBeforeSensitiveOp(config);
}
