import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/bindings/dependency_registry.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/external_url.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/identity_verification_session.dart';
import '../../../../core/utils/external_url_launcher.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/exam_info.dart';
import '../../domain/repositories/candidate_profile_repository.dart';
import '../../domain/repositories/exam_info_repository.dart';
import '../../../onboarding/domain/entities/onboarding_candidate.dart';
import '../../../onboarding/domain/entities/onboarding_state.dart';
import '../../../onboarding/domain/usecases/get_onboarding_state_usecase.dart';
import '../../../onboarding/domain/usecases/set_onboarding_flag_usecase.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../widgets/dashboard_security_settings_sheet.dart';
import '../widgets/demo_quiz_dialog.dart';
import 'dashboard_security_settings_controller.dart';

class CandidateDashboardController extends GetxController {
  CandidateDashboardController(
    this._profileRepository,
    this._examInfoRepository,
    this._getOnboardingState,
    this._setOnboardingFlag,
    this._examRunContext,
    this._verificationSession,
    this._notificationRepository,
    this._logger,
  );

  final CandidateProfileRepository _profileRepository;
  final ExamInfoRepository _examInfoRepository;
  final GetOnboardingStateUseCase _getOnboardingState;
  final SetOnboardingFlagUseCase _setOnboardingFlag;
  final ExamRunContext _examRunContext;
  final IdentityVerificationSession _verificationSession;
  final NotificationRepository _notificationRepository;
  final AppLogger _logger;

  final candidate = Rxn<OnboardingCandidate>();
  final examInfo = Rxn<ExamInfo>();
  final isLoading = true.obs;
  final isOpeningTutorial = false.obs;
  final isDeviceBound = false.obs;
  final unreadNotificationCount = 0.obs;

  final scrollController = ScrollController();
  final examInfoShowcaseKey = GlobalKey();
  final examRulesShowcaseKey = GlobalKey();
  final settingsShowcaseKey = GlobalKey();
  final notificationsShowcaseKey = GlobalKey();

  bool hasSeenDashboardTutorial = true;
  bool _isTutorialRunning = false;
  VoidCallback? _showcaseStarter;

  List<GlobalKey> get showcaseKeys => [
        examInfoShowcaseKey,
        examRulesShowcaseKey,
        settingsShowcaseKey,
        notificationsShowcaseKey,
      ];

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_load());
  }

  Future<void> _load() async {
    _verificationSession.clear();
    isLoading.value = true;
    try {
      final stateResult = await _getOnboardingState();
      switch (stateResult) {
        case Success(:final data):
          isDeviceBound.value = data.isDeviceBound;
          hasSeenDashboardTutorial = data.hasSeenDashboardTutorial;
          await _migrateLegacyCongratulationsFlag(data);
        case ErrorResult():
          break;
      }

      final profileResult = await _profileRepository.getProfile();
      switch (profileResult) {
        case Success(:final data):
          candidate.value = data;
        case ErrorResult():
          break;
      }

      final examResult = await _examInfoRepository.getExamInfo();
      switch (examResult) {
        case Success(:final data):
          examInfo.value = data;
        case ErrorResult():
          break;
      }

      await _refreshUnreadCount();
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error('dashboard load failed', error: e, stackTrace: st);
      }
    } finally {
      isLoading.value = false;
      if (!isClosed) {
        await _maybeShowDialogs();
      }
    }
  }

  Future<void> _migrateLegacyCongratulationsFlag(
    OnboardingState data,
  ) async {
    if (!data.hasCompletedDemo || data.hasSeenCongratulationsDialog) {
      return;
    }

    try {
      await _setOnboardingFlag.setHasSeenCongratulationsDialog(true);
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error(
          'legacy congratulations flag migration failed',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  Future<void> _maybeShowDialogs() async {
    if (!hasSeenDashboardTutorial) {
      await tryStartDashboardTutorial();
      return;
    }

    await _maybeShowDemoDialogIfNeeded();
  }

  Future<void> _maybeShowDemoDialogIfNeeded() async {
    final stateResult = await _getOnboardingState();
    final state = switch (stateResult) {
      Success(:final data) => data,
      ErrorResult() => null,
    };
    if (state == null) return;

    if (!state.hasSeenDemoDialog) {
      await _showDemoQuizDialog();
    }
  }

  Future<void> _showDemoQuizDialog() async {
    final openTutorial = await Get.dialog<bool>(
      const DemoQuizDialog(),
      barrierDismissible: false,
    );
    await _setOnboardingFlag.setHasSeenDemoDialog(true);
    if (openTutorial == true) {
      unawaited(onOpenDemoTutorial());
    }
  }

  Future<void> onDashboardTutorialCompleted() async {
    await markDashboardTutorialSeen();
    await _maybeShowDemoDialogIfNeeded();
  }

  void registerShowcaseStarter(VoidCallback starter) {
    _showcaseStarter = starter;
  }

  void unregisterShowcaseStarter() {
    _showcaseStarter = null;
  }

  void resetTutorialRunningState() {
    _isTutorialRunning = false;
  }

  Future<void> tryStartDashboardTutorial() async {
    if (isClosed ||
        isLoading.value ||
        _isTutorialRunning ||
        hasSeenDashboardTutorial) {
      return;
    }

    if (Get.isDialogOpen == true || (Get.isBottomSheetOpen ?? false)) {
      return;
    }

    final starter = _showcaseStarter;
    if (starter == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isClosed && !hasSeenDashboardTutorial && !_isTutorialRunning) {
          unawaited(tryStartDashboardTutorial());
        }
      });
      return;
    }

    _isTutorialRunning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) {
        _isTutorialRunning = false;
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isClosed) {
          _isTutorialRunning = false;
          return;
        }
        starter();
      });
    });
  }

  Future<void> markDashboardTutorialSeen() async {
    if (hasSeenDashboardTutorial) {
      _isTutorialRunning = false;
      return;
    }

    hasSeenDashboardTutorial = true;
    _isTutorialRunning = false;
    try {
      await _setOnboardingFlag.setHasSeenDashboardTutorial(true);
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error(
          'mark dashboard tutorial seen failed',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  void onStartExamination() {
    _examRunContext.setReal();
    _verificationSession.clear();
    Get.toNamed(AppRoutes.identityVerification);
  }

  Future<void> onOpenDemoTutorial() async {
    if (isOpeningTutorial.value) return;

    isOpeningTutorial.value = true;
    try {
      await ExternalUrlLauncher.launchHttpUrlOrShowError(
        ExternalUrl.demoExamTutorialYouTube,
        logger: _logger,
      );
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error('onOpenDemoTutorial failed', error: e, stackTrace: st);
      }
    } finally {
      if (!isClosed) {
        isOpeningTutorial.value = false;
      }
    }
  }

  void onViewExamProcedure({bool scheduleTutorialOnReturn = false}) {
    unawaited(
      Get.toNamed(AppRoutes.examProcedure)?.then((_) {
        if (scheduleTutorialOnReturn) {
          unawaited(tryStartDashboardTutorial());
        }
      }),
    );
  }

  void onOpenNotifications() {
    unawaited(
      Get.toNamed(AppRoutes.notifications)?.then((_) => _refreshUnreadCount()),
    );
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final result = await _notificationRepository.getUnreadCount();
      switch (result) {
        case Success(:final data):
          unreadNotificationCount.value = data;
        case ErrorResult():
          unreadNotificationCount.value = 0;
      }
    } catch (e, st) {
      unreadNotificationCount.value = 0;
      if (kDebugMode) {
        _logger.error(
          'unread notification count load failed',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  void onOpenSecuritySettings() {
    if (Get.isBottomSheetOpen ?? false) return;

    DashboardSecuritySettingsBinding().dependencies();
    Get.bottomSheet<void>(
      const DashboardSecuritySettingsSheet(),
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ).whenComplete(() {
      if (Get.isRegistered<DashboardSecuritySettingsController>()) {
        Get.delete<DashboardSecuritySettingsController>();
      }
    });
  }
}
