import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_error_toast.dart';
import '../../domain/usecases/candidate_login_usecase.dart';

class CandidateLoginController extends GetxController {
  CandidateLoginController(
    this._loginUseCase,
    this._logger,
  );

  final CandidateLoginUseCase _loginUseCase;
  final AppLogger _logger;

  final candidateIdController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  @override
  void onClose() {
    candidateIdController.dispose();
    super.onClose();
  }

  Future<void> continueLogin() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      final result = await _loginUseCase(candidateIdController.text);
      switch (result) {
        case Success():
          Get.offAllNamed(AppRoutes.candidateDashboard);
        case ErrorResult(:final failure):
          AppErrorToast.show(AppStrings.somethingWentWrong);
          if (kDebugMode) {
            _logger.error('candidateLogin failed', error: failure.message);
          }
      }
    } catch (e, st) {
      AppErrorToast.show(AppStrings.somethingWentWrong);
      if (kDebugMode) {
        _logger.error('candidateLogin failed', error: e, stackTrace: st);
      }
    } finally {
      isLoading.value = false;
    }
  }

  String? validateCandidateId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }
}
