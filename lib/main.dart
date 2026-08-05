import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bindings/dependency_registry.dart';
import 'app/device_compromised_app.dart';
import 'core/config/deployment.dart';
import 'core/services/security_service.dart';
import 'core/services/system_ui_service.dart';

/// Set to `false` to allow screenshots and screen recording app-wide.
/// Requires an app restart to take effect.
const bool kPreventScreenCapture = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemUiService.applyFullscreenMode();
  await SystemUiService.applyPortraitLock();

  Deployment.init(
    preventScreenCapture: kPreventScreenCapture,
  );

  final securityStatus = await SecurityService.instance.initialize();
  if (securityStatus.hasBlockingIntegrityIssue(
    strictExamIntegrity: Deployment.instance.strictExamIntegrity,
  )) {
    runApp(
      DeviceCompromisedApp(
        reason: securityStatus.primaryBlockReason ??
            securityStatus.failureReason,
      ),
    );
    return;
  }

  await DependencyRegistry.init();
  // Offline demo (no API calls):
  // Deployment.init(demo: true, preventScreenCapture: kPreventScreenCapture);
  // then await DependencyRegistry.init();
  runApp(const MilitaryExamApp());
}
