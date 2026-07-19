import 'dart:async';

import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/exam_lock_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/usecases/clear_exam_local_data_usecase.dart';
import '../../domain/usecases/finalize_exam_usecase.dart';
import '../../domain/usecases/finish_exam_usecase.dart';
import '../../domain/usecases/get_current_exam_usecase.dart';
import '../../domain/usecases/get_exam_timer_usecase.dart';
import '../../domain/usecases/lock_exam_session_usecase.dart';
import '../../domain/usecases/report_security_violation_usecase.dart';
import '../../domain/usecases/start_exam_session_usecase.dart';
import '../../domain/usecases/submit_saved_exam_answers_usecase.dart';
import '../../domain/utils/exam_question_splitter.dart';

class ExamSessionController extends GetxController {
  ExamSessionController({
    required StartExamSessionUseCase startExamSessionUseCase,
    required GetCurrentExamUseCase getCurrentExamUseCase,
    required GetExamTimerUseCase getExamTimerUseCase,
    required SubmitSavedExamAnswersUseCase submitSavedExamAnswersUseCase,
    required FinalizeExamUseCase finalizeExamUseCase,
    required ClearExamLocalDataUseCase clearExamLocalDataUseCase,
    required FinishExamUseCase finishExamUseCase,
    required LockExamSessionUseCase lockExamSessionUseCase,
    required ReportSecurityViolationUseCase reportSecurityViolationUseCase,
  })  : _startExamSessionUseCase = startExamSessionUseCase,
        _getCurrentExamUseCase = getCurrentExamUseCase,
        _getExamTimerUseCase = getExamTimerUseCase,
        _submitSavedExamAnswersUseCase = submitSavedExamAnswersUseCase,
        _finalizeExamUseCase = finalizeExamUseCase,
        _clearExamLocalDataUseCase = clearExamLocalDataUseCase,
        _finishExamUseCase = finishExamUseCase,
        _lockExamSessionUseCase = lockExamSessionUseCase,
        _reportSecurityViolationUseCase = reportSecurityViolationUseCase;

  final StartExamSessionUseCase _startExamSessionUseCase;
  final GetCurrentExamUseCase _getCurrentExamUseCase;
  final GetExamTimerUseCase _getExamTimerUseCase;
  final SubmitSavedExamAnswersUseCase _submitSavedExamAnswersUseCase;
  final FinalizeExamUseCase _finalizeExamUseCase;
  final ClearExamLocalDataUseCase _clearExamLocalDataUseCase;
  final FinishExamUseCase _finishExamUseCase;
  final LockExamSessionUseCase _lockExamSessionUseCase;
  final ReportSecurityViolationUseCase _reportSecurityViolationUseCase;

  final examSession = Rxn<ExamSession>();
  final currentExam = Rxn<CurrentExam>();
  final timer = Rxn<ExamTimer>();
  final submissionReceipt = Rxn<SubmissionReceipt>();
  final lockState = Rxn<ExamLockState>();
  final currentPhase = ExamPhase.mcq.obs;
  final isLoading = false.obs;
  final isExamLoading = false.obs;
  final errorMessage = RxnString();
  final canAccessQuestions = true.obs;
  final canSubmitExam = true.obs;

  final mcqQuestions = <McqQuestion>[].obs;
  final fillBlankQuestions = <FillBlankQuestion>[].obs;
  final descriptiveQuestions = <WrittenQuestion>[].obs;

  Timer? _timerTicker;
  Worker? _lockWorker;
  bool _timeExpiryHandled = false;

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
        await loadCurrentExam();
        await _refreshTimer();
        _startTimerTicker();
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  Future<void> loadCurrentExam() async {
    isExamLoading.value = true;
    errorMessage.value = null;

    final result = await _getCurrentExamUseCase();
    isExamLoading.value = false;

    switch (result) {
      case Success(:final data):
        currentExam.value = data;
        canAccessQuestions.value = data.window.canAccessQuestions;
        canSubmitExam.value = data.window.canSubmit;
        mcqQuestions.assignAll(
          ExamQuestionSplitter.toMcqQuestions(data.questions),
        );
        fillBlankQuestions.assignAll(
          ExamQuestionSplitter.toFillBlankQuestions(data.questions),
        );
        descriptiveQuestions.assignAll(
          ExamQuestionSplitter.toDescriptiveQuestions(data.questions),
        );
        _applyExamDuration(data);
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
    }
  }

  void _applyExamDuration(CurrentExam exam) {
    final remainingMinutes = exam.window.remainingExamMinutes;
    if (remainingMinutes > 0) {
      timer.value = ExamTimer(remainingSeconds: remainingMinutes * 60);
      return;
    }

    final session = examSession.value;
    if (session != null && exam.durationMinutes > 0) {
      examSession.value = ExamSession(
        sessionId: session.sessionId,
        examineeId: session.examineeId,
        startedAt: session.startedAt,
        durationMinutes: exam.durationMinutes,
        isLocked: session.isLocked,
        currentPhase: session.currentPhase,
      );
    }
  }

  Future<void> _refreshTimer() async {
    final sessionId = examSession.value?.sessionId;
    if (sessionId == null) return;

    final result = await _getExamTimerUseCase(sessionId);
    switch (result) {
      case Success(:final data):
        if (timer.value == null || timer.value!.remainingSeconds <= 0) {
          timer.value = data;
        }
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
    if (_timeExpiryHandled) return;
    if (examSession.value?.sessionId == null) return;

    _timeExpiryHandled = true;
    _timerTicker?.cancel();

    final result = await _submitSavedExamAnswersUseCase(currentPhase.value);
    switch (result) {
      case Success(:final data):
        submissionReceipt.value = data;
        currentPhase.value = ExamPhase.finished;
        final examName =
            currentExam.value?.examName ?? AppStrings.finishExamDefaultName;
        mcqQuestions.clear();
        fillBlankQuestions.clear();
        descriptiveQuestions.clear();
        currentExam.value = null;
        Get.offAllNamed(
          AppRoutes.finishExam,
          arguments: <String, dynamic>{
            'examName': examName,
            'submittedAt': data.submittedAt,
            'submissionType': 'timeExpired',
          },
        );
      case ErrorResult(:final failure):
        _timeExpiryHandled = false;
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

  void advanceToFillBlankPhase() {
    currentPhase.value = ExamPhase.fillBlank;
  }

  void advanceToWrittenPhase() {
    currentPhase.value = ExamPhase.written;
  }

  String completePhaseAndGetNextRoute(ExamPhase completedPhase) {
    final nextPhase = ExamQuestionSplitter.nextPhaseAfter(
      completedPhase: completedPhase,
      fillBlankCount: fillBlankQuestions.length,
      descriptiveCount: descriptiveQuestions.length,
    );
    if (nextPhase != null) {
      currentPhase.value = nextPhase;
    }
    return ExamQuestionSplitter.nextRouteAfterPhase(
          completedPhase: completedPhase,
          mcqCount: mcqQuestions.length,
          fillBlankCount: fillBlankQuestions.length,
          descriptiveCount: descriptiveQuestions.length,
        ) ??
        AppRoutes.finishExam;
  }

  String get initialExamRoute {
    if (mcqQuestions.isNotEmpty) return AppRoutes.mcqExam;
    if (fillBlankQuestions.isNotEmpty) return AppRoutes.fillBlankExam;
    if (descriptiveQuestions.isNotEmpty) return AppRoutes.writtenExam;
    return AppRoutes.finishExam;
  }

  Future<bool> finalizeExamAndClearLocal() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _finalizeExamUseCase(currentExam.value);
    isLoading.value = false;

    switch (result) {
      case Success(:final data):
        submissionReceipt.value = data;
        await _clearExamLocalDataUseCase();
        currentPhase.value = ExamPhase.finished;
        mcqQuestions.clear();
        fillBlankQuestions.clear();
        descriptiveQuestions.clear();
        currentExam.value = null;
        return true;
      case ErrorResult(:final failure):
        errorMessage.value = failure.message;
        return false;
    }
  }
}
