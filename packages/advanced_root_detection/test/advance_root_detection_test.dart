import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_root_detection/advanced_root_detection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdvanceRootDetection', () {
    const channel = MethodChannel('advanced_root_detection/methods');
    final List<MethodCall> log = [];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        log.add(call);
        switch (call.method) {
          case 'performCheck':
            return {
              'detectedThreats': [],
              'checkedAt': DateTime.now().toIso8601String(),
            };
          case 'startMonitoring':
            return null;
          case 'stopMonitoring':
            return null;
          case 'verifyBeforeSensitiveOp':
            return true;
          default:
            throw PlatformException(code: 'UNKNOWN', message: 'Unknown method');
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('performCheck returns clean ThreatReport when no threats', () async {
      final shield = AdvanceRootDetection();
      final report = await shield.performCheck();
      expect(report.isClean, isTrue);
      expect(report.detectedThreats, isEmpty);
      expect(log.last.method, equals('performCheck'));
    });

    test('performCheck passes config correctly', () async {
      final shield = AdvanceRootDetection();
      final config = SecurityConfig(
        android: AndroidConfig(packageName: 'com.example.app'),
        ios: IOSConfig(bundleIds: ['com.example.app'], teamId: 'ABC123'),
      );
      await shield.performCheck(config);
      final args = log.last.arguments as Map;
      expect((args['android'] as Map)['packageName'], equals('com.example.app'));
    });

    test('verifyBeforeSensitiveOp returns true when safe', () async {
      final shield = AdvanceRootDetection();
      final safe = await shield.verifyBeforeSensitiveOp();
      expect(safe, isTrue);
    });

    test('startMonitoring invokes native method', () async {
      final shield = AdvanceRootDetection();
      await shield.startMonitoring();
      expect(log.last.method, equals('startMonitoring'));
    });

    test('stopMonitoring invokes native method', () async {
      final shield = AdvanceRootDetection();
      await shield.stopMonitoring();
      expect(log.last.method, equals('stopMonitoring'));
    });
  });

  group('ThreatReport', () {
    test('isPrivilegedAccess true when privilegedAccess threat present', () {
      final report = ThreatReport(
        detectedThreats: [
          const Threat(
            category: ThreatCategory.privilegedAccess,
            description: 'su binary found',
            severity: Severity.critical,
          ),
        ],
        checkedAt: DateTime.now(),
      );
      expect(report.isPrivilegedAccess, isTrue);
      expect(report.isClean, isFalse);
      expect(report.hasCriticalThreat, isTrue);
    });

    test('isClean true when no threats', () {
      final report = ThreatReport(detectedThreats: [], checkedAt: DateTime.now());
      expect(report.isClean, isTrue);
      expect(report.isPrivilegedAccess, isFalse);
      expect(report.hasCriticalThreat, isFalse);
    });

    test('fromMap/toMap round-trip', () {
      final original = ThreatReport(
        detectedThreats: [
          const Threat(
            category: ThreatCategory.runtimeManipulation,
            description: 'Frida detected',
            severity: Severity.critical,
          ),
        ],
        checkedAt: DateTime.parse('2026-04-23T12:00:00.000Z'),
      );
      final map = original.toMap();
      final restored = ThreatReport.fromMap(map);
      expect(restored.detectedThreats.length, equals(1));
      expect(restored.detectedThreats.first.category,
          equals(ThreatCategory.runtimeManipulation));
    });
  });

  group('Threat', () {
    test('equality based on category/description/severity', () {
      const t1 = Threat(
        category: ThreatCategory.debuggerAttached,
        description: 'Debugger connected',
        severity: Severity.high,
      );
      const t2 = Threat(
        category: ThreatCategory.debuggerAttached,
        description: 'Debugger connected',
        severity: Severity.high,
      );
      expect(t1, equals(t2));
    });

    test('fromMap deserialises correctly', () {
      final map = {
        'category': 'analysisEnvironment',
        'description': 'Emulator detected',
        'severity': 'medium',
      };
      final threat = Threat.fromMap(map);
      expect(threat.category, equals(ThreatCategory.analysisEnvironment));
      expect(threat.severity, equals(Severity.medium));
    });
  });

  group('SecurityConfig', () {
    test('toMap includes all fields', () {
      const config = SecurityConfig(
        android: AndroidConfig(
          packageName: 'com.test',
          signingCertHashes: ['AABBCC'],
          checkVpn: true,
        ),
        ios: IOSConfig(bundleIds: ['com.test'], teamId: 'XYZ'),
        monitoringInterval: Duration(seconds: 60),
      );
      final map = config.toMap();
      expect((map['android'] as Map)['packageName'], 'com.test');
      expect((map['android'] as Map)['checkVpn'], isTrue);
      expect((map['ios'] as Map)['teamId'], 'XYZ');
      expect(map['monitoringIntervalSeconds'], 60);
    });
  });
}
