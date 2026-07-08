import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/config/build_mode.dart';
import 'package:military_exam/core/config/deployment.dart';
import 'package:military_exam/core/config/environment.dart';

void main() {
  test('Deployment resolves development environment in debug mode', () {
    Deployment.init(mode: BuildMode.development);
    expect(Deployment.instance.environment.enableMockExamData, isTrue);
    expect(Deployment.instance.environment.enableNetworkLogs, isTrue);
    expect(Deployment.instance.isDemo, isFalse);
  });

  test('Demo mode disables API usage and uses on-device data only', () {
    Deployment.init(demo: true);
    expect(Deployment.instance.isDemo, isTrue);
    expect(Deployment.instance.mode, BuildMode.demo);
    expect(Deployment.instance.environment.baseUrl, isEmpty);
    expect(Deployment.instance.environment.enableNetworkLogs, isFalse);
  });

  test('Production environment disables verbose logging flags', () {
    Deployment.init(mode: BuildMode.production);
    expect(Deployment.instance.environment.enableNetworkLogs, isFalse);
    expect(Environment.forMode(BuildMode.production).enableMockExamData, isFalse);
    expect(Deployment.instance.isDemo, isFalse);
  });
}
