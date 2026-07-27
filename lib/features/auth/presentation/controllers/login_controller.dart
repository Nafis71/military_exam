import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:military_exam/core/utils/validators.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/services/screen_security_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/widgets/app_error_toast.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import '../../../exam_session/domain/usecases/has_cached_exam_answers_usecase.dart';
import '../../../exam_session/domain/usecases/recover_cached_exam_submission_usecase.dart';
import '../../../exam_session/domain/usecases/save_roll_number_usecase.dart';
import '../../../security_gate/domain/usecases/complete_security_pre_exam_usecase.dart';
import '../../../onboarding/domain/usecases/get_onboarding_state_usecase.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/usecases/get_districts_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/validate_exam_eligibility_usecase.dart';

class LoginController extends GetxController {
  LoginController(
    this._loginUseCase,
    this._getDistrictsUseCase,
    this._validateEligibilityUseCase,
    this._hasCachedExamAnswersUseCase,
    this._recoverCachedExamSubmissionUseCase,
    this._clearExamLocalDataUseCase,
    this._saveRollNumberUseCase,
    this._getOnboardingState,
    this._completePreExam,
    this._screenSecurity,
    this._watchdog,
    this._examRunContext,
    this._logger,
  );

  final LoginUseCase _loginUseCase;
  final GetDistrictsUseCase _getDistrictsUseCase;
  final ValidateExamEligibilityUseCase _validateEligibilityUseCase;
  final HasCachedExamAnswersUseCase _hasCachedExamAnswersUseCase;
  final RecoverCachedExamSubmissionUseCase _recoverCachedExamSubmissionUseCase;
  final ClearExamLocalDataUseCase _clearExamLocalDataUseCase;
  final SaveRollNumberUseCase _saveRollNumberUseCase;
  final GetOnboardingStateUseCase _getOnboardingState;
  final CompleteSecurityPreExamUseCase _completePreExam;
  final ScreenSecurityService _screenSecurity;
  final SecurityWatchdogService _watchdog;
  final ExamRunContext _examRunContext;
  final AppLogger _logger;

  final examineeIdController = TextEditingController();
  final batchPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isLoadingDistricts = false.obs;
  final errorMessage = RxnString();
  final session = Rxn<AuthSession>();
  final eligibility = Rxn<ExamEligibility>();
  final districts = <String>[].obs;
  final selectedDistrict = RxnString();

  @override
  void onInit() {
    super.onInit();
    if (!_examRunContext.isOnboardingDemo) {
      unawaited(_enableScreenSecurity());
    }
    unawaited(fetchDistricts());
    unawaited(_prefillExamineeId());
  }

  @override
  void onClose() {
    if (!_examRunContext.isOnboardingDemo && !_watchdog.isRunning) {
      unawaited(_disableScreenSecurity());
    }
    examineeIdController.dispose();
    batchPasswordController.dispose();
    super.onClose();
  }

  Future<void> _enableScreenSecurity() async {
    try {
      await _screenSecurity.enable();
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error(
          'login screen security enable failed',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  Future<void> _disableScreenSecurity() async {
    try {
      await _screenSecurity.disable();
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error(
          'login screen security disable failed',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  Future<void> _prefillExamineeId() async {
    try {
      final stateResult = await _getOnboardingState();
      switch (stateResult) {
        case Success(:final data):
          final id = data.candidate?.candidateId;
          if (id != null && id.isNotEmpty) {
            examineeIdController.text = id;
          }
        case ErrorResult():
          break;
      }
    } catch (error, stackTrace) {
      _logger.error('_prefillExamineeId failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> fetchDistricts() async {
    isLoadingDistricts.value = true;
    try {
      final result = await _getDistrictsUseCase();
      switch (result) {
        case Success(:final data):
          districts.assignAll(data);
        case ErrorResult(:final failure):
          _logger.error('fetchDistricts failed', error: failure.message);
          errorMessage.value = AppStrings.networkRequestFailed;
      }
    } catch (error, stackTrace) {
      _logger.error('fetchDistricts failed', error: error, stackTrace: stackTrace);
      errorMessage.value = AppStrings.networkRequestFailed;
    } finally {
      isLoadingDistricts.value = false;
    }
  }

  void selectDistrict(String? district) {
    selectedDistrict.value = district;
  }

  Future<void> login() async {
    errorMessage.value = null;
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    final credentials = LoginCredentials(
      district: selectedDistrict.value!,
      rollNumber: examineeIdController.text.trim(),
    );

    final result = await _loginUseCase(credentials);
    if (result is ErrorResult<AuthSession>) {
      isLoading.value = false;
      final failure = result.failure;
      if (failure is BadRequestFailure) {
        AppErrorToast.show(failure.message);
        return;
      }
      if (failure is AuthFailure) {
        errorMessage.value = failure.message;
      } else {
        errorMessage.value = null;
        _logger.error('login failed', error: failure.message);
        AppErrorToast.show(AppStrings.somethingWentWrong);
      }
      return;
    }

    final authSession = (result as Success<AuthSession>).data;
    session.value = authSession;

    final rollResult = await _saveRollNumberUseCase(credentials.rollNumber);
    if (rollResult is ErrorResult<void>) {
      isLoading.value = false;
      _logger.error('saveRollNumber failed', error: rollResult.failure.message);
      errorMessage.value = AppStrings.somethingWentWrong;
      return;
    }

    final eligibilityResult =
        await _validateEligibilityUseCase(authSession.sessionId);

    switch (eligibilityResult) {
      case Success(:final data):
        eligibility.value = data;
        if (!data.isEligible || data.isLocked || !data.isExamActive) {
          isLoading.value = false;
          errorMessage.value =
              data.message ?? AppStrings.notEligible;
          return;
        }
        final recovered = await _tryRecoverCachedSubmission();
        isLoading.value = false;
        if (recovered) return;
        await _completePreExam();
      case ErrorResult(:final failure):
        isLoading.value = false;
        errorMessage.value = failure.message;
    }
  }

  Future<bool> _tryRecoverCachedSubmission() async {
    try {
      final hasCacheResult = await _hasCachedExamAnswersUseCase();
      if (hasCacheResult is ErrorResult<bool>) {
        _logger.error(
          'hasCachedExamAnswers failed',
          error: hasCacheResult.failure.message,
        );
        return false;
      }
      if (hasCacheResult.dataOrNull != true) return false;

      isLoading.value = true;
      final recoveryResult = await _recoverCachedExamSubmissionUseCase();
      isLoading.value = false;

      switch (recoveryResult) {
        case Success(:final data):
          Get.offAllNamed(
            AppRoutes.finishExam,
            arguments: <String, dynamic>{
              'examName': data.exam.examName,
              'submittedAt': data.receipt.submittedAt,
              'submissionType': 'manual',
            },
          );
          return true;
        case ErrorResult(:final failure):
          if (failure is NetworkFailure) {
            errorMessage.value = AppStrings.cachedSubmissionUploadFailed;
            return true;
          }
          _logger.error(
            'recoverCachedExamSubmission failed',
            error: failure.message,
          );
          await _clearExamLocalDataUseCase();
          return false;
      }
    } catch (error, stackTrace) {
      isLoading.value = false;
      _logger.error(
        '_tryRecoverCachedSubmission failed',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage.value = AppStrings.somethingWentWrong;
      return true;
    }
  }

  String? validateDistrict(String? value) => Validators.requiredField(value);
}
