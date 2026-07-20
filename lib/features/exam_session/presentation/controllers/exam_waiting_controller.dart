import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/exam_lock_service.dart';
import '../../../../core/services/security_watchdog_service.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../security_gate/domain/usecases/start_security_watchdog_usecase.dart';
import '../../domain/utils/exam_waiting_utils.dart';
import 'exam_session_controller.dart';

class ExamWaitingController extends GetxController {
  ExamWaitingController(
    this._sessionController,
    this._startWatchdog,
    this._lifecycleService,
    this._logger,
  );

  final ExamSessionController _sessionController;
  final StartSecurityWatchdogUseCase _startWatchdog;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final remainingTime = Duration.zero.obs;
  final errorMessage = RxnString();
  final isRefreshing = false.obs;

  Timer? _countdownTimer;
  Timer? _pollTimer;
  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;
  Worker? _lockWorker;
  bool _isTransitioning = false;
  late final String sessionId;
  bool _isPollingAtZero = false;

  String get examName =>
      _sessionController.currentExam.value?.examName ??
      AppStrings.finishExamDefaultName;

  int get durationMinutes =>
      _sessionController.currentExam.value?.durationMinutes ?? 0;

  bool get hasCountdownTarget => _sessionController.hasCountdownTarget;

  @override
  void onInit() {
    super.onInit();
    sessionId = Get.arguments as String? ?? '';
    _updateRemainingTime();
    _startCountdown();
    _startPolling();
    _listenForResume();
    _listenForLock();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    unawaited(_lifecycleSubscription?.cancel());
    _lockWorker?.dispose();
    super.onClose();
  }

  void _listenForLock() {
    if (!Get.isRegistered<ExamLockService>()) return;
    _lockWorker = ever(
      Get.find<ExamLockService>().lockState,
      (state) {
        if (state.isLocked) {
          _countdownTimer?.cancel();
          _pollTimer?.cancel();
        }
      },
    );
  }

  void _listenForResume() {
    _lifecycleSubscription = _lifecycleService.lifecycleStream.listen((state) {
      if (state == AppLifecycleState.resumed) {
        _updateRemainingTime();
        unawaited(_pollCurrentExam());
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
      if (_sessionController.isWaitingForExamStart) {
        if (remainingTime.value == Duration.zero) {
          unawaited(_onCountdownReachedZero());
        }
        return;
      }
      unawaited(_transitionToExam());
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (remainingTime.value == Duration.zero ||
          !_sessionController.hasCountdownTarget) {
        unawaited(_pollCurrentExam());
      }
    });
  }

  void _updateRemainingTime() {
    remainingTime.value = _sessionController.timeUntilExamStart;
  }

  Future<void> _onCountdownReachedZero() async {
    if (_isTransitioning || _isPollingAtZero) return;
    _isPollingAtZero = true;
    try {
      await _pollCurrentExam();
      if (!_sessionController.isWaitingForExamStart) {
        await _transitionToExam();
      }
    } finally {
      _isPollingAtZero = false;
    }
  }

  Future<void> refreshExamWindow() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    errorMessage.value = null;
    try {
      await _pollCurrentExam();
      _updateRemainingTime();
      if (!_sessionController.isWaitingForExamStart) {
        await _transitionToExam();
      }
    } catch (error, stackTrace) {
      _logger.error('refreshExamWindow failed', error: error, stackTrace: stackTrace);
      errorMessage.value = AppStrings.examWaitingSyncFailed;
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _pollCurrentExam() async {
    try {
      await _sessionController.loadCurrentExam(refresh: true);
      if (_sessionController.errorMessage.value != null) {
        errorMessage.value = AppStrings.examWaitingSyncFailed;
        return;
      }
      errorMessage.value = null;
      _updateRemainingTime();
      if (!_sessionController.isWaitingForExamStart) {
        await _transitionToExam();
      }
    } catch (error, stackTrace) {
      _logger.error('pollCurrentExam failed', error: error, stackTrace: stackTrace);
      errorMessage.value = AppStrings.examWaitingSyncFailed;
    }
  }

  Future<void> _transitionToExam() async {
    if (_isTransitioning || isClosed) return;
    _isTransitioning = true;
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    try {
      final ready = await _sessionController.beginExamAfterWaiting();
      if (!ready) {
        _isTransitioning = false;
        _startCountdown();
        _startPolling();
        return;
      }

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
        sessionId: _sessionController.examSession.value?.sessionId ?? sessionId,
      );

      if (isClosed) return;
      Get.offAllNamed(
        _sessionController.initialExamRoute,
        arguments: _sessionController.examSession.value?.sessionId ?? sessionId,
      );
    } catch (error, stackTrace) {
      _isTransitioning = false;
      _logger.error('_transitionToExam failed', error: error, stackTrace: stackTrace);
      errorMessage.value = AppStrings.somethingWentWrong;
      _startCountdown();
      _startPolling();
    }
  }

  String get formattedCountdown =>
      ExamWaitingUtils.formatCountdown(remainingTime.value);
}
