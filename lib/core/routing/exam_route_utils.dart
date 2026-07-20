import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

/// Route helpers for active exam flows.
abstract final class ExamRouteUtils {
  static bool get isOnActiveExamRoute {
    final route = Get.currentRoute;
    return route == AppRoutes.mcqExam ||
        route == AppRoutes.fillBlankExam ||
        route == AppRoutes.writtenExam ||
        route == AppRoutes.examSubmitReview ||
        route == AppRoutes.examWaiting;
  }
}
