import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';

class GetStartedController extends GetxController {
  void onGetStarted() {
    Get.toNamed(AppRoutes.candidateLogin);
  }
}
