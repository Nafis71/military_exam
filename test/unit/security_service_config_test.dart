import 'package:advanced_root_detection/advanced_root_detection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/config/build_mode.dart';
import 'package:military_exam/core/config/deployment.dart';
import 'package:military_exam/core/services/security_service.dart';

void main() {
  group('relaxSimulatorIntegrityChecks', () {
    test('demo mode relaxes simulator integrity checks', () {
      Deployment.init(demo: true);
      expect(Deployment.instance.relaxSimulatorIntegrityChecks, isTrue);
    });

    test('staging mode relaxes simulator integrity checks', () {
      Deployment.init(mode: BuildMode.staging);
      expect(Deployment.instance.relaxSimulatorIntegrityChecks, isTrue);
    });

    test('development mode relaxes simulator integrity checks', () {
      Deployment.init(mode: BuildMode.development);
      expect(Deployment.instance.relaxSimulatorIntegrityChecks, isTrue);
    });

    test('production mode keeps simulator integrity checks', () {
      Deployment.init(mode: BuildMode.production);
      expect(Deployment.instance.relaxSimulatorIntegrityChecks, isFalse);
    });
  });

  group('relaxDeveloperModeChecks', () {
    test('demo mode relaxes developer mode checks', () {
      Deployment.init(demo: true);
      expect(Deployment.instance.relaxDeveloperModeChecks, isTrue);
    });

    test('staging mode relaxes developer mode checks', () {
      Deployment.init(mode: BuildMode.staging);
      expect(Deployment.instance.relaxDeveloperModeChecks, isTrue);
    });

    test('development mode relaxes developer mode checks', () {
      Deployment.init(mode: BuildMode.development);
      expect(Deployment.instance.relaxDeveloperModeChecks, isTrue);
    });

    test('production mode keeps developer mode checks', () {
      Deployment.init(mode: BuildMode.production);
      expect(Deployment.instance.relaxDeveloperModeChecks, isFalse);
    });
  });

  group('SecurityConfig simulator flags', () {
    test('demo maps skip flags to native config', () {
      Deployment.init(demo: true);
      final relaxSimulator = Deployment.instance.relaxSimulatorIntegrityChecks;
      final relaxDeveloperMode = Deployment.instance.relaxDeveloperModeChecks;

      final config = SecurityConfig(
        ios: IOSConfig(skipJailbreakOnSimulator: relaxSimulator),
        android: AndroidConfig(
          skipRootOnEmulator: relaxSimulator,
          skipDeveloperModeOnEmulator: relaxSimulator,
          skipDeveloperMode: relaxDeveloperMode,
        ),
      );

      expect(config.ios.skipJailbreakOnSimulator, isTrue);
      expect(config.android.skipRootOnEmulator, isTrue);
      expect(config.android.skipDeveloperModeOnEmulator, isTrue);
      expect(config.android.skipDeveloperMode, isTrue);
      expect(config.toMap()['ios']['skipJailbreakOnSimulator'], isTrue);
      expect(config.toMap()['android']['skipRootOnEmulator'], isTrue);
      expect(config.toMap()['android']['skipDeveloperModeOnEmulator'], isTrue);
      expect(config.toMap()['android']['skipDeveloperMode'], isTrue);
    });

    test('production maps skip flags off', () {
      Deployment.init(mode: BuildMode.production);
      final relaxSimulator = Deployment.instance.relaxSimulatorIntegrityChecks;
      final relaxDeveloperMode = Deployment.instance.relaxDeveloperModeChecks;

      final config = SecurityConfig(
        ios: IOSConfig(skipJailbreakOnSimulator: relaxSimulator),
        android: AndroidConfig(
          skipRootOnEmulator: relaxSimulator,
          skipDeveloperModeOnEmulator: relaxSimulator,
          skipDeveloperMode: relaxDeveloperMode,
        ),
      );

      expect(config.ios.skipJailbreakOnSimulator, isFalse);
      expect(config.android.skipRootOnEmulator, isFalse);
      expect(config.android.skipDeveloperModeOnEmulator, isFalse);
      expect(config.android.skipDeveloperMode, isFalse);
    });
  });

  group('detectDeveloperMode', () {
    const developerThreat = Threat(
      category: ThreatCategory.debuggerAttached,
      description: 'Developer options or ADB enabled (multi-source check)',
      severity: Severity.high,
    );

    test('returns false when developer mode checks are relaxed', () {
      Deployment.init(mode: BuildMode.staging);
      expect(detectDeveloperMode(const [developerThreat]), isFalse);
    });

    test('returns true when developer mode checks are enforced', () {
      Deployment.init(mode: BuildMode.production);
      expect(detectDeveloperMode(const [developerThreat]), isTrue);
    });
  });
}
