import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../exam_session/domain/usecases/submit_exam_with_pending_uploads_usecase.dart';
import '../../../security_gate/domain/usecases/check_connectivity_usecase.dart';
import '../../../security_gate/domain/usecases/observe_connectivity_usecase.dart';
import '../../../security_gate/domain/usecases/stop_exam_vpn_lockdown_usecase.dart';
import '../models/violation_screen_args.dart';

class ViolationController extends GetxController {
  ViolationController(
    this._submitExamWithPendingUploadsUseCase,
    this._checkConnectivityUseCase,
    this._observeConnectivityUseCase,
    this._stopVpnLockdown,
    this._lifecycleService,
    this._logger, {
    ViolationScreenArgs? initialArgs,
  }) : _initialArgs = initialArgs;

  final SubmitExamWithPendingUploadsUseCase _submitExamWithPendingUploadsUseCase;
  final CheckConnectivityUseCase _checkConnectivityUseCase;
  final ObserveConnectivityUseCase _observeConnectivityUseCase;
  final StopExamVpnLockdownUseCase _stopVpnLockdown;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;
  final ViolationScreenArgs? _initialArgs;

  final violation = Rxn<SecurityViolation>();
  final answersSubmitted = false.obs;
  final submissionPending = false.obs;
  final stopAutoRetry = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;

  bool _isSubmitting = false;

  @override
  void onInit() {
    super.onInit();
    _readArguments(_initialArgs ?? ViolationScreenArgs.fromRoute(Get.arguments));
    if (submissionPending.value && !stopAutoRetry.value) {
      _startConnectivityListener();
      _startLifecycleListener();
    }
  }

  @override
  void onClose() {
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_lifecycleSubscription?.cancel());
    super.onClose();
  }

  void _readArguments(ViolationScreenArgs args) {
    violation.value = args.violation;
    answersSubmitted.value = args.answersSubmitted;
    submissionPending.value = args.submissionPending;
    stopAutoRetry.value = args.stopAutoRetry;
  }

  String get title => AppStrings.examPenalized;

  String get message =>
      violation.value?.type.displayMessage ??
      AppStrings.securityViolationLocked;

  String get alertMessage {
    if (answersSubmitted.value) {
      return AppStrings.examAnswersPublished;
    }
    if (submissionPending.value) {
      if (isSubmitting.value) {
        return AppStrings.violationSubmissionRetryingMessage;
      }
      if (errorMessage.value != null) {
        return errorMessage.value!;
      }
      return AppStrings.violationSubmissionPendingMessage;
    }
    return AppStrings.examCancelledAndRecorded;
  }

  List<String> get bullets => [
        isBackgroundViolation
            ? AppStrings.violationRuleBackgroundForbidden
            : AppStrings.violationRuleGeneric,
        AppStrings.violationReportedToAuthority,
      ];

  bool get isBackgroundViolation {
    final type = violation.value?.type;
    return type == ViolationType.appBackgrounded ||
        type == ViolationType.appMinimized;
  }

  Future<void> _attemptSubmit() async {
    if (_isSubmitting || stopAutoRetry.value || !submissionPending.value) {
      return;
    }

    _isSubmitting = true;
    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      final result = await _submitExamWithPendingUploadsUseCase();
      switch (result) {
        case Success():
          answersSubmitted.value = true;
          submissionPending.value = false;
          _stopListeners();
          await _stopVpnLockdown();
        case ErrorResult(:final failure):
          _handleSubmitFailure(failure);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error(
          'violation retry submit failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
      errorMessage.value = AppStrings.somethingWentWrong;
      stopAutoRetry.value = true;
      _stopListeners();
      unawaited(_stopVpnLockdown());
    } finally {
      _isSubmitting = false;
      isSubmitting.value = false;
    }
  }

  void _handleSubmitFailure(Failure failure) {
    if (failure is NetworkFailure) {
      errorMessage.value = null;
      return;
    }

    if (failure is UploadFailure &&
        failure.message == AppStrings.imageFileNotFound) {
      errorMessage.value = failure.message;
      stopAutoRetry.value = true;
      submissionPending.value = false;
      _stopListeners();
      unawaited(_stopVpnLockdown());
      return;
    }

    if (failure is UploadFailure) {
      errorMessage.value = null;
      return;
    }

    errorMessage.value = AppStrings.somethingWentWrong;
    stopAutoRetry.value = true;
    submissionPending.value = false;
    _stopListeners();
    unawaited(_stopVpnLockdown());
  }

  void _startConnectivityListener() {
    if (_connectivitySubscription != null) return;

    _connectivitySubscription = _observeConnectivityUseCase().listen(
      (status) {
        if (!status.isOnline) return;
        if (!submissionPending.value || stopAutoRetry.value || _isSubmitting) {
          return;
        }
        unawaited(_attemptSubmit());
      },
      onError: (Object error) {
        if (kDebugMode) {
          _logger.error('violation connectivity listener failed', error: error);
        }
      },
    );
  }

  void _startLifecycleListener() {
    if (_lifecycleSubscription != null) return;

    _lifecycleSubscription = _lifecycleService.lifecycleStream.listen((state) {
      if (state != AppLifecycleState.resumed) return;
      if (!submissionPending.value || stopAutoRetry.value || _isSubmitting) {
        return;
      }
      unawaited(_retryWhenOnline());
    });
  }

  Future<void> _retryWhenOnline() async {
    final connectivityResult = await _checkConnectivityUseCase();
    if (connectivityResult.dataOrNull?.isOnline == true) {
      await _attemptSubmit();
    }
  }

  void _stopListeners() {
    unawaited(_connectivitySubscription?.cancel());
    _connectivitySubscription = null;
    unawaited(_lifecycleSubscription?.cancel());
    _lifecycleSubscription = null;
  }
}
