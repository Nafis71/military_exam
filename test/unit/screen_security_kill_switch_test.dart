import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/config/build_mode.dart';
import 'package:military_exam/core/config/deployment.dart';
import 'package:military_exam/core/logging/app_logger.dart';
import 'package:military_exam/core/services/screen_security_service.dart';

void main() {
  group('Deployment preventScreenCapture', () {
    test('defaults to true when not specified', () {
      Deployment.init(mode: BuildMode.development);
      expect(Deployment.instance.preventScreenCapture, isTrue);
    });

    test('can be disabled via init', () {
      Deployment.init(preventScreenCapture: false);
      expect(Deployment.instance.preventScreenCapture, isFalse);
    });

    test('stays false without a second Deployment.init overwrite', () {
      Deployment.init(preventScreenCapture: false);
      expect(Deployment.isInitialized, isTrue);
      expect(Deployment.instance.preventScreenCapture, isFalse);
    });
  });

  group('ScreenSecurityService kill switch', () {
    test('enable is skipped when preventScreenCapture is false', () async {
      Deployment.init(preventScreenCapture: false);
      final service = ScreenSecurityService(AppLogger());

      await service.enable();

      expect(service.isEnabled, isFalse);
    });

    test('enable is skipped when policy would block but deployment allows', () async {
      Deployment.init(preventScreenCapture: false);
      final service = ScreenSecurityService(AppLogger());

      await service.enable();
      await service.enable();

      expect(service.isEnabled, isFalse);
    });
  });
}
