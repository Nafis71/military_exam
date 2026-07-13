import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'security_config.dart';
import 'threat_report.dart';

/// The platform interface for [advance_root_detection].
///
/// Platform implementations must extend this class rather than implement it
/// so that any added methods do not break existing implementations.
abstract class AdvanceRootDetectionPlatform extends PlatformInterface {
  /// Constructs an [AdvanceRootDetectionPlatform].
  AdvanceRootDetectionPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdvanceRootDetectionPlatform? _instance;

  /// The default instance of [AdvanceRootDetectionPlatform] to use.
  static AdvanceRootDetectionPlatform get instance {
    return _instance!;
  }

  /// Sets the default instance of [AdvanceRootDetectionPlatform].
  ///
  /// Platform implementations should call this in their
  /// `registerWith()` function.
  static set instance(AdvanceRootDetectionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Performs a full security check and returns a [ThreatReport].
  ///
  /// Throws a [PlatformException] if the native layer encounters a fatal error.
  Future<ThreatReport> performCheck(SecurityConfig config);

  /// Returns a [Stream] of individual [Threat]s detected during monitoring.
  Stream<Threat> get threatStream;

  /// Starts background monitoring with the given [config].
  Future<void> startMonitoring(SecurityConfig config);

  /// Stops background monitoring.
  Future<void> stopMonitoring();

  /// Performs a quick synchronous-style check intended for use before
  /// sensitive operations (e.g. payments).
  ///
  /// Returns `true` if the environment is considered safe (no high/critical threats).
  Future<bool> verifyBeforeSensitiveOp(SecurityConfig config);
}
