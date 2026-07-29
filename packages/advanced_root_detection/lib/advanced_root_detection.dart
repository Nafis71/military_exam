/// Advance Root Detection — Flutter RASP plugin.
///
/// Provides comprehensive Runtime Application Self-Protection for Android and iOS,
/// including detection of rooted/jailbroken devices, hooking frameworks (Frida,
/// Xposed), emulators, debuggers, and app tampering.
///
/// ## Quick start
/// ```dart
/// final shield = AdvanceRootDetection();
/// final report = await shield.performCheck(SecurityConfig());
/// if (report.isPrivilegedAccess) { /* handle root/jailbreak */ }
/// ```
library advanced_root_detection; // ignore: unnecessary_library_name

export 'src/advance_root_detection_base.dart';
export 'src/threat_report.dart';
export 'src/threat_category.dart';
export 'src/security_config.dart';
export 'src/severity.dart';
export 'src/platform_interface.dart';
export 'src/method_channel_impl.dart';
export 'src/root_detection_guard.dart';
