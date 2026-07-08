import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/services/exam_lock_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../domain/usecases/auto_submit_exam_usecase.dart';
import '../../domain/usecases/finish_exam_usecase.dart';
import '../../domain/usecases/get_exam_timer_usecase.dart';
import '../../domain/usecases/lock_exam_session_usecase.dart';
import '../../domain/usecases/report_security_violation_usecase.dart';
import '../../domain/usecases/start_exam_session_usecase.dart';

class ExamSessionController extends GetxController {
  ExamSessionController({
    required StartExamSessionUseCase startExamSessionUseCase,
    required GetExamTimerUseCase getExamTimerUseCase,
    required AutoSubmitExamUseCase autoSubmitExamUseCase,
    required FinishExamUseCase finishExamUseCase,
    required LockExamSessionUseCase lockExamSessionUseCase,
    required ReportSecurityViolationUseCase reportSecurityViolationUseCase,
  })  : _startExamSessionUseCase = startExamSessionUseCase,
        _getExamTimerUseCase = getExamTimerUseCase,
        _autoSubmitExamUseCase = autoSubmitExamUseCase,
        _finishExamUseCase = finishExamUseCase,
        _lockExamSessionUseCase = lockExamSessionUseCase,
        _reportSecurityViolationUseCase = reportSecurityViolationUseCase;

  final StartExamSessionUseCase _startExamSessionUseCase;
  final GetExamTimerUseCase _getExamTimerUseCase;
  final AutoSubmitExamUseCase _autoSubmitExamUseCase;
  final FinishExamUseCase _finishExamUseCase;
  final LockExamSessionUseCase _lockExamSessionUseCase;
  final ReportSecurityViolationUseCase _reportSecurityViolationUseCase;

  final examSession = Rxn<ExamSession>();
  final timer = Rxn<ExamTimer>();
  final submissionReceipt = Rxn<SubmissionReceipt>();
  final lockState = Rxn<ExamLockState>();
  final currentPhase = ExamPhase.mcq.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  Timer? _timerTicker;
  Worker? _lockWorker;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<ExamLockService>()) {
      _lockWorker = ever(
        Get.find<ExamLockService>().lockState,
        _onExternalLock,
      );
    }
  }

  @override
  void onClose() {
    _timerTicker?.cancel();
    _lockWorker?.dispose();
    super.onClose();
  }

  void _onExternalLock(ExamLockState state) {
    if (!state.isLocked) return;
    _timerTicker?.cancel();
    lockState.value = state;
    currentPhase.value = ExamPhase.locked;
  }

  Future<void> startSession(String authSessionId) async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _startExamSessionUseCase(authSessionId);
    isLoading.value = false;

    switch (result) {
      case Success(:final data):
        examSession.value = data;
        currentPhase.value = ExamPhase.mcq;
        await _refreshTimer();
        _startTimerTicker();
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  Future<void> _refreshTimer() async {
    final sessionId = examSession.value?.sessionId;
    if (sessionId == null) return;

    final result = await _getExamTimerUseCase(sessionId);
    switch (result) {
      case Success(:final data):
        timer.value = data;
        if (data.remainingSeconds <= 0) {
          await autoSubmit();
        }
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  void _startTimerTicker() {
    _timerTicker?.cancel();
    _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final current = timer.value;
      if (current == null) return;

      if (current.remainingSeconds <= 0) {
        await autoSubmit();
        return;
      }

      timer.value = ExamTimer(remainingSeconds: current.remainingSeconds - 1);
    });
  }

  Future<void> autoSubmit() async {
    final sessionId = examSession.value?.sessionId;
    if (sessionId == null) return;

    _timerTicker?.cancel();
    final result = await _autoSubmitExamUseCase(sessionId);
    switch (result) {
      case Success(:final data):
        submissionReceipt.value = data;
        currentPhase.value = ExamPhase.finished;
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  Future<void> finishExam() async {
    final sessionId = examSession.value?.sessionId;
    if (sessionId == null) return;

    _timerTicker?.cancel();
    isLoading.value = true;
    final result = await _finishExamUseCase(sessionId);
    isLoading.value = false;

    switch (result) {
      case Success(:final data):
        submissionReceipt.value = data;
        currentPhase.value = ExamPhase.finished;
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  Future<void> lockSession(String reason) async {
    final sessionId = examSession.value?.sessionId;
    if (sessionId == null) return;

    final result = await _lockExamSessionUseCase(sessionId, reason);
    switch (result) {
      case Success(:final data):
        lockState.value = data;
        currentPhase.value = ExamPhase.locked;
        _timerTicker?.cancel();
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  Future<void> reportViolation(SecurityViolation violation) async {
    final result = await _reportSecurityViolationUseCase(violation);
    switch (result) {
      case Success(:final data):
        if (data.isLocked) {
          await lockSession(data.message);
        }
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  void advanceToWrittenPhase() {
    currentPhase.value = ExamPhase.written;
  }
}
