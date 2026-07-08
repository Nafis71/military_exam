import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/exam_route_utils.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/domain/usecases/start_exam_session_usecase.dart';
import '../../../security_gate/domain/usecases/check_airplane_mode_usecase.dart';
import '../../../security_gate/domain/usecases/check_connectivity_usecase.dart';
import '../../../security_gate/domain/usecases/start_security_watchdog_usecase.dart';
import '../../../security_gate/presentation/routes/security_routes.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/validate_exam_eligibility_usecase.dart';

class LoginController extends GetxController {
  LoginController(
    this._loginUseCase,
    this._validateEligibilityUseCase,
    this._startExamSessionUseCase,
    this._startWatchdog,
    this._cameraPermissionService,
    this._checkAirplaneMode,
    this._checkConnectivity,
    this._lifecycleService,
  );

  final LoginUseCase _loginUseCase;
  final ValidateExamEligibilityUseCase _validateEligibilityUseCase;
  final StartExamSessionUseCase _startExamSessionUseCase;
  final StartSecurityWatchdogUseCase _startWatchdog;
  final CameraPermissionService _cameraPermissionService;
  final CheckAirplaneModeUseCase _checkAirplaneMode;
  final CheckConnectivityUseCase _checkConnectivity;
  final AppLifecycleService _lifecycleService;

  final examineeIdController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final session = Rxn<AuthSession>();
  final eligibility = Rxn<ExamEligibility>();

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
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    unawaited(_lifecycleSubscription?.cancel());
    examineeIdController.dispose();
    passwordController.dispose();
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

  Future<void> _redirectToWifiModeIfAirplaneEnabled() async {
    if (_redirecting || isClosed || ExamRouteUtils.isOnActiveExamRoute) return;

    final airplaneResult = await _checkAirplaneMode();
    if (isClosed || ExamRouteUtils.isOnActiveExamRoute) return;
    if (airplaneResult.dataOrNull?.isEnabled != true) return;

    _redirecting = true;
    Get.offNamed(SecurityRoutes.wifiModeRequired);
  }

  Future<void> login() async {
    errorMessage.value = null;
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    final credentials = LoginCredentials(
      examineeId: examineeIdController.text.trim(),
      password: passwordController.text,
    );

    final result = await _loginUseCase(credentials);
    if (result is ErrorResult<AuthSession>) {
      isLoading.value = false;
      errorMessage.value = result.failure.message;
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

    final startResult = await _startExamSessionUseCase(authSessionId);
    switch (startResult) {
      case Success(:final data):
        _pollTimer?.cancel();
        _pollTimer = null;
        await _startWatchdog(
          policy: const SecurityPolicy(
            requireAirplaneMode: true,
            monitoredPhases: [ExamPhase.mcq, ExamPhase.written],
          ),
          phase: ExamPhase.mcq,
          sessionId: data.sessionId,
        );
        Get.offAllNamed(AppRoutes.mcqExam, arguments: data.sessionId);
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  String? validateExamineeId(String? value) => Validators.examineeId(value);

  String? validatePassword(String? value) => Validators.password(value);
}
