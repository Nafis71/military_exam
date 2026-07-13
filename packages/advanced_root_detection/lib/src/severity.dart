/// Severity level of a detected threat.
enum Severity {
  /// Informational signal — no immediate action required.
  info,

  /// Low-risk signal — worth logging but not blocking.
  low,

  /// Medium-risk signal — consider restricting functionality.
  medium,

  /// High-risk signal — strongly recommend blocking the operation.
  high,

  /// Critical risk — device/environment is demonstrably compromised.
  critical,
}
