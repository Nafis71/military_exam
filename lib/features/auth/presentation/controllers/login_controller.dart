import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:military_exam/core/utils/validators.dart';

import '../../../../core/config/deployment.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/routing/exam_route_utils.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/widgets/app_error_toast.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../../../security_gate/domain/usecases/check_airplane_mode_usecase.dart';
import '../../../security_gate/domain/usecases/check_connectivity_usecase.dart';
import '../../../security_gate/domain/usecases/check_device_integrity_usecase.dart';
import '../../../security_gate/domain/usecases/start_security_watchdog_usecase.dart';
import '../../../security_gate/presentation/routes/security_routes.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/usecases/get_districts_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/validate_exam_eligibility_usecase.dart';

class LoginController extends GetxController {
  LoginController(
    this._loginUseCase,
    this._getDistrictsUseCase,
    this._validateEligibilityUseCase,
    this._sessionController,
    this._startWatchdog,
    this._cameraPermissionService,
    this._checkAirplaneMode,
    this._checkConnectivity,
    this._checkDeviceIntegrity,
    this._lifecycleService,
    this._logger,
  );

  final LoginUseCase _loginUseCase;
  final GetDistrictsUseCase _getDistrictsUseCase;
  final ValidateExamEligibilityUseCase _validateEligibilityUseCase;
  final ExamSessionController _sessionController;
  final StartSecurityWatchdogUseCase _startWatchdog;
  final CameraPermissionService _cameraPermissionService;
  final CheckAirplaneModeUseCase _checkAirplaneMode;
  final CheckConnectivityUseCase _checkConnectivity;
  final CheckDeviceIntegrityUseCase _checkDeviceIntegrity;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final examineeIdController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isLoadingDistricts = false.obs;
  final errorMessage = RxnString();
  final session = Rxn<AuthSession>();
  final eligibility = Rxn<ExamEligibility>();
  final districts = <String>[].obs;
  final selectedDistrict = RxnString();

  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;
  Timer? _pollTimer;
  bool _redirecting = false;
  AppLifecycleState? _lastLifecycleState;

  @override
  void onInit() {
    super.onInit();
    _lastLifecycleState = _lifecycleService.currentState;
    _listenForResume();
    _startSecurityPolling();
    unawaited(_recheckAfterReturningToForeground());
    unawaited(fetchDistricts());
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    unawaited(_lifecycleSubscription?.cancel());
    examineeIdController.dispose();
    super.onClose();
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

  Future<void> _verifySecurityRequirements() async {
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
    }
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
    isLoading.value = false;

    switch (eligibilityResult) {
      case Success(:final data):
        eligibility.value = data;
        if (!data.isEligible || data.isLocked || !data.isExamActive) {
          errorMessage.value =
              data.message ?? AppStrings.notEligible;
          return;
        }
        await _enterExam(authSession.sessionId);
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  Future<void> _enterExam(String authSessionId) async {
    final cameraGranted = await _cameraPermissionService.ensureGranted();
    if (!cameraGranted) {
      errorMessage.value = AppStrings.cameraPermissionRequiredBeforeExam;
      return;
    }

    await _sessionController.startSession(authSessionId);
    if (_sessionController.errorMessage.value != null) {
      errorMessage.value = _sessionController.errorMessage.value;
      return;
    }
    final examSession = _sessionController.examSession.value;
    if (examSession == null) return;

    _pollTimer?.cancel();
    _pollTimer = null;
    final sessionId = examSession.sessionId;
    await _startWatchdog(
      policy: const SecurityPolicy(
        requireAirplaneMode: true,
        monitoredPhases: [
          ExamPhase.mcq,
          ExamPhase.fillBlank,
          ExamPhase.written,
        ],
      ),
      phase: ExamPhase.mcq,
      sessionId: sessionId,
    );
    Get.offAllNamed(
      _sessionController.initialExamRoute,
      arguments: sessionId,
    );
  }

  String? validateDistrict(String? value) => Validators.requiredField(value);
}
