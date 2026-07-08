import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/bindings/dependency_registry.dart';
import 'core/services/system_ui_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemUiService.applyFullscreenMode();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await DependencyRegistry.init(demo: true);
  // Offline demo (no API calls): await DependencyRegistry.init(demo: true);
  runApp(const MilitaryExamApp());
}
