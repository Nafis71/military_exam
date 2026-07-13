import 'package:flutter/services.dart';

import 'platform_interface.dart';
import 'security_config.dart';
import 'threat_report.dart';

/// Default [AdvanceRootDetectionPlatform] implementation using [MethodChannel].
class MethodChannelAdvanceRootDetection extends AdvanceRootDetectionPlatform {
  /// The MethodChannel used for one-shot calls.
  static const MethodChannel _methodChannel =
      MethodChannel('advanced_root_detection/methods');

  /// The EventChannel used for streaming threats during monitoring.
  static const EventChannel _eventChannel =
      EventChannel('advanced_root_detection/threats');

  Stream<Threat>? _threatStream;

  @override
  Future<ThreatReport> performCheck(SecurityConfig config) async {
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'performCheck',
      config.toMap(),
    );
    if (result == null) {
      return ThreatReport(detectedThreats: [], checkedAt: DateTime.now());
    }
    return ThreatReport.fromMap(result);
  }

  @override
  Stream<Threat> get threatStream {
    _threatStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Threat.fromMap(event as Map<dynamic, dynamic>));
    return _threatStream!;
  }

  @override
  Future<void> startMonitoring(SecurityConfig config) async {
    await _methodChannel.invokeMethod<void>(
      'startMonitoring',
      config.toMap(),
    );
  }

  @override
  Future<void> stopMonitoring() async {
    await _methodChannel.invokeMethod<void>('stopMonitoring');
  }

  @override
  Future<bool> verifyBeforeSensitiveOp(SecurityConfig config) async {
    final result = await _methodChannel.invokeMethod<bool>(
      'verifyBeforeSensitiveOp',
      config.toMap(),
    );
    return result ?? false;
  }
}
