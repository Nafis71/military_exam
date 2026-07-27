import 'dart:async';

import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../onboarding/domain/usecases/get_onboarding_state_usecase.dart';
import '../../../../core/utils/result.dart';

class SplashController extends GetxController {
  SplashController(this._getOnboardingState);

  final GetOnboardingStateUseCase _getOnboardingState;

  @override
  void onInit() {
    super.onInit();
    unawaited(_navigateNext());
  }

  Future<void> _navigateNext() async {
    await Future<void>.delayed(AppConstants.splashMinDuration);

    final stateResult = await _getOnboardingState();
    switch (stateResult) {
      case Success(:final data) when data.isLoggedIn:
        Get.offNamed(AppRoutes.candidateDashboard);
        return;
      case Success():
      case ErrorResult():
        break;
    }

    Get.offNamed(AppRoutes.getStarted);
  }
}
