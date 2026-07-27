import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';

class InstructionsController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  static const int totalPages = 3;

  String get continueButtonLabel =>
      currentPage.value < totalPages - 1
          ? AppStrings.next
          : AppStrings.continueToSecurityCheck;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) => currentPage.value = index;

  void nextPage() {
    if (currentPage.value < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }

    Get.offNamed(AppRoutes.securityGate);
  }
}
