import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/exam_lock_service.dart';
import '../../../exam_session/domain/usecases/auto_submit_exam_usecase.dart';
import '../../../exam_session/domain/usecases/report_security_violation_usecase.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';

class HandleSecurityViolationUseCase {
  HandleSecurityViolationUseCase(
    this._lockService,
    this._reportViolationUseCase,
    this._autoSubmitExamUseCase,
    this._lifecycleService, {
    this.violationRoute = AppRoutes.violation,
  });

  final ExamLockService _lockService;
  final ReportSecurityViolationUseCase _reportViolationUseCase;
  final AutoSubmitExamUseCase _autoSubmitExamUseCase;
  final AppLifecycleService _lifecycleService;
  final String violationRoute;

  bool _handled = false;
  StreamSubscription<AppLifecycleState>? _resumeSubscription;

  Future<void> call(SecurityViolation violation) async {
    if (_handled) return;
    _handled = true;

    await _lockService.lock(reason: violation.type.displayMessage);
    await _reportViolationUseCase(violation);

    final sessionId = violation.sessionId;
    if (sessionId != null) {
      await _autoSubmitExamUseCase(sessionId);
    }

    _navigateToViolation(violation);
  }

  void _navigateToViolation(SecurityViolation violation) {
    void navigate() {
      if (Get.currentRoute == violationRoute) return;
      Get.offAllNamed(violationRoute, arguments: violation);
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
