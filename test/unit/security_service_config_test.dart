import 'package:advanced_root_detection/advanced_root_detection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/config/build_mode.dart';
import 'package:military_exam/core/config/deployment.dart';

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

  group('SecurityConfig simulator flags', () {
    test('demo maps skip flags to native config', () {
      Deployment.init(demo: true);
      final relax = Deployment.instance.relaxSimulatorIntegrityChecks;

      final config = SecurityConfig(
        ios: IOSConfig(skipJailbreakOnSimulator: relax),
        android: AndroidConfig(
          skipRootOnEmulator: relax,
          skipDeveloperModeOnEmulator: relax,
        ),
      );

      expect(config.ios.skipJailbreakOnSimulator, isTrue);
      expect(config.android.skipRootOnEmulator, isTrue);
      expect(config.android.skipDeveloperModeOnEmulator, isTrue);
      expect(config.toMap()['ios']['skipJailbreakOnSimulator'], isTrue);
      expect(config.toMap()['android']['skipRootOnEmulator'], isTrue);
      expect(config.toMap()['android']['skipDeveloperModeOnEmulator'], isTrue);
    });

    test('production maps skip flags off', () {
      Deployment.init(mode: BuildMode.production);
      final relax = Deployment.instance.relaxSimulatorIntegrityChecks;

      final config = SecurityConfig(
        ios: IOSConfig(skipJailbreakOnSimulator: relax),
        android: AndroidConfig(
          skipRootOnEmulator: relax,
          skipDeveloperModeOnEmulator: relax,
        ),
      );

      expect(config.ios.skipJailbreakOnSimulator, isFalse);
      expect(config.android.skipRootOnEmulator, isFalse);
      expect(config.android.skipDeveloperModeOnEmulator, isFalse);
    });
  });
}
