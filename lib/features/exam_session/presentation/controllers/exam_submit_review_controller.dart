import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../security_gate/domain/usecases/check_connectivity_usecase.dart';
import '../../../security_gate/domain/usecases/observe_connectivity_usecase.dart';
import '../../domain/entities/exam_submit_summary.dart';
import '../../domain/usecases/get_exam_submit_summary_usecase.dart';
import '../../domain/usecases/submit_exam_with_pending_uploads_usecase.dart';
import 'exam_session_controller.dart';
import 'exam_submit_review_state.dart';

class ExamSubmitReviewController extends GetxController {
  ExamSubmitReviewController(
    this._sessionController,
    this._getExamSubmitSummaryUseCase,
    this._submitExamWithPendingUploadsUseCase,
    this._checkConnectivityUseCase,
    this._observeConnectivityUseCase,
    this._lifecycleService,
    this._logger,
  );

  final ExamSessionController _sessionController;
  final GetExamSubmitSummaryUseCase _getExamSubmitSummaryUseCase;
  final SubmitExamWithPendingUploadsUseCase _submitExamWithPendingUploadsUseCase;
  final CheckConnectivityUseCase _checkConnectivityUseCase;
  final ObserveConnectivityUseCase _observeConnectivityUseCase;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final reviewState = const ExamSubmitReviewState(
    viewState: ExamSubmitReviewViewState.loading,
  ).obs;
  final summary = Rxn<ExamSubmitSummary>();
  final isSubmitting = false.obs;
  final isRefreshing = false.obs;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;
  Worker? _offlineSubmitWorker;
  Worker? _phaseWorker;

  bool _isSubmitting = false;

  bool get canSubmitExam => _sessionController.canSubmitExam.value;

  @override
  void onInit() {
    super.onInit();
    _listenForOfflineSubmitSignal();
    _listenForPhaseFinished();
    unawaited(_loadSummary());
  }

  @override
  void onClose() {
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_lifecycleSubscription?.cancel());
    _offlineSubmitWorker?.dispose();
    _phaseWorker?.dispose();
    _sessionController.needsOfflineSubmit.value = false;
    super.onClose();
  }

  void _listenForOfflineSubmitSignal() {
    _offlineSubmitWorker = ever(
      _sessionController.needsOfflineSubmit,
      (needsOffline) {
        if (!needsOffline) return;
        _sessionController.needsOfflineSubmit.value = false;
        _enterWaitingState();
      },
    );
  }

  void _listenForPhaseFinished() {
    _phaseWorker = ever(_sessionController.currentPhase, (phase) {
      if (phase == ExamPhase.finished) {
        _stopConnectivityListener();
      }
    });
  }

  Future<void> refreshSummary() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      await _loadSummary();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _loadSummary() async {
    reviewState.value = reviewState.value.copyWith(
      viewState: ExamSubmitReviewViewState.loading,
      clearErrorMessage: true,
    );

    String? syncWarning;
    final timerRemainingSeconds =
        _sessionController.timer.value?.remainingSeconds;

    await _sessionController.loadCurrentExam(refresh: true);

    if (_sessionController.errorMessage.value != null) {
      final failureMessage = _sessionController.errorMessage.value!;
      if (_isNetworkMessage(failureMessage)) {
        syncWarning = AppStrings.examSubmitReviewSyncWarning;
        _sessionController.errorMessage.value = null;
      } else if (_sessionController.currentExam.value == null) {
        reviewState.value = ExamSubmitReviewState(
          viewState: ExamSubmitReviewViewState.summary,
          errorMessage: AppStrings.somethingWentWrong,
        );
        return;
      } else {
        reviewState.value = ExamSubmitReviewState(
          viewState: ExamSubmitReviewViewState.summary,
          errorMessage: AppStrings.somethingWentWrong,
        );
        return;
      }
    }

    final exam = _sessionController.currentExam.value;
    if (exam == null) {
      reviewState.value = const ExamSubmitReviewState(
        viewState: ExamSubmitReviewViewState.summary,
        errorMessage: AppStrings.somethingWentWrong,
      );
      return;
    }

    final summaryResult = await _getExamSubmitSummaryUseCase(
      exam: exam,
      timerRemainingSeconds: timerRemainingSeconds,
      sessionStartedAt: _sessionController.examSession.value?.startedAt,
    );

    switch (summaryResult) {
      case Success(:final data):
        summary.value = data;
        reviewState.value = ExamSubmitReviewState(
          viewState: ExamSubmitReviewViewState.summary,
          syncWarning: syncWarning,
        );
      case ErrorResult(:final failure):
        if (kDebugMode) {
          _logger.error('getExamSubmitSummary failed', error: failure.message);
        }
        reviewState.value = const ExamSubmitReviewState(
          viewState: ExamSubmitReviewViewState.summary,
          errorMessage: AppStrings.somethingWentWrong,
        );
    }
  }

  Future<void> submit() async {
    if (_isSubmitting || !canSubmitExam) return;

    final connectivityResult = await _checkConnectivityUseCase();
    final isOnline = connectivityResult.dataOrNull?.isOnline ?? false;
    if (!isOnline) {
      _enterWaitingState();
      return;
    }

    await _attemptSubmit();
  }

  Future<void> retrySubmit() async {
    if (_isSubmitting || reviewState.value.stopAutoRetry) return;
    await _attemptSubmit();
  }

  Future<void> _attemptSubmit() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    isSubmitting.value = true;

    try {
      final result = await _submitExamWithPendingUploadsUseCase();
      switch (result) {
        case Success(:final data):
          _sessionController.submissionReceipt.value = data.receipt;
          _sessionController.currentPhase.value = ExamPhase.finished;
          _sessionController.mcqQuestions.clear();
          _sessionController.fillBlankQuestions.clear();
          _sessionController.descriptiveQuestions.clear();
          _sessionController.currentExam.value = null;
          _stopConnectivityListener();
          Get.offAllNamed(
            AppRoutes.finishExam,
            arguments: <String, dynamic>{
              'examName': data.exam.examName,
              'submittedAt': data.receipt.submittedAt,
            },
          );
        case ErrorResult(:final failure):
          _handleSubmitFailure(failure);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error('_attemptSubmit failed', error: error, stackTrace: stackTrace);
      }
      reviewState.value = reviewState.value.copyWith(
        viewState: ExamSubmitReviewViewState.summary,
        errorMessage: AppStrings.somethingWentWrong,
      );
    } finally {
      _isSubmitting = false;
      isSubmitting.value = false;
    }
  }

  void _handleSubmitFailure(Failure failure) {
    if (failure is NetworkFailure) {
      _enterWaitingState();
      return;
    }

    if (failure is UploadFailure &&
        failure.message == AppStrings.imageFileNotFound) {
      reviewState.value = ExamSubmitReviewState(
        viewState: ExamSubmitReviewViewState.waitingForNetwork,
        waitingErrorMessage: failure.message,
        stopAutoRetry: true,
      );
      _startConnectivityListener();
      return;
    }

    if (reviewState.value.viewState == ExamSubmitReviewViewState.waitingForNetwork) {
      reviewState.value = reviewState.value.copyWith(
        waitingErrorMessage: AppStrings.somethingWentWrong,
        stopAutoRetry: true,
      );
      return;
    }

    reviewState.value = reviewState.value.copyWith(
      viewState: ExamSubmitReviewViewState.summary,
      errorMessage: AppStrings.somethingWentWrong,
    );
  }

  void _enterWaitingState() {
    reviewState.value = reviewState.value.copyWith(
      viewState: ExamSubmitReviewViewState.waitingForNetwork,
      clearErrorMessage: true,
      clearWaitingErrorMessage: true,
      stopAutoRetry: false,
    );
    _startConnectivityListener();
    _startLifecycleListener();
  }

  void _startConnectivityListener() {
    if (_connectivitySubscription != null) return;

    _connectivitySubscription = _observeConnectivityUseCase().listen(
      (status) {
        if (!status.isOnline) return;
        if (reviewState.value.viewState != ExamSubmitReviewViewState.waitingForNetwork) {
          return;
        }
        if (reviewState.value.stopAutoRetry || _isSubmitting) return;
        unawaited(_attemptSubmit());
      },
      onError: (Object error) {
        if (kDebugMode) {
          _logger.error('connectivity listener failed', error: error);
        }
      },
    );
  }

  void _startLifecycleListener() {
    if (_lifecycleSubscription != null) return;

    _lifecycleSubscription = _lifecycleService.lifecycleStream.listen((state) {
      if (state != AppLifecycleState.resumed) return;
      if (reviewState.value.viewState != ExamSubmitReviewViewState.waitingForNetwork) {
        return;
      }
      if (reviewState.value.stopAutoRetry || _isSubmitting) return;
      unawaited(_retryWhenOnline());
    });
  }

  Future<void> _retryWhenOnline() async {
    final connectivityResult = await _checkConnectivityUseCase();
    if (connectivityResult.dataOrNull?.isOnline == true) {
      await _attemptSubmit();
    }
  }

  void _stopConnectivityListener() {
    unawaited(_connectivitySubscription?.cancel());
    _connectivitySubscription = null;
    unawaited(_lifecycleSubscription?.cancel());
    _lifecycleSubscription = null;
  }

  bool _isNetworkMessage(String message) {
    return message == AppStrings.noInternetConnection ||
        message == AppStrings.networkRequestFailed ||
        message == AppStrings.requestTimedOut;
  }
}
