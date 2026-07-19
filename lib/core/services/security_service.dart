import 'dart:io' show Platform;

import 'package:advanced_root_detection/advanced_root_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../config/deployment.dart';

enum SecurityPosture { safe, unsafe, checkFailed }

class SecurityStatus {
  const SecurityStatus({
    required this.isRooted,
    required this.isJailbroken,
    required this.isHooked,
    required this.isDebuggerAttached,
    required this.isEmulator,
    required this.hasTestKeys,
    required this.isIntegrityViolated,
    required this.isUntrustedInstall,
    required this.isEnvironmentSpoofed,
    required this.isCustomRom,
    required this.posture,
    required this.checkedAt,
    this.detectedThreats = const [],
    this.failureReason,
    this.primaryBlockReason,
  });

  final bool isRooted;
  final bool isJailbroken;
  final bool isHooked;
  final bool isDebuggerAttached;
  final bool isEmulator;
  final bool hasTestKeys;
  final bool isIntegrityViolated;
  final bool isUntrustedInstall;
  final bool isEnvironmentSpoofed;
  final bool isCustomRom;
  final SecurityPosture posture;
  final DateTime checkedAt;
  final List<Threat> detectedThreats;
  final String? failureReason;
  final String? primaryBlockReason;

  bool get isUnsafe => posture != SecurityPosture.safe;

  bool get hasCriticalThreat =>
      posture == SecurityPosture.checkFailed ||
      posture == SecurityPosture.unsafe;

  factory SecurityStatus.unsafe({
    required String failureReason,
    DateTime? checkedAt,
  }) =>
      SecurityStatus(
        isRooted: true,
        isJailbroken: true,
        isHooked: true,
        isDebuggerAttached: true,
        isEmulator: true,
        hasTestKeys: true,
        isIntegrityViolated: true,
        isUntrustedInstall: true,
        isEnvironmentSpoofed: true,
        isCustomRom: true,
        posture: SecurityPosture.checkFailed,
        checkedAt: checkedAt ?? DateTime.now(),
        failureReason: failureReason,
        primaryBlockReason: failureReason,
      );

  /// Hard-block issues for essential scope: root, jailbreak, custom ROM (strict).
  bool hasBlockingIntegrityIssue({required bool strictExamIntegrity}) =>
      posture == SecurityPosture.checkFailed ||
      isRooted ||
      isJailbroken ||
      (strictExamIntegrity && isCustomRom);

  factory SecurityStatus.fromReport(
    ThreatReport report, {
    required bool allowSideload,
    required bool strictExamIntegrity,
    required bool blockEmulator,
    SecurityCheckScope scope = SecurityCheckScope.essential,
  }) {
    if (scope == SecurityCheckScope.essential) {
      return _fromEssentialReport(
        report,
        strictExamIntegrity: strictExamIntegrity,
      );
    }
    return _fromFullReport(
      report,
      allowSideload: allowSideload,
      strictExamIntegrity: strictExamIntegrity,
      blockEmulator: blockEmulator,
    );
  }

  static SecurityStatus _fromEssentialReport(
    ThreatReport report, {
    required bool strictExamIntegrity,
  }) {
    final threats = report.detectedThreats;
    final isCustomRom = detectCustomRom(threats);
    final isRooted = Platform.isAndroid && detectRootThreat(threats);
    final isJailbroken = Platform.isIOS && detectJailbreakThreat(threats);
    final isDeveloperMode = detectDeveloperMode(threats);
    final isUnsafe =
        isRooted || isJailbroken || (strictExamIntegrity && isCustomRom);

    return SecurityStatus(
      isRooted: isRooted,
      isJailbroken: isJailbroken,
      isHooked: false,
      isDebuggerAttached: isDeveloperMode,
      isEmulator: false,
      hasTestKeys: false,
      isIntegrityViolated: false,
      isUntrustedInstall: false,
      isEnvironmentSpoofed: false,
      isCustomRom: isCustomRom,
      posture: isUnsafe ? SecurityPosture.unsafe : SecurityPosture.safe,
      checkedAt: report.checkedAt,
      detectedThreats: threats,
      primaryBlockReason: isRooted
          ? _rootThreatReason(threats)
          : isJailbroken
              ? _jailbreakThreatReason(threats)
              : isCustomRom && strictExamIntegrity
                  ? _customRomThreatReason(threats)
                  : null,
    );
  }

  static SecurityStatus _fromFullReport(
    ThreatReport report, {
    required bool allowSideload,
    required bool strictExamIntegrity,
    required bool blockEmulator,
  }) {
    final threats = report.detectedThreats;
    final blocking = blockingThreats(
      threats,
      allowSideload: allowSideload,
      strictExamIntegrity: strictExamIntegrity,
      blockEmulator: blockEmulator,
    );
    final compositeMedium = hasCompositeMediumPrivilegedThreats(
      threats,
      strictExamIntegrity: strictExamIntegrity,
    );

    final isRooted = Platform.isAndroid &&
        (hasThreatInCategory(
          threats,
          ThreatCategory.privilegedAccess,
          allowSideload: allowSideload,
          strictExamIntegrity: strictExamIntegrity,
          blockEmulator: blockEmulator,
        ) ||
            detectCustomRom(threats));
    final isJailbroken = Platform.isIOS &&
        hasThreatInCategory(
          threats,
          ThreatCategory.privilegedAccess,
          allowSideload: allowSideload,
          strictExamIntegrity: strictExamIntegrity,
          blockEmulator: blockEmulator,
        );
    final isHooked = hasThreatInCategory(
      threats,
      ThreatCategory.runtimeManipulation,
      allowSideload: allowSideload,
      strictExamIntegrity: strictExamIntegrity,
      blockEmulator: blockEmulator,
    );
    final isDebuggerAttached = hasThreatInCategory(
      threats,
      ThreatCategory.debuggerAttached,
      allowSideload: allowSideload,
      strictExamIntegrity: strictExamIntegrity,
      blockEmulator: blockEmulator,
    );
    final isEmulator = blockEmulator &&
        hasThreatInCategory(
          threats,
          ThreatCategory.analysisEnvironment,
          allowSideload: allowSideload,
          strictExamIntegrity: strictExamIntegrity,
          blockEmulator: blockEmulator,
        );
    final hasTestKeys = detectTestKeys(threats);
    final isEnvironmentSpoofed = detectEnvironmentSpoofed(threats);
    final isCustomRom = detectCustomRom(threats);
    final isIntegrityViolated = threats.any(
          (threat) => threat.category == ThreatCategory.integrityViolation,
        ) ||
        isEnvironmentSpoofed;
    final isUntrustedInstall = !allowSideload &&
        threats.any(
          (threat) => threat.category == ThreatCategory.untrustedSource,
        );

    final isUnsafe = blocking.isNotEmpty ||
        compositeMedium ||
        isIntegrityViolated ||
        hasTestKeys ||
        isRooted ||
        isJailbroken ||
        isHooked ||
        isDebuggerAttached ||
        isEmulator ||
        isUntrustedInstall ||
        isEnvironmentSpoofed ||
        (strictExamIntegrity && isCustomRom);

    return SecurityStatus(
      isRooted: isRooted,
      isJailbroken: isJailbroken,
      isHooked: isHooked,
      isDebuggerAttached: isDebuggerAttached,
      isEmulator: isEmulator,
      hasTestKeys: hasTestKeys,
      isIntegrityViolated: isIntegrityViolated,
      isUntrustedInstall: isUntrustedInstall,
      isEnvironmentSpoofed: isEnvironmentSpoofed,
      isCustomRom: isCustomRom,
      posture: isUnsafe ? SecurityPosture.unsafe : SecurityPosture.safe,
      checkedAt: report.checkedAt,
      detectedThreats: threats,
      primaryBlockReason: blocking.isNotEmpty
          ? blocking.first.description
          : compositeMedium
              ? 'Multiple privileged-access risk signals detected'
              : isEnvironmentSpoofed
                  ? _spoofingReason(threats)
                  : null,
    );
  }
}

class SecurityService {
  SecurityService._();

  static final SecurityService instance = SecurityService._();

  final AdvanceRootDetection _shield = AdvanceRootDetection();
  SecurityStatus? _lastStatus;

  SecurityStatus? get lastStatus => _lastStatus;

  SecurityConfig _buildConfig() {
    final deployment = Deployment.instance;
    final relaxSimulator = deployment.relaxSimulatorIntegrityChecks;
    final relaxDeveloperMode = deployment.relaxDeveloperModeChecks;
    return SecurityConfig(
      scope: SecurityCheckScope.essential,
      android: AndroidConfig(
        packageName: 'com.example.military_exam',
        allowSideload: deployment.allowSideload,
        strictExamIntegrity: deployment.strictExamIntegrity,
        treatDeveloperModeAsThreat: true,
        skipRootOnEmulator: relaxSimulator,
        skipDeveloperModeOnEmulator: relaxSimulator,
        skipDeveloperMode: relaxDeveloperMode,
        allowedInstallers: const [
          AppStore.googlePlay,
          AppStore.amazonAppstore,
          AppStore.mdm,
          AppStore.samsungGalaxyStore,
          AppStore.huaweiAppGallery,
        ],
      ),
      ios: IOSConfig(
        bundleIds: const ['com.example.military_exam'],
        skipJailbreakOnSimulator: relaxSimulator,
      ),
    );
  }

  SecurityCheckScope get _checkScope => _buildConfig().scope;

  Future<SecurityStatus> initialize() async {
    final allowSideload = Deployment.instance.allowSideload;
    final strictExamIntegrity = Deployment.instance.strictExamIntegrity;
    final blockEmulator = Deployment.instance.isProduction;
    final scope = _checkScope;
    try {
      final report = await _shield.performCheck(_buildConfig());
      _logThreats(
        report,
        allowSideload: allowSideload,
        strictExamIntegrity: strictExamIntegrity,
        blockEmulator: blockEmulator,
        scope: scope,
      );
      _lastStatus = SecurityStatus.fromReport(
        report,
        allowSideload: allowSideload,
        strictExamIntegrity: strictExamIntegrity,
        blockEmulator: blockEmulator,
        scope: scope,
      );
    } on PlatformException catch (error, stackTrace) {
      if (kDebugMode) {
        Logger().e(
          'RASP PlatformException',
          error: error,
          stackTrace: stackTrace,
        );
      }
      _lastStatus = SecurityStatus.unsafe(
        failureReason: error.message ?? 'platform_channel_failed',
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        Logger().e('RASP check failed', error: error, stackTrace: stackTrace);
      }
      _lastStatus = SecurityStatus.unsafe(failureReason: error.toString());
    }
    return _lastStatus!;
  }

  Future<SecurityStatus> recheck() => initialize();

  Future<bool> verifyBeforeSensitiveOp() async {
    try {
      return await _shield.verifyBeforeSensitiveOp(_buildConfig());
    } catch (_) {
      return false;
    }
  }

  void _logThreats(
    ThreatReport report, {
    required bool allowSideload,
    required bool strictExamIntegrity,
    required bool blockEmulator,
    required SecurityCheckScope scope,
  }) {
    if (!kDebugMode) return;
    final logger = Logger();
    for (final threat in report.detectedThreats) {
      logger.w(
        'RASP threat [${threat.category.name}/${threat.severity.name}]: '
        '${threat.description}',
      );
    }
    if (scope == SecurityCheckScope.essential) {
      if (detectRootThreat(report.detectedThreats) ||
          detectJailbreakThreat(report.detectedThreats) ||
          (strictExamIntegrity && detectCustomRom(report.detectedThreats))) {
        logger.e('RASP essential-scope blocking threats detected');
      }
      return;
    }
    final blocking = blockingThreats(
      report.detectedThreats,
      allowSideload: allowSideload,
      strictExamIntegrity: strictExamIntegrity,
      blockEmulator: blockEmulator,
    );
    if (blocking.isNotEmpty) {
      logger.e('RASP blocking threats: ${blocking.length}');
    }
  }
}

String? _spoofingReason(List<Threat> threats) {
  for (final threat in threats) {
    final description = threat.description.toLowerCase();
    if (description.contains('spoofing')) {
      return threat.description;
    }
  }
  return null;
}

bool severityAtLeast(Severity severity, Severity minimum) {
  const order = [
    Severity.info,
    Severity.low,
    Severity.medium,
    Severity.high,
    Severity.critical,
  ];
  return order.indexOf(severity) >= order.indexOf(minimum);
}

bool isBootloaderWarnOnly(
  Threat threat, {
  required bool strictExamIntegrity,
}) {
  if (strictExamIntegrity) return false;

  final description = threat.description.toLowerCase();
  return description.contains('hardware attestation') ||
      description.contains('tee/trustzone') ||
      description.contains('bootloader') ||
      description.contains('verifiedbootstate') ||
      description.contains('verified boot') ||
      description.contains('unlocked bootloader');
}

bool isLowConfidenceDebuggerHeuristic(Threat threat) {
  if (threat.category != ThreatCategory.debuggerAttached) return false;
  final description = threat.description.toLowerCase();
  return description.contains('native ptrace') ||
      description.contains('fork-based parent debugger');
}

bool isDeveloperModeOnlyHeuristic(Threat threat) {
  if (threat.category != ThreatCategory.debuggerAttached) return false;
  final description = threat.description.toLowerCase();
  return description.contains('developer options') ||
      description.contains('developer mode') ||
      description.contains('adb enabled') ||
      description.contains('multi-source check') ||
      description.contains('usb debugging') ||
      description.contains('development_settings');
}

bool isBlockingThreat(
  Threat threat, {
  required bool allowSideload,
  required bool strictExamIntegrity,
  required bool blockEmulator,
}) {
  if (isBootloaderWarnOnly(threat, strictExamIntegrity: strictExamIntegrity)) {
    return false;
  }
  if (isLowConfidenceDebuggerHeuristic(threat)) return false;
  if (isDeveloperModeOnlyHeuristic(threat)) return false;
  if (!blockEmulator && threat.category == ThreatCategory.analysisEnvironment) {
    return false;
  }
  if (allowSideload && threat.category == ThreatCategory.untrustedSource) {
    return false;
  }
  if (threat.category == ThreatCategory.integrityViolation) return true;
  if (!allowSideload && threat.category == ThreatCategory.untrustedSource) {
    return severityAtLeast(threat.severity, Severity.medium);
  }
  if (!severityAtLeast(threat.severity, Severity.high)) return false;
  return switch (threat.category) {
    ThreatCategory.privilegedAccess ||
    ThreatCategory.runtimeManipulation ||
    ThreatCategory.debuggerAttached ||
    ThreatCategory.analysisEnvironment =>
      true,
    _ => false,
  };
}

List<Threat> blockingThreats(
  List<Threat> threats, {
  required bool allowSideload,
  required bool strictExamIntegrity,
  required bool blockEmulator,
}) =>
    threats
        .where(
          (threat) => isBlockingThreat(
            threat,
            allowSideload: allowSideload,
            strictExamIntegrity: strictExamIntegrity,
            blockEmulator: blockEmulator,
          ),
        )
        .toList();

bool hasThreatInCategory(
  List<Threat> threats,
  ThreatCategory category, {
  required bool allowSideload,
  required bool strictExamIntegrity,
  required bool blockEmulator,
}) =>
    threats.any(
      (threat) =>
          threat.category == category &&
          isBlockingThreat(
            threat,
            allowSideload: allowSideload,
            strictExamIntegrity: strictExamIntegrity,
            blockEmulator: blockEmulator,
          ),
    );

bool hasCompositeMediumPrivilegedThreats(
  List<Threat> threats, {
  required bool strictExamIntegrity,
}) {
  if (!strictExamIntegrity) return false;
  final count = threats
      .where(
        (threat) =>
            threat.category == ThreatCategory.privilegedAccess &&
            threat.severity == Severity.medium,
      )
      .length;
  return count >= 2;
}

bool detectTestKeys(List<Threat> threats) {
  for (final threat in threats) {
    final description = threat.description.toLowerCase();
    if (description.contains('test-keys') ||
        description.contains('test keys') ||
        description.contains('build signed with test-keys') ||
        description.contains('ro.build.tags')) {
      return true;
    }
  }
  return false;
}

bool detectDeveloperMode(List<Threat> threats) {
  if (Deployment.instance.relaxDeveloperModeChecks) return false;
  for (final threat in threats) {
    final description = threat.description.toLowerCase();
    if (description.contains('developer options') ||
        description.contains('developer mode') ||
        description.contains('development_settings') ||
        description.contains('usb debugging') ||
        description.contains('adb enabled') ||
        description.contains('adb_wifi') ||
        description.contains('multi-source check')) {
      return true;
    }
  }
  return false;
}

bool isDeveloperModeOnlyIssue({
  required SecurityStatus status,
  required bool strictExamIntegrity,
}) {
  if (!detectDeveloperMode(status.detectedThreats)) return false;
  if (status.hasBlockingIntegrityIssue(
        strictExamIntegrity: strictExamIntegrity,
      )) {
    return false;
  }
  return true;
}

bool detectRootThreat(List<Threat> threats) {
  return threats.any((threat) {
    if (threat.category != ThreatCategory.privilegedAccess) return false;
    if (threat.description.toLowerCase().contains('custom rom')) return false;
    return severityAtLeast(threat.severity, Severity.high);
  });
}

bool detectJailbreakThreat(List<Threat> threats) {
  return threats.any(
    (threat) =>
        threat.category == ThreatCategory.privilegedAccess &&
        severityAtLeast(threat.severity, Severity.high),
  );
}

String? _rootThreatReason(List<Threat> threats) {
  for (final threat in threats) {
    if (threat.category == ThreatCategory.privilegedAccess &&
        !threat.description.toLowerCase().contains('custom rom')) {
      return threat.description;
    }
  }
  return null;
}

String? _jailbreakThreatReason(List<Threat> threats) {
  for (final threat in threats) {
    if (threat.category == ThreatCategory.privilegedAccess) {
      return threat.description;
    }
  }
  return null;
}

String? _customRomThreatReason(List<Threat> threats) {
  for (final threat in threats) {
    if (threat.description.toLowerCase().contains('custom rom')) {
      return threat.description;
    }
  }
  return null;
}

bool detectEnvironmentSpoofed(List<Threat> threats) {
  for (final threat in threats) {
    final description = threat.description.toLowerCase();
    if (threat.category == ThreatCategory.integrityViolation &&
        description.contains('spoofing')) {
      return true;
    }
  }
  return false;
}

bool detectCustomRom(List<Threat> threats) {
  for (final threat in threats) {
    final description = threat.description.toLowerCase();
    if (description.contains('custom rom')) {
      return true;
    }
  }
  return false;
}
