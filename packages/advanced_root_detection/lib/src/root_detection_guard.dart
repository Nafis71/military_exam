import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'advance_root_detection_base.dart';
import 'security_config.dart';
import 'severity.dart';
import 'threat_report.dart';

/// A widget that blocks access to [child] when the device is rooted (Android)
/// or jailbroken (iOS).
///
/// Drop it at the top of your widget tree, wrapping your app's root widget:
///
/// ```dart
/// void main() {
///   runApp(
///     RootDetectionGuard(
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
///
/// While the check is in progress a full-screen loader is shown. If a threat
/// is detected an "Access Denied" screen is displayed and the app cannot be
/// used until the issue is resolved. On web [child] is always shown.
class RootDetectionGuard extends StatefulWidget {
  /// The widget to display when the device passes all security checks.
  final Widget child;

  /// When `true` the guard is disabled and [child] is rendered immediately.
  /// Defaults to `false`. Set to `true` when running on the web where native
  /// security checks are not available.
  final bool isWeb;

  /// Optional [SecurityConfig] forwarded to [AdvanceRootDetection.performCheck].
  /// Defaults to [SecurityConfig()].
  final SecurityConfig config;

  /// Optional custom message displayed on the blocked screen when a threat is
  /// detected. If not provided, the detected threat description is shown.
  final String? blockedMessage;

  /// When `true` the guard is completely bypassed in debug builds
  /// (`kDebugMode == true`), allowing the app to run normally on a non-rooted
  /// device during development without triggering the blocked screen.
  ///
  /// **Never set this to `true` in production.** The flag has no effect in
  /// profile or release builds because [kDebugMode] is `false` there.
  ///
  /// Defaults to `false`.
  final bool bypassInDebugMode;

  const RootDetectionGuard({
    super.key,
    required this.child,
    this.isWeb = false,
    this.config = const SecurityConfig(),
    this.blockedMessage,
    this.bypassInDebugMode = false,
  });

  @override
  State<RootDetectionGuard> createState() => _RootDetectionGuardState();
}

class _RootDetectionGuardState extends State<RootDetectionGuard> {
  /// `null`  → check in progress
  /// `true`  → threat detected, show blocked screen
  /// `false` → clean, show child
  bool? _isCompromised;

  /// The detected threats (populated only when [_isCompromised] == `true`).
  List<Threat> _threats = [];

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    // Web or non-mobile platforms: skip native checks.
    if (widget.isWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      if (mounted) setState(() => _isCompromised = false);
      return;
    }

    // Debug builds: bypass check if the flag is set.
    if (kDebugMode && widget.bypassInDebugMode) {
      if (mounted) setState(() => _isCompromised = false);
      return;
    }

    bool compromised = false;
    List<Threat> threats = [];

    try {
      final report = await AdvanceRootDetection()
          .performCheck(widget.config);

      // Block only on definitive threat categories:
      //   • privilegedAccess  — root / jailbreak indicators
      //   • runtimeManipulation — Frida, Xposed, Shamiko hooks, Zygisk injection
      //   • integrityViolation — APK tampered / wrong signer
      //
      // We intentionally do NOT block on hasCriticalThreat alone because that
      // would also catch high-severity supplementary findings such as an unlocked
      // bootloader on a developer phone, which is not the same as a rooted device.
      compromised = report.isPrivilegedAccess ||
          report.isRuntimeManipulated ||
          report.isIntegrityViolated;

      threats = report.detectedThreats
          .where((t) =>
              t.severity == Severity.high || t.severity == Severity.critical)
          .toList();
    } catch (_) {
      // If the check itself throws (e.g. during testing), treat as compromised
      // to fail securely.
      compromised = true;
    }

    if (mounted) {
      setState(() {
        _isCompromised = compromised;
        _threats = threats;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Web or debug bypass: always allow through.
    if (widget.isWeb || (kDebugMode && widget.bypassInDebugMode)) {
      return widget.child;
    }

    // Still checking.
    if (_isCompromised == null) return _loadingScreen();

    // Threat found: block access.
    if (_isCompromised == true) return _blockedScreen();

    // All clear.
    return widget.child;
  }

  Widget _loadingScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _blockedScreen() {
    // Pick the most descriptive threat message to show the user.
    final primaryThreat = _threats.isNotEmpty ? _threats.first : null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Colors.red,
                    size: 96,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.blockedMessage ??
                        (primaryThreat != null
                            ? primaryThreat.description
                            : 'This device is rooted or jailbroken.\n'
                                'The app cannot run on a compromised device.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  if (_threats.length > 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_threats.length} security issues detected.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Close App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => SystemNavigator.pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
