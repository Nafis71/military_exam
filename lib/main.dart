import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/bindings/dependency_registry.dart';
import 'app/device_compromised_app.dart';
import 'core/config/deployment.dart';
import 'core/services/security_service.dart';
import 'core/services/system_ui_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemUiService.applyFullscreenMode();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Deployment.init(demo: true);

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

  await DependencyRegistry.init(demo: false);
  // Offline demo (no API calls): await DependencyRegistry.init(demo: true);
  runApp(const MilitaryExamApp());
}
