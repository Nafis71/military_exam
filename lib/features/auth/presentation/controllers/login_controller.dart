import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/deployment.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/routing/exam_route_utils.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/services/exam_vpn_lockdown_service.dart';
import '../../../../core/services/screen_security_service.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/widgets/app_error_toast.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import '../../../exam_session/domain/usecases/enter_exam_after_credentials_usecase.dart';
import '../../../exam_session/domain/usecases/get_roll_number_usecase.dart';
import '../../../exam_session/domain/usecases/save_roll_number_usecase.dart';
import '../../../exam_session/domain/usecases/has_cached_exam_answers_usecase.dart';
import '../../../exam_session/domain/usecases/recover_cached_exam_submission_usecase.dart';
import '../../../onboarding/domain/usecases/get_onboarding_state_usecase.dart';
import '../../../security_gate/domain/usecases/check_airplane_mode_usecase.dart';
import '../../../security_gate/domain/usecases/check_connectivity_usecase.dart';
import '../../../security_gate/domain/usecases/check_device_integrity_usecase.dart';
import '../../../security_gate/domain/usecases/stop_exam_vpn_lockdown_usecase.dart';
import '../../../security_gate/domain/usecases/stop_security_watchdog_usecase.dart';
import '../../../security_gate/presentation/routes/security_routes.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/validate_exam_eligibility_usecase.dart';

class LoginController extends GetxController {
  LoginController(
    this._loginUseCase,
    this._validateEligibilityUseCase,
    this._hasCachedExamAnswersUseCase,
    this._recoverCachedExamSubmissionUseCase,
    this._clearExamLocalDataUseCase,
    this._getOnboardingState,
    this._getRollNumber,
    this._saveRollNumber,
    this._enterExamAfterCredentials,
    this._checkAirplaneMode,
    this._checkConnectivity,
    this._checkDeviceIntegrity,
    this._vpnLockdownService,
    this._stopWatchdog,
    this._stopVpnLockdown,
    this._lifecycleService,
    this._screenSecurity,
    this._watchdog,
    this._examRunContext,
    this._logger,
  );

  final LoginUseCase _loginUseCase;
  final ValidateExamEligibilityUseCase _validateEligibilityUseCase;
  final HasCachedExamAnswersUseCase _hasCachedExamAnswersUseCase;
  final RecoverCachedExamSubmissionUseCase _recoverCachedExamSubmissionUseCase;
  final ClearExamLocalDataUseCase _clearExamLocalDataUseCase;
  final GetOnboardingStateUseCase _getOnboardingState;
  final GetRollNumberUseCase _getRollNumber;
  final SaveRollNumberUseCase _saveRollNumber;
  final EnterExamAfterCredentialsUseCase _enterExamAfterCredentials;
  final CheckAirplaneModeUseCase _checkAirplaneMode;
  final CheckConnectivityUseCase _checkConnectivity;
  final CheckDeviceIntegrityUseCase _checkDeviceIntegrity;
  final ExamVpnLockdownService _vpnLockdownService;
  final StopSecurityWatchdogUseCase _stopWatchdog;
  final StopExamVpnLockdownUseCase _stopVpnLockdown;
  final AppLifecycleService _lifecycleService;
  final ScreenSecurityService _screenSecurity;
  final SecurityWatchdogService _watchdog;
  final ExamRunContext _examRunContext;
  final AppLogger _logger;

  final batchPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final session = Rxn<AuthSession>();
  final eligibility = Rxn<ExamEligibility>();

  String _storedCandidateId = '';

  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;
  Timer? _pollTimer;
  bool _redirecting = false;
  bool _isEnteringExam = false;
  AppLifecycleState? _lastLifecycleState;

  @override
  void onInit() {
    super.onInit();
    if (!_examRunContext.isOnboardingDemo) {
      unawaited(_enableScreenSecurity());
      _lastLifecycleState = _lifecycleService.currentState;
      _listenForResume();
      _startSecurityPolling();
      unawaited(_recheckAfterReturningToForeground());
    }
    unawaited(_loadStoredCandidateId());
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    unawaited(_lifecycleSubscription?.cancel());
    unawaited(_releasePreExamSecurityIfNeeded());
    batchPasswordController.dispose();
    super.onClose();
  }

  Future<void> goBack() async {
    if (_examRunContext.isOnboardingDemo) {
      Get.offAllNamed(AppRoutes.candidateDashboard);
      return;
    }

    await _releasePreExamSecurityIfNeeded();
    Get.offAllNamed(AppRoutes.candidateDashboard);
  }

  Future<void> _releasePreExamSecurityIfNeeded() async {
    if (_examRunContext.isOnboardingDemo) return;
    if (_isEnteringExam || _watchdog.isRunning) return;

    _stopSecurityPolling();
    try {
      await _stopWatchdog();
      await _stopVpnLockdown();
      await _disableScreenSecurity();
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error(
          'pre-exam security release failed',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  void _listenForResume() {
    _lifecycleSubscription = _lifecycleService.lifecycleStream.listen((state) {
      final wasBackgrounded = _lastLifecycleState ==
              AppLifecycleState.paused ||
          _lastLifecycleState == AppLifecycleState.hidden ||
          _lastLifecycleState == AppLifecycleState.inactive;
      _lastLifecycleState = state;

      if (state == AppLifecycleState.resumed && wasBackgrounded) {
        _redirecting = false;
        unawaited(_recheckAfterReturningToForeground());
      }

      if (state == AppLifecycleState.detached) {
        unawaited(_releasePreExamSecurityIfNeeded());
      }
    });
  }

  Future<void> _recheckAfterReturningToForeground() async {
    await Future<void>.delayed(AppConstants.settingsReturnRecheckDelay);
    _redirecting = false;
    await _verifySecurityRequirements();
  }

  void _startSecurityPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      AppConstants.airplaneModePollInterval,
      (_) => unawaited(_verifySecurityRequirements()),
    );
  }

  void _stopSecurityPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _verifySecurityRequirements() async {
    if (_examRunContext.isOnboardingDemo) return;
    if (_redirecting || isClosed || ExamRouteUtils.isOnActiveExamRoute) return;

    final integrityResult = await _checkDeviceIntegrity();
    final deviceIntegrity = integrityResult.dataOrNull;
    if (deviceIntegrity != null &&
        _isDeveloperModeOnlyIssue(deviceIntegrity)) {
      _redirectToDeveloperMode();
      return;
    }

    final airplaneResult = await _checkAirplaneMode();
    final airplane = airplaneResult.dataOrNull;
    if (airplane != null && !airplane.isEnabled) {
      _redirectToAirplaneMode();
      return;
    }

    final connectivityResult = await _checkConnectivity();
    final connectivity = connectivityResult.dataOrNull;
    if (connectivity != null && !connectivity.isOnline) {
      await _redirectToWifiModeIfAirplaneEnabled();
      return;
    }

    if (!Deployment.instance.isDemo) {
      final vpnActive = await _vpnLockdownService.isActiveNative();
      if (!vpnActive) {
        _redirectToVpnLockdown();
      }
    }
  }

  void _redirectToVpnLockdown() {
    if (_redirecting || isClosed || ExamRouteUtils.isOnActiveExamRoute) return;
    _redirecting = true;
    Get.offNamed(SecurityRoutes.vpnLockdownRequired);
  }

  void _redirectToAirplaneMode() {
    if (_redirecting || isClosed || ExamRouteUtils.isOnActiveExamRoute) return;
    _redirecting = true;
    Get.offNamed(SecurityRoutes.airplaneModeRequired);
  }

  void _redirectToDeveloperMode() {
    if (_redirecting || isClosed || ExamRouteUtils.isOnActiveExamRoute) return;
    _redirecting = true;
    Get.offNamed(SecurityRoutes.developerModeRequired);
  }

  bool _isDeveloperModeOnlyIssue(DeviceIntegrityStatus deviceIntegrity) {
    final rasp = SecurityService.instance.lastStatus;
    if (rasp == null) return deviceIntegrity.isDeveloperModeEnabled;
    return isDeveloperModeOnlyIssue(
      status: rasp,
      strictExamIntegrity: Deployment.instance.strictExamIntegrity,
    );
  }

  Future<void> _redirectToWifiModeIfAirplaneEnabled() async {
    if (_redirecting || isClosed || ExamRouteUtils.isOnActiveExamRoute) return;

    final airplaneResult = await _checkAirplaneMode();
    if (isClosed || ExamRouteUtils.isOnActiveExamRoute) return;
    if (airplaneResult.dataOrNull?.isEnabled != true) return;

    _redirecting = true;
    Get.offNamed(SecurityRoutes.wifiModeRequired);
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

  Future<void> _loadStoredCandidateId() async {
    try {
      final stateResult = await _getOnboardingState();
      switch (stateResult) {
        case Success(:final data):
          final id = data.candidate?.candidateId;
          if (id != null && id.isNotEmpty) {
            _storedCandidateId = id;
            return;
          }
        case ErrorResult():
          break;
      }

      final rollResult = await _getRollNumber();
      switch (rollResult) {
        case Success(:final data):
          if (data != null && data.isNotEmpty) {
            _storedCandidateId = data;
            return;
          }
        case ErrorResult():
          break;
      }

      errorMessage.value = AppStrings.candidateIdNotFound;
    } catch (error, stackTrace) {
      _logger.error('_loadStoredCandidateId failed', error: error, stackTrace: stackTrace);
      errorMessage.value = AppStrings.candidateIdNotFound;
    }
  }

  Future<void> login() async {
    errorMessage.value = null;
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (_storedCandidateId.isEmpty) {
      errorMessage.value = AppStrings.candidateIdNotFound;
      return;
    }

    isLoading.value = true;
    final credentials = LoginCredentials(
      rollNumber: _storedCandidateId,
      batchPassword: batchPasswordController.text.trim(),
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
        final saveRollResult = await _saveRollNumber(_storedCandidateId);
        if (saveRollResult is ErrorResult<void>) {
          isLoading.value = false;
          _logger.error(
            'saveRollNumber failed',
            error: saveRollResult.failure.message,
          );
          errorMessage.value = AppStrings.somethingWentWrong;
          return;
        }
        final recovered = await _tryRecoverCachedSubmission();
        isLoading.value = false;
        if (recovered) return;
        isLoading.value = true;
        _stopSecurityPolling();
        _isEnteringExam = true;
        try {
          final enterResult = await _enterExamAfterCredentials(
            authSessionId: authSession.sessionId,
          );
          isLoading.value = false;
          if (enterResult is ErrorResult<void>) {
            _isEnteringExam = false;
            _logger.error(
              'enterExam failed',
              error: enterResult.failure.message,
            );
            errorMessage.value = enterResult.failure.message;
            if (!_examRunContext.isOnboardingDemo) {
              _startSecurityPolling();
            }
          }
        } catch (e, st) {
          _isEnteringExam = false;
          isLoading.value = false;
          if (kDebugMode) {
            _logger.error('enterExam failed', error: e, stackTrace: st);
          }
          errorMessage.value = AppStrings.somethingWentWrong;
          if (!_examRunContext.isOnboardingDemo) {
            _startSecurityPolling();
          }
        }
      case ErrorResult(:final failure):
        isLoading.value = false;
        errorMessage.value = failure.message;
    }
  }

  Future<bool> _tryRecoverCachedSubmission() async {
    try {
      final storedRollResult = await _getRollNumber();
      if (storedRollResult is Success<String?> &&
          storedRollResult.data != null &&
          storedRollResult.data!.isNotEmpty &&
          storedRollResult.data != _storedCandidateId) {
        if (kDebugMode) {
          _logger.info(
            'login cache recovery skipped: roll number mismatch '
            '(stored=${storedRollResult.data}, current=$_storedCandidateId)',
          );
        }
        await _clearExamLocalDataUseCase();
      }

      final hasCacheResult = await _hasCachedExamAnswersUseCase(
        rollNumber: _storedCandidateId,
      );
      if (hasCacheResult is ErrorResult<bool>) {
        _logger.error(
          'hasCachedExamAnswers failed',
          error: hasCacheResult.failure.message,
        );
        return false;
      }
      if (kDebugMode) {
        _logger.info(
          'login cache recovery check: hasCache=${hasCacheResult.dataOrNull}',
        );
      }
      if (hasCacheResult.dataOrNull != true) return false;

      isLoading.value = true;
      final recoveryResult = await _recoverCachedExamSubmissionUseCase();
      isLoading.value = false;

      switch (recoveryResult) {
        case Success(:final data):
          if (kDebugMode) {
            _logger.info('login cache recovery succeeded; routing to finish');
          }
          _stopSecurityPolling();
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
}
