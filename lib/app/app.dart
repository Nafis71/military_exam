import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'bindings/dependency_registry.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import '../core/config/deployment.dart';
import '../core/theme/app_theme.dart';

class MilitaryExamApp extends StatelessWidget {
  const MilitaryExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: Deployment.instance.environment.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: AppRoutes.splash,
          getPages: AppPages.routes,
          initialBinding: AppBinding(),
          defaultTransition: Transition.fadeIn,
          builder: (context, widget) {
            return widget ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
