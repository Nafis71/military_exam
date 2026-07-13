import 'threat_category.dart';
import 'severity.dart';

/// A single detected threat.
class Threat {
  /// The category this threat belongs to.
  final ThreatCategory category;

  /// Human-readable description of what was detected.
  final String description;

  /// Severity of this specific finding.
  final Severity severity;

  /// Optional additional details (e.g. which file was found).
  final Map<String, dynamic>? details;

  /// Creates a [Threat] instance.
  const Threat({
    required this.category,
    required this.description,
    required this.severity,
    this.details,
  });

  /// Deserialises a [Threat] from a map returned over the MethodChannel.
  factory Threat.fromMap(Map<dynamic, dynamic> map) {
    return Threat(
      category: ThreatCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ThreatCategory.integrityViolation,
      ),
      description: map['description'] as String? ?? '',
      severity: Severity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => Severity.medium,
      ),
      details: map['details'] != null
          ? Map<String, dynamic>.from(map['details'] as Map)
          : null,
    );
  }

  /// Serialises this [Threat] to a map.
  Map<String, dynamic> toMap() => {
        'category': category.name,
        'description': description,
        'severity': severity.name,
        if (details != null) 'details': details,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Threat &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          description == other.description &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(category, description, severity);

  @override
  String toString() =>
      'Threat(category: ${category.name}, severity: ${severity.name}, '
      'description: $description)';
}

/// Aggregated result of a full security check.
///
/// Example:
/// ```dart
/// final report = await shield.performCheck(config);
/// if (report.isPrivilegedAccess) {
///   // Block sensitive operation
/// }
/// ```
class ThreatReport {
  /// All individual threats detected during this check.
  final List<Threat> detectedThreats;

  /// Timestamp when the check was performed.
  final DateTime checkedAt;

  /// Creates a [ThreatReport].
  const ThreatReport({
    required this.detectedThreats,
    required this.checkedAt,
  });

  /// Returns `true` if any root (Android) or jailbreak (iOS) indicators were found.
  bool get isPrivilegedAccess =>
      detectedThreats.any((t) => t.category == ThreatCategory.privilegedAccess);

  /// Returns `true` if a hooking framework (Frida, Xposed, Substrate…) was detected.
  bool get isRuntimeManipulated =>
      detectedThreats.any((t) => t.category == ThreatCategory.runtimeManipulation);

  /// Returns `true` if a debugger is attached or anti-debug checks triggered.
  bool get isDebuggerAttached =>
      detectedThreats.any((t) => t.category == ThreatCategory.debuggerAttached);

  /// Returns `true` if running inside an emulator or simulator.
  bool get isAnalysisEnvironment =>
      detectedThreats.any((t) => t.category == ThreatCategory.analysisEnvironment);

  /// Returns `true` if app signing, installer, or bundle integrity is violated.
  bool get isIntegrityViolated =>
      detectedThreats.any((t) => t.category == ThreatCategory.integrityViolation);

  /// Returns `true` if any threat of [Severity.high] or [Severity.critical] exists.
  bool get hasCriticalThreat => detectedThreats.any(
        (t) => t.severity == Severity.critical || t.severity == Severity.high,
      );

  /// Returns `true` if the device/environment passes all checks (no threats found).
  bool get isClean => detectedThreats.isEmpty;

  /// Deserialises from a map returned over the MethodChannel.
  factory ThreatReport.fromMap(Map<dynamic, dynamic> map) {
    final rawThreats = map['detectedThreats'] as List<dynamic>? ?? [];
    return ThreatReport(
      detectedThreats: rawThreats
          .map((t) => Threat.fromMap(t as Map<dynamic, dynamic>))
          .toList(),
      checkedAt: DateTime.tryParse(map['checkedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Serialises to a map.
  Map<String, dynamic> toMap() => {
        'detectedThreats': detectedThreats.map((t) => t.toMap()).toList(),
        'checkedAt': checkedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreatReport &&
          runtimeType == other.runtimeType &&
          detectedThreats == other.detectedThreats;

  @override
  int get hashCode => detectedThreats.hashCode;

  @override
  String toString() =>
      'ThreatReport(threats: ${detectedThreats.length}, clean: $isClean, '
      'checkedAt: ${checkedAt.toIso8601String()})';
}
