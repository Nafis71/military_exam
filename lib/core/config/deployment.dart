import 'build_mode.dart';
import 'environment.dart';

class Deployment {
  Deployment._internal(
    this.mode, {
    required this.preventScreenCapture,
  }) : environment = Environment.forMode(mode);

  final BuildMode mode;
  final Environment environment;

  /// When true, screenshots and screen recording are blocked via [ScreenSecurityService].
  final bool preventScreenCapture;

  static Deployment? _instance;

  static Deployment get instance {
    assert(
      _instance != null,
      'Deployment not initialized. Call Deployment.init() first.',
    );
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  /// Initializes deployment configuration.
  ///
  /// Pass [demo: true] to run fully offline with on-device data only (no API calls).
  /// Alternatively pass [mode: BuildMode.demo] for the same behavior.
  static void init({
    BuildMode? mode,
    bool demo = false,
    bool preventScreenCapture = true,
  }) {
    final resolvedMode = demo
        ? BuildMode.demo
        : (mode ?? BuildModeResolver.resolve());
    _instance = Deployment._internal(
      resolvedMode,
      preventScreenCapture: preventScreenCapture,
    );
  }

  /// When true, the app makes no network API calls and loads data from device storage.
  bool get isDemo => environment.isDemo;

  bool get isProduction => mode == BuildMode.production;
  bool get isDevelopment => mode == BuildMode.development;

  /// When true, skip jailbreak/root/developer-mode checks on iOS simulator / Android emulator.
  bool get relaxSimulatorIntegrityChecks => !isProduction;

  /// When true, skip developer-mode checks on all devices (not only emulators).
  bool get relaxDeveloperModeChecks => !isProduction;

  /// When true, sideloaded / unknown install sources are allowed for RASP.
  bool get allowSideload => environment.allowSideload;

  /// When true, strict exam integrity checks (bootloader, custom ROM, spoofing).
  bool get strictExamIntegrity => environment.strictExamIntegrity;
}
