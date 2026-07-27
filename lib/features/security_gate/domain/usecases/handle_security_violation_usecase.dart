import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/exam_lock_service.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../exam_session/domain/usecases/report_security_violation_usecase.dart';
import '../../../exam_session/domain/usecases/submit_saved_exam_answers_usecase.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../utils/violation_submit_outcome.dart';
import 'stop_exam_vpn_lockdown_usecase.dart';

class HandleSecurityViolationUseCase {
  HandleSecurityViolationUseCase(
    this._lockService,
    this._reportViolationUseCase,
    this._submitSavedExamAnswersUseCase,
    this._lifecycleService,
    this._stopVpnLockdown,
    this._examRunContext, {
    this.violationRoute = AppRoutes.violation,
  });

  final ExamLockService _lockService;
  final ReportSecurityViolationUseCase _reportViolationUseCase;
  final SubmitSavedExamAnswersUseCase _submitSavedExamAnswersUseCase;
  final AppLifecycleService _lifecycleService;
  final StopExamVpnLockdownUseCase _stopVpnLockdown;
  final ExamRunContext _examRunContext;
  final String violationRoute;

  bool _handled = false;
  StreamSubscription<AppLifecycleState>? _resumeSubscription;

  Future<void> call(SecurityViolation violation) async {
    if (_examRunContext.isOnboardingDemo) return;
    if (_handled) return;
    _handled = true;

    await _lockService.lock(reason: violation.type.displayMessage);
    await _reportViolationUseCase(violation);

    var outcome = ViolationSubmitOutcome.none;
    if (violation.sessionId != null) {
      final submitResult =
          await _submitSavedExamAnswersUseCase(violation.phase);
      outcome = resolveViolationSubmitOutcome(submitResult);
    }

    await _releaseVpnIfTerminal(outcome);

    _navigateToViolation(violation, outcome: outcome);
  }

  Future<void> _releaseVpnIfTerminal(ViolationSubmitOutcome outcome) async {
    if (outcome.submissionPending) return;
    await _stopVpnLockdown();
  }

  void _navigateToViolation(
    SecurityViolation violation, {
    required ViolationSubmitOutcome outcome,
  }) {
    void navigate() {
      if (Get.currentRoute == violationRoute) return;
      Get.offAllNamed(
        violationRoute,
        arguments: <String, dynamic>{
          'violation': violation,
          'answersSubmitted': outcome.answersSubmitted,
          'submissionPending': outcome.submissionPending,
          'stopAutoRetry': outcome.stopAutoRetry,
        },
      );
    }

    navigate();

    if (_lifecycleService.currentState == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
      return;
    }

    _resumeSubscription?.cancel();
    _resumeSubscription = _lifecycleService.lifecycleStream.listen((state) {
      if (state != AppLifecycleState.resumed) return;
      _resumeSubscription?.cancel();
      _resumeSubscription = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
    });
  }

  SecurityViolation buildViolation({
    required ViolationType type,
    required ExamPhase phase,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityViolation(
      type: type,
      occurredAt: DateTime.now(),
      phase: phase,
      sessionId: sessionId,
      platform: Platform.operatingSystem,
    );
  }

  void reset() {
    _handled = false;
    _resumeSubscription?.cancel();
    _resumeSubscription = null;
  }
}
