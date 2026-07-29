import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/bindings/dependency_registry.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/device_id_service.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/identity_verification_session.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_error_toast.dart';
import '../../../exam_session/domain/usecases/enter_exam_after_credentials_usecase.dart';
import '../../domain/entities/exam_info.dart';
import '../../domain/repositories/candidate_profile_repository.dart';
import '../../domain/repositories/exam_info_repository.dart';
import '../../../../shared/domain/entities/device_details.dart';
import '../../../onboarding/domain/entities/onboarding_candidate.dart';
import '../../../onboarding/domain/usecases/get_onboarding_state_usecase.dart';
import '../../../onboarding/domain/usecases/set_onboarding_flag_usecase.dart';
import '../../../onboarding/domain/usecases/unbind_device_usecase.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../widgets/congratulations_dialog.dart';
import '../widgets/dashboard_security_settings_sheet.dart';
import '../widgets/demo_quiz_dialog.dart';
import '../widgets/unbind_device_dialog.dart';
import 'dashboard_security_settings_controller.dart';

class CandidateDashboardController extends GetxController {
  CandidateDashboardController(
    this._profileRepository,
    this._examInfoRepository,
    this._getOnboardingState,
    this._setOnboardingFlag,
    this._examRunContext,
    this._verificationSession,
    this._startOnboardingDemoExam,
    this._unbindDevice,
    this._deviceIdService,
    this._notificationRepository,
    this._logger,
  );

  final CandidateProfileRepository _profileRepository;
  final ExamInfoRepository _examInfoRepository;
  final GetOnboardingStateUseCase _getOnboardingState;
  final SetOnboardingFlagUseCase _setOnboardingFlag;
  final ExamRunContext _examRunContext;
  final IdentityVerificationSession _verificationSession;
  final StartOnboardingDemoExamUseCase _startOnboardingDemoExam;
  final UnbindDeviceUseCase _unbindDevice;
  final DeviceIdService _deviceIdService;
  final NotificationRepository _notificationRepository;
  final AppLogger _logger;

  final candidate = Rxn<OnboardingCandidate>();
  final examInfo = Rxn<ExamInfo>();
  final isLoading = true.obs;
  final isStartingDemo = false.obs;
  final isUnbinding = false.obs;
  final isDeviceBound = false.obs;
  final deviceBrandName = '—'.obs;
  final deviceModelNumber = '—'.obs;
  final deviceOsVersion = '—'.obs;
  final isDeviceInfoAvailable = false.obs;
  final hasCompletedDemo = false.obs;
  final showStartDemo = true.obs;
  final unreadNotificationCount = 0.obs;
  final isDeviceBindingExpanded = false.obs;

  final scrollController = ScrollController();
  final deviceInfoShowcaseKey = GlobalKey();
  final examInfoShowcaseKey = GlobalKey();
  final examRulesShowcaseKey = GlobalKey();
  final settingsShowcaseKey = GlobalKey();
  final notificationsShowcaseKey = GlobalKey();

  bool hasSeenDashboardTutorial = true;
  bool _isTutorialRunning = false;
  VoidCallback? _showcaseStarter;

  bool _pendingCongratulations = false;

  List<GlobalKey> get showcaseKeys => [
        deviceInfoShowcaseKey,
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
          hasCompletedDemo.value = data.hasCompletedDemo;
          showStartDemo.value = !data.hasCompletedDemo;
          isDeviceBound.value = data.isDeviceBound;
          hasSeenDashboardTutorial = data.hasSeenDashboardTutorial;
          _pendingCongratulations = Get.arguments == true &&
              data.hasCompletedDemo &&
              !data.hasSeenCongratulationsDialog;
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

      await _loadDeviceInfo();
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

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceDetails = await _deviceIdService.getDeviceDetails();
      deviceBrandName.value = deviceDetails.brandName;
      deviceModelNumber.value = deviceDetails.modelNumber;
      deviceOsVersion.value = deviceDetails.osVersion;
      isDeviceInfoAvailable.value = deviceDetails.hasDisplayableInfo;
    } catch (e, st) {
      deviceBrandName.value = DeviceDetails.unavailableValue;
      deviceModelNumber.value = DeviceDetails.unavailableValue;
      deviceOsVersion.value = DeviceDetails.unavailableValue;
      isDeviceInfoAvailable.value = false;
      if (kDebugMode) {
        _logger.error('device info load failed', error: e, stackTrace: st);
      }
    }
  }

  Future<void> _maybeShowDialogs() async {
    if (_pendingCongratulations) {
      await _showCongratulationsDialog();
      return;
    }

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

    if (!state.hasCompletedDemo && !state.hasSeenDemoDialog) {
      await _showDemoQuizDialog();
    }
  }

  Future<void> _showDemoQuizDialog() async {
    final startDemo = await Get.dialog<bool>(
      const DemoQuizDialog(),
      barrierDismissible: false,
    );
    await _setOnboardingFlag.setHasSeenDemoDialog(true);
    if (startDemo == true) {
      unawaited(onStartDemo());
    }
  }

  Future<void> onDashboardTutorialCompleted() async {
    await markDashboardTutorialSeen();
    await _maybeShowDemoDialogIfNeeded();
  }

  Future<void> _showCongratulationsDialog() async {
    final viewProcedure = await Get.dialog<bool>(
      const CongratulationsDialog(),
      barrierDismissible: false,
    );
    await _setOnboardingFlag.setHasSeenCongratulationsDialog(true);
    if (viewProcedure == true) {
      onViewExamProcedure(scheduleTutorialOnReturn: true);
    }
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

  Future<void> onStartDemo() async {
    if (isStartingDemo.value) return;

    _examRunContext.setOnboardingDemo();
    isStartingDemo.value = true;
    try {
      final result = await _startOnboardingDemoExam();
      if (result is ErrorResult) {
        AppErrorToast.show(AppStrings.somethingWentWrong);
        if (kDebugMode) {
          _logger.error('onStartDemo failed');
        }
      }
    } catch (e, st) {
      AppErrorToast.show(AppStrings.somethingWentWrong);
      if (kDebugMode) {
        _logger.error('onStartDemo failed', error: e, stackTrace: st);
      }
    } finally {
      isStartingDemo.value = false;
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

  Future<void> onUnbind() async {
    if (isUnbinding.value || isStartingDemo.value) return;

    final confirmed = await Get.dialog<bool>(
      const UnbindDeviceDialog(),
      barrierDismissible: false,
    );
    if (confirmed != true || isClosed) return;

    isUnbinding.value = true;
    try {
      final result = await _unbindDevice();
      if (isClosed) return;

      switch (result) {
        case Success():
          Get.offAllNamed(AppRoutes.getStarted);
        case ErrorResult():
          AppErrorToast.show(AppStrings.somethingWentWrong);
          if (kDebugMode) {
            _logger.error('onUnbind failed');
          }
      }
    } catch (e, st) {
      if (isClosed) return;
      AppErrorToast.show(AppStrings.somethingWentWrong);
      if (kDebugMode) {
        _logger.error('onUnbind failed', error: e, stackTrace: st);
      }
    } finally {
      if (!isClosed) {
        isUnbinding.value = false;
      }
    }
  }
}
