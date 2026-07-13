import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import '../features/security_gate/presentation/pages/device_compromised_page.dart';

class DeviceCompromisedApp extends StatelessWidget {
  const DeviceCompromisedApp({super.key, this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: DeviceCompromisedPage(reason: reason),
        );
      },
    );
  }
}
