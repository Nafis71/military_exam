/// Categories of security threats detected by [AdvanceRootDetection].
enum ThreatCategory {
  /// Device has root (Android) or jailbreak (iOS) indicators.
  privilegedAccess,

  /// Hooking framework detected (Frida, Xposed, Substrate, etc.).
  runtimeManipulation,

  /// Debugger is attached or anti-debug checks triggered.
  debuggerAttached,

  /// Running inside an emulator or simulator.
  analysisEnvironment,

  /// APK/IPA signing, installer source, or bundle integrity violated.
  integrityViolation,

  /// Screen capture, recording, or sharing detected (Android).
  screenCapture,

  /// Package installed from untrusted / unknown source.
  untrustedSource,
}
