import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../auth/domain/usecases/clear_session_usecase.dart';
import '../../../exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import '../../../exam_session/presentation/controllers/exam_session_controller.dart';
import '../../../onboarding/domain/usecases/set_onboarding_flag_usecase.dart';
import '../../domain/finish_submission_type.dart';
import '../../../security_gate/domain/usecases/stop_exam_vpn_lockdown_usecase.dart';
import '../../../security_gate/domain/usecases/stop_security_watchdog_usecase.dart';

class FinishExamController extends GetxController {
  FinishExamController(
    this._stopWatchdog,
    this._stopVpnLockdown,
    this._clearSession,
    this._clearExamLocalData,
    this._examRunContext,
    this._setOnboardingFlag,
    this._logger,
  );

  final StopSecurityWatchdogUseCase _stopWatchdog;
  final StopExamVpnLockdownUseCase _stopVpnLockdown;
  final ClearSessionUseCase _clearSession;
  final ClearExamLocalDataUseCase _clearExamLocalData;
  final ExamRunContext _examRunContext;
  final SetOnboardingFlagUseCase _setOnboardingFlag;
  final AppLogger _logger;

  late final String examName;
  late final String submittedAtLabel;
  late final FinishSubmissionType submissionType;
  late final bool isOnboardingDemo;

  String get title => submissionType == FinishSubmissionType.timeExpired
      ? AppStrings.timeExpiredTitle
      : AppStrings.submissionSuccessful;

  String get message => submissionType == FinishSubmissionType.timeExpired
      ? AppStrings.timeExpiredMessage
      : AppStrings.submissionSuccessfulMessage;

  String get primaryButtonLabel =>
      isOnboardingDemo ? AppStrings.finishExamination : AppStrings.exitApp;

  @override
  void onInit() {
    super.onInit();
    isOnboardingDemo = _examRunContext.isOnboardingDemo;
    _resolveDisplayData();
    if (isOnboardingDemo) {
      unawaited(_cleanupOnboardingDemo());
    } else {
      unawaited(_cleanupRealExam());
    }
  }

  void _resolveDisplayData() {
    final args = Get.arguments;
    String? argExamName;
    DateTime? argSubmittedAt;

    if (args is Map) {
      final name = args['examName'];
      if (name is String && name.trim().isNotEmpty) {
        argExamName = name.trim();
      }
      final submittedAt = args['submittedAt'];
      if (submittedAt is DateTime) {
        argSubmittedAt = submittedAt;
      }
      submissionType = _parseSubmissionType(args['submissionType']);
    } else {
      submissionType = FinishSubmissionType.manual;
    }

    if (argSubmittedAt == null && Get.isRegistered<ExamSessionController>()) {
      argSubmittedAt =
          Get.find<ExamSessionController>().submissionReceipt.value?.submittedAt;
    }

    examName = argExamName ?? AppStrings.finishExamDefaultName;
    submittedAtLabel = _formatSubmittedAt(argSubmittedAt ?? DateTime.now());
  }

  FinishSubmissionType _parseSubmissionType(Object? raw) {
    if (raw is FinishSubmissionType) return raw;
    if (raw is String) {
      return FinishSubmissionType.values.firstWhere(
        (type) => type.name == raw,
        orElse: () => FinishSubmissionType.manual,
      );
    }
    return FinishSubmissionType.manual;
  }

  String _formatSubmittedAt(DateTime submittedAt) {
    final hour24 = submittedAt.hour;
    final isPm = hour24 >= 12;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final time =
        '$hour12:${submittedAt.minute.toString().padLeft(2, '0')}:'
        '${submittedAt.second.toString().padLeft(2, '0')} '
        '${isPm ? 'PM' : 'AM'}';
    return toBengaliDigitString(time);
  }

  Future<void> _cleanupRealExam() async {
    try {
      await _stopWatchdog();
      await _stopVpnLockdown();
      await _clearExamLocalData();
      await _clearSession();
    } catch (e, st) {
      _logger.error('finish exam cleanup failed', error: e, stackTrace: st);
    }
  }

  Future<void> _cleanupOnboardingDemo() async {
    try {
      await _stopWatchdog();
      await _stopVpnLockdown();
      await _clearExamLocalData();
      await _setOnboardingFlag.setHasCompletedDemo(true);
      _examRunContext.reset();
    } catch (e, st) {
      _logger.error('onboarding demo cleanup failed', error: e, stackTrace: st);
    }
  }

  Future<void> onPrimaryAction() async {
    if (isOnboardingDemo) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.candidateDashboard, arguments: true);
      });
      return;
    }
    await exitApp();
  }

  Future<void> exitApp() async {
    try {
      await _stopVpnLockdown();
    } catch (e, st) {
      _logger.error('exitApp vpn stop failed', error: e, stackTrace: st);
    }
    SystemNavigator.pop();
  }
}
