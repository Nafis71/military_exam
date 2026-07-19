import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/finish_exam/presentation/pages/finish_exam_page.dart';
import '../../features/instructions/presentation/pages/instructions_page.dart';
import '../../features/fill_blank_exam/presentation/pages/fill_blank_exam_page.dart';
import '../../features/mcq_exam/presentation/pages/mcq_exam_page.dart';
import '../../features/security_gate/presentation/pages/airplane_mode_required_page.dart';
import '../../features/security_gate/presentation/pages/camera_permission_required_page.dart';
import '../../features/security_gate/presentation/pages/wifi_mode_required_page.dart';
import '../../features/security_gate/presentation/pages/developer_mode_required_page.dart';
import '../../features/security_gate/presentation/pages/security_error_page.dart';
import '../../features/security_gate/presentation/pages/security_gate_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/violation/presentation/pages/violation_page.dart';
import '../../features/written_exam/presentation/pages/written_exam_page.dart';
import '../bindings/dependency_registry.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.instructions,
      page: () => const InstructionsPage(),
      binding: InstructionsBinding(),
    ),
    GetPage(
      name: AppRoutes.securityGate,
      page: () => const SecurityGatePage(),
      binding: SecurityGateBinding(),
    ),
    GetPage(
      name: AppRoutes.securityError,
      page: () => const SecurityErrorPage(),
    ),
    GetPage(
      name: AppRoutes.airplaneModeRequired,
      page: () => const AirplaneModeRequiredPage(),
      binding: AirplaneModeBinding(),
    ),
    GetPage(
      name: AppRoutes.wifiModeRequired,
      page: () => const WifiModeRequiredPage(),
      binding: WifiModeBinding(),
    ),
    GetPage(
      name: AppRoutes.developerModeRequired,
      page: () => const DeveloperModeRequiredPage(),
      binding: DeveloperModeBinding(),
    ),
    GetPage(
      name: AppRoutes.cameraPermissionRequired,
      page: () => const CameraPermissionRequiredPage(),
      binding: CameraPermissionBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.mcqExam,
      page: () => const McqExamPage(),
      binding: McqExamBinding(),
      middlewares: [ExamRouteGuard()],
    ),
    GetPage(
      name: AppRoutes.fillBlankExam,
      page: () => const FillBlankExamPage(),
      binding: FillBlankExamBinding(),
      middlewares: [ExamRouteGuard()],
    ),
    GetPage(
      name: AppRoutes.writtenExam,
      page: () => const WrittenExamPage(),
      binding: WrittenExamBinding(),
      middlewares: [ExamRouteGuard()],
    ),
    GetPage(
      name: AppRoutes.finishExam,
      page: () => const FinishExamPage(),
      binding: FinishExamBinding(),
      middlewares: [NoBackRouteGuard()],
    ),
    GetPage(
      name: AppRoutes.violation,
      page: () => const ViolationPage(),
      binding: ViolationBinding(),
      middlewares: [NoBackRouteGuard()],
    ),
  ];
}

class ExamRouteGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Route guards rely on exam session state managed by controllers.
    return null;
  }
}

class NoBackRouteGuard extends GetMiddleware {
  @override
  Widget onPageBuilt(Widget page) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: page,
    );
  }
}
