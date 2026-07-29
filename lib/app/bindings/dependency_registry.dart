import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/storage/hive_initializer.dart';
import '../../core/storage/secure_storage_provider.dart';
import '../../features/exam_session/data/datasources/demo_exam_memory_store.dart';
import '../../features/exam_session/data/datasources/exam_answers_hive_datasource.dart';

import '../../core/config/deployment.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_factory.dart';
import '../../core/services/camera_permission_service.dart';
import '../../core/services/document_edge_detection_service.dart';
import '../../core/services/exam_connectivity_alert_service.dart';
import '../../core/services/device_id_service.dart';
import '../../core/services/exam_run_context.dart';
import '../../core/services/identity_verification_session.dart';
import '../../core/services/platform_settings_service.dart';
import '../../core/services/screen_security_service.dart';
import '../../core/services/app_lifecycle_service.dart';
import '../../core/services/auth_token_holder.dart';
import '../../core/services/exam_lock_service.dart';
import '../../core/services/security_watchdog_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/session_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/repositories/session_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/session_repository.dart';
import '../../features/auth/domain/usecases/clear_session_usecase.dart';
import '../../features/auth/domain/usecases/get_current_session_usecase.dart';
import '../../features/auth/domain/usecases/get_districts_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/validate_exam_eligibility_usecase.dart';
import '../../features/auth/presentation/controllers/login_controller.dart';
import '../../app/services/pending_exam_answers_flusher_impl.dart';
import '../../features/exam_session/data/datasources/exam_local_datasource.dart';
import '../../features/exam_session/data/datasources/exam_remote_datasource.dart';
import '../../features/exam_session/data/repositories/exam_repository_impl.dart';
import '../../features/exam_session/data/repositories/penalty_repository_impl.dart';
import '../../features/exam_session/domain/repositories/exam_repository.dart';
import '../../features/exam_session/domain/repositories/penalty_repository.dart';
import '../../features/exam_session/domain/ports/pending_exam_answers_flusher.dart';
import '../../features/exam_session/domain/usecases/finish_exam_usecase.dart';
import '../../features/exam_session/domain/usecases/clear_exam_local_data_usecase.dart';
import '../../features/exam_session/domain/usecases/finalize_exam_usecase.dart';
import '../../features/exam_session/domain/usecases/get_current_exam_usecase.dart';
import '../../features/exam_session/domain/usecases/get_roll_number_usecase.dart';
import '../../features/exam_session/domain/usecases/save_roll_number_usecase.dart';
import '../../features/exam_session/domain/usecases/get_exam_timer_usecase.dart';
import '../../features/exam_session/domain/usecases/lock_exam_session_usecase.dart';
import '../../features/exam_session/domain/usecases/report_security_violation_usecase.dart';
import '../../features/exam_session/domain/usecases/start_exam_session_usecase.dart';
import '../../features/exam_session/domain/usecases/submit_saved_exam_answers_usecase.dart';
import '../../features/exam_session/domain/usecases/get_exam_submit_summary_usecase.dart';
import '../../features/exam_session/domain/usecases/has_cached_exam_answers_usecase.dart';
import '../../features/exam_session/domain/usecases/recover_cached_exam_submission_usecase.dart';
import '../../features/exam_session/domain/usecases/submit_exam_with_pending_uploads_usecase.dart';
import '../../features/exam_session/domain/usecases/upload_pending_written_images_usecase.dart';
import '../../features/exam_session/presentation/controllers/exam_session_controller.dart';
import '../../features/exam_session/presentation/controllers/exam_submit_review_controller.dart';
import '../../features/exam_session/presentation/controllers/exam_waiting_controller.dart';
import '../../core/services/exam_vpn_lockdown_service.dart';
import '../../features/candidate_dashboard/data/repositories/candidate_profile_repository_impl.dart';
import '../../features/candidate_dashboard/data/repositories/mock_exam_info_repository.dart';
import '../../features/candidate_dashboard/domain/repositories/candidate_profile_repository.dart';
import '../../features/candidate_dashboard/domain/repositories/exam_info_repository.dart';
import '../../features/candidate_dashboard/presentation/controllers/candidate_dashboard_controller.dart';
import '../../features/candidate_dashboard/presentation/controllers/dashboard_security_settings_controller.dart';
import '../../features/exam_session/domain/usecases/enter_exam_after_credentials_usecase.dart';
import '../../features/onboarding/data/datasources/candidate_secure_datasource.dart';
import '../../features/onboarding/data/datasources/onboarding_local_datasource.dart';
import '../../features/onboarding/data/datasources/onboarding_prefs_local_datasource.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/candidate_login_usecase.dart';
import '../../features/onboarding/domain/usecases/get_onboarding_state_usecase.dart';
import '../../features/onboarding/domain/usecases/set_onboarding_flag_usecase.dart';
import '../../features/onboarding/domain/usecases/unbind_device_usecase.dart';
import '../../features/onboarding/presentation/controllers/candidate_login_controller.dart';
import '../../features/onboarding/presentation/controllers/get_started_controller.dart';
import '../../features/finish_exam/presentation/controllers/finish_exam_controller.dart';
import '../../features/identity_verification/data/repositories/identity_verification_repository_impl.dart';
import '../../features/identity_verification/domain/repositories/identity_verification_repository.dart';
import '../../features/identity_verification/domain/usecases/verify_candidate_qr_usecase.dart';
import '../../features/identity_verification/presentation/controllers/identity_verification_controller.dart';
import '../../features/instructions/presentation/controllers/instructions_controller.dart';
import '../../features/fill_blank_exam/domain/usecases/get_fill_blank_progress_usecase.dart';
import '../../features/fill_blank_exam/domain/usecases/get_fill_blank_questions_usecase.dart';
import '../../features/fill_blank_exam/domain/usecases/save_fill_blank_answer_usecase.dart';
import '../../features/fill_blank_exam/presentation/controllers/fill_blank_exam_controller.dart';
import '../../features/mcq_exam/domain/usecases/get_current_mcq_progress_usecase.dart';
import '../../features/mcq_exam/domain/usecases/get_mcq_questions_usecase.dart';
import '../../features/mcq_exam/domain/usecases/save_mcq_answer_usecase.dart';
import '../../features/mcq_exam/presentation/controllers/mcq_exam_controller.dart';
import '../../features/security_gate/data/datasources/security_local_datasource.dart';
import '../../features/security_gate/data/repositories/security_repository_impl.dart';
import '../../features/security_gate/domain/repositories/security_repository.dart';
import '../../features/security_gate/domain/usecases/check_airplane_mode_usecase.dart';
import '../../features/security_gate/domain/usecases/check_connectivity_usecase.dart';
import '../../features/security_gate/domain/usecases/check_device_integrity_usecase.dart';
import '../../features/security_gate/domain/usecases/complete_security_pre_exam_usecase.dart';
import '../../features/security_gate/domain/usecases/handle_security_violation_usecase.dart';
import '../../features/security_gate/domain/usecases/observe_airplane_mode_usecase.dart';
import '../../features/security_gate/domain/usecases/observe_connectivity_usecase.dart';
import '../../features/security_gate/domain/usecases/open_airplane_mode_settings_usecase.dart';
import '../../features/security_gate/domain/usecases/open_developer_mode_settings_usecase.dart';
import '../../features/security_gate/domain/usecases/open_wifi_settings_usecase.dart';
import '../../features/security_gate/domain/usecases/start_security_watchdog_usecase.dart';
import '../../features/security_gate/domain/usecases/stop_exam_vpn_lockdown_usecase.dart';
import '../../features/security_gate/domain/usecases/stop_security_watchdog_usecase.dart';
import '../../features/security_gate/presentation/controllers/airplane_mode_controller.dart';
import '../../features/security_gate/presentation/controllers/camera_permission_controller.dart';
import '../../features/security_gate/presentation/controllers/developer_mode_controller.dart';
import '../../features/security_gate/presentation/controllers/security_gate_controller.dart';
import '../../features/security_gate/presentation/controllers/vpn_lockdown_controller.dart';
import '../../features/security_gate/presentation/controllers/wifi_mode_controller.dart';
import '../../features/splash/presentation/controllers/splash_controller.dart';
import '../../features/violation/presentation/controllers/violation_controller.dart';
import '../../features/written_exam/data/repositories/written_exam_repository_impl.dart';
import '../../features/written_exam/domain/repositories/written_exam_repository.dart';
import '../../features/written_exam/domain/usecases/add_written_image_usecase.dart';
import '../../features/written_exam/domain/usecases/delete_written_image_usecase.dart';
import '../../features/written_exam/domain/usecases/get_written_images_usecase.dart';
import '../../features/written_exam/domain/usecases/mark_written_image_uploaded_usecase.dart';
import '../../features/written_exam/domain/usecases/save_descriptive_draft_usecase.dart';
import '../../features/written_exam/domain/usecases/upload_descriptive_answer_image_usecase.dart';
import '../../features/written_exam/presentation/controllers/written_exam_controller.dart';
import '../routes/app_routes.dart';

class DependencyRegistry {
  static Future<void> init({bool demo = false}) async {
    Deployment.init(demo: demo);

    final logger = AppLogger();
    Get.put<AppLogger>(logger, permanent: true);
    Get.put<ErrorMapper>(ErrorMapper(), permanent: true);

    final tokenHolder = AuthTokenHolder();
    Get.put<AuthTokenHolder>(tokenHolder, permanent: true);

    final secureStorage = SecureStorageProvider.instance;
    await HiveInitializer.init();
    final onboardingPrefsBox =
        await HiveInitializer.openBox(AppHiveBoxes.onboardingPrefs);
    final sessionBox = await HiveInitializer.openBox(AppHiveBoxes.session);
    final examCacheBox = await HiveInitializer.openBox(AppHiveBoxes.examCache);
    final writtenExamMetaBox =
        await HiveInitializer.openBox(AppHiveBoxes.writtenExamMeta);

    Get.put<DemoExamMemoryStore>(DemoExamMemoryStore(), permanent: true);
    Get.put<ExamRunContext>(
      ExamRunContext(Get.find<DemoExamMemoryStore>()),
      permanent: true,
    );
    Get.put<IdentityVerificationSession>(
      IdentityVerificationSession(),
      permanent: true,
    );
    Get.put<DeviceIdService>(DeviceIdService(), permanent: true);

    final onboardingLocal = OnboardingLocalDataSourceImpl(
      CandidateSecureDataSourceImpl(secureStorage),
      OnboardingPrefsHiveDataSourceImpl(onboardingPrefsBox),
    );
    final onboardingRepo = OnboardingRepositoryImpl(onboardingLocal);
    Get.put<OnboardingRepository>(onboardingRepo, permanent: true);

    final sessionLocal = SessionLocalDataSourceImpl(sessionBox);
    final sessionRepo = SessionRepositoryImpl(sessionLocal);
    Get.put<SessionRepository>(sessionRepo, permanent: true);

    final dio = DioFactory(
      logger: logger,
      tokenProvider: () => tokenHolder.token,
    ).create();
    Get.put<Dio>(dio, permanent: true);

    final apiClient = ApiClient(dio, Get.find<ErrorMapper>());
    Get.put<ApiClient>(apiClient, permanent: true);

    final authRemote = AuthRemoteDataSourceImpl(apiClient, logger);
    final authRepo = AuthRepositoryImpl(authRemote);
    Get.put<AuthRepository>(authRepo, permanent: true);

    final examRemote = ExamRemoteDataSourceImpl(
      apiClient,
      logger,
      Get.find<ExamRunContext>(),
    );
    final examLocal = ExamLocalDataSourceImpl(examCacheBox);
    final examAnswersHive = await HiveInitializer.initExamAnswers();
    Get.put<ExamAnswersHiveDataSource>(examAnswersHive, permanent: true);
    final examRepo = ExamRepositoryImpl(
      examRemote,
      examLocal,
      examAnswersHive,
      Get.find<ExamRunContext>(),
      Get.find<DemoExamMemoryStore>(),
      onboardingRepo,
    );
    Get.put<ExamRepository>(examRepo, permanent: true);

    final penaltyRepo = PenaltyRepositoryImpl(examLocal);
    Get.put<PenaltyRepository>(penaltyRepo, permanent: true);

    final writtenRepo = WrittenExamRepositoryImpl(
      apiClient,
      writtenExamMetaBox,
      Get.find<ExamRunContext>(),
      Get.find<DemoExamMemoryStore>(),
    );
    Get.put<WrittenExamRepository>(writtenRepo, permanent: true);

    final platformSettings = PlatformSettingsService();
    Get.put<PlatformSettingsService>(platformSettings, permanent: true);

    final cameraPermissionService = CameraPermissionService();
    Get.put<CameraPermissionService>(cameraPermissionService, permanent: true);

    final identityVerificationRepo = IdentityVerificationRepositoryImpl();
    Get.put<IdentityVerificationRepository>(
      identityVerificationRepo,
      permanent: true,
    );
    Get.put(
      VerifyCandidateQrUseCase(identityVerificationRepo),
      permanent: true,
    );

    final documentEdgeDetectionService = DocumentEdgeDetectionService();
    Get.put<DocumentEdgeDetectionService>(
      documentEdgeDetectionService,
      permanent: true,
    );

    final securityLocal = SecurityLocalDataSource(platformSettings);
    final securityRepo = SecurityRepositoryImpl(securityLocal);
    Get.put<SecurityRepository>(securityRepo, permanent: true);

    final lifecycleService = AppLifecycleService();
    await lifecycleService.init();
    Get.put<AppLifecycleService>(lifecycleService, permanent: true);

    final lockService = ExamLockService();
    Get.put<ExamLockService>(lockService, permanent: true);

    Get.put(StartExamSessionUseCase(examRepo), permanent: true);
    Get.put(GetCurrentExamUseCase(examRepo), permanent: true);
    Get.put(GetExamTimerUseCase(examRepo), permanent: true);
    Get.put(FinishExamUseCase(examRepo), permanent: true);
    Get.put(FinalizeExamUseCase(examRepo, writtenRepo), permanent: true);
    Get.put(ClearExamLocalDataUseCase(examRepo, writtenRepo), permanent: true);
    Get.put(
      UploadPendingWrittenImagesUseCase(
        examRepo,
        writtenRepo,
        Get.find<ExamRunContext>(),
      ),
      permanent: true,
    );
    Get.put(GetExamSubmitSummaryUseCase(examRepo), permanent: true);
    Get.put(
      SubmitExamWithPendingUploadsUseCase(
        examRepo,
        Get.find<UploadPendingWrittenImagesUseCase>(),
        Get.find<FinalizeExamUseCase>(),
        Get.find<ClearExamLocalDataUseCase>(),
      ),
      permanent: true,
    );
    Get.put(
      HasCachedExamAnswersUseCase(examRepo, writtenRepo),
      permanent: true,
    );
    Get.put(
      RecoverCachedExamSubmissionUseCase(
        Get.find<SubmitExamWithPendingUploadsUseCase>(),
      ),
      permanent: true,
    );
    Get.put<PendingExamAnswersFlusher>(
      PendingExamAnswersFlusherImpl(Get.find<AppLogger>()),
      permanent: true,
    );
    Get.put(
      SubmitSavedExamAnswersUseCase(
        Get.find<PendingExamAnswersFlusher>(),
        examRepo,
        Get.find<UploadPendingWrittenImagesUseCase>(),
        Get.find<FinalizeExamUseCase>(),
        Get.find<ClearExamLocalDataUseCase>(),
      ),
      permanent: true,
    );
    Get.put(SaveRollNumberUseCase(examRepo), permanent: true);
    Get.put(GetRollNumberUseCase(examRepo), permanent: true);
    Get.put(LockExamSessionUseCase(examRepo), permanent: true);
    Get.put(
      ReportSecurityViolationUseCase(
        examRepo,
        penaltyRepo,
        Get.find<ExamRunContext>(),
      ),
      permanent: true,
    );

    Get.put(
      ExamSessionController(
        startExamSessionUseCase: Get.find<StartExamSessionUseCase>(),
        getCurrentExamUseCase: Get.find<GetCurrentExamUseCase>(),
        getExamTimerUseCase: Get.find<GetExamTimerUseCase>(),
        submitSavedExamAnswersUseCase: Get.find<SubmitSavedExamAnswersUseCase>(),
        uploadPendingWrittenImagesUseCase:
            Get.find<UploadPendingWrittenImagesUseCase>(),
        finalizeExamUseCase: Get.find<FinalizeExamUseCase>(),
        clearExamLocalDataUseCase: Get.find<ClearExamLocalDataUseCase>(),
        finishExamUseCase: Get.find<FinishExamUseCase>(),
        lockExamSessionUseCase: Get.find<LockExamSessionUseCase>(),
        reportSecurityViolationUseCase:
            Get.find<ReportSecurityViolationUseCase>(),
        examRunContext: Get.find<ExamRunContext>(),
      ),
      permanent: true,
    );

    final vpnLockdownService = ExamVpnLockdownService(logger);
    await vpnLockdownService.initialize();
    Get.put<ExamVpnLockdownService>(vpnLockdownService, permanent: true);

    final stopVpnLockdown = StopExamVpnLockdownUseCase(vpnLockdownService);
    Get.put<StopExamVpnLockdownUseCase>(stopVpnLockdown, permanent: true);

    final handleViolation = HandleSecurityViolationUseCase(
      lockService,
      Get.find<ReportSecurityViolationUseCase>(),
      Get.find<SubmitSavedExamAnswersUseCase>(),
      lifecycleService,
      stopVpnLockdown,
      Get.find<ExamRunContext>(),
      violationRoute: AppRoutes.violation,
    );
    Get.put<HandleSecurityViolationUseCase>(handleViolation, permanent: true);

    final screenSecurityService = ScreenSecurityService(logger);
    Get.put<ScreenSecurityService>(screenSecurityService, permanent: true);

    final examConnectivityAlertService = ExamConnectivityAlertService();
    Get.put<ExamConnectivityAlertService>(
      examConnectivityAlertService,
      permanent: true,
    );

    final watchdog = SecurityWatchdogService(
      securityRepo,
      ObserveAirplaneModeUseCase(securityRepo),
      ObserveConnectivityUseCase(securityRepo),
      examConnectivityAlertService,
      handleViolation,
      lifecycleService,
      screenSecurityService,
      vpnLockdownService,
      logger,
    );
    Get.put<SecurityWatchdogService>(watchdog, permanent: true);

    Get.put(LoginUseCase(authRepo, sessionRepo, tokenHolder), permanent: true);
    Get.put(GetDistrictsUseCase(authRepo), permanent: true);
    Get.put(ValidateExamEligibilityUseCase(authRepo), permanent: true);
    Get.put(GetCurrentSessionUseCase(sessionRepo), permanent: true);
    Get.put(ClearSessionUseCase(sessionRepo, tokenHolder), permanent: true);

    Get.put(GetOnboardingStateUseCase(onboardingRepo), permanent: true);
    Get.put(SetOnboardingFlagUseCase(onboardingRepo), permanent: true);
    Get.put(
      CandidateLoginUseCase(
        onboardingRepo,
        Get.find<SaveRollNumberUseCase>(),
      ),
      permanent: true,
    );
    Get.put<ExamInfoRepository>(MockExamInfoRepository(), permanent: true);
    Get.put<CandidateProfileRepository>(
      CandidateProfileRepositoryImpl(onboardingRepo),
      permanent: true,
    );

    Get.put(CheckDeviceIntegrityUseCase(securityRepo), permanent: true);
    Get.put(CheckAirplaneModeUseCase(securityRepo), permanent: true);
    Get.put(CheckConnectivityUseCase(securityRepo), permanent: true);
    Get.put(ObserveAirplaneModeUseCase(securityRepo), permanent: true);
    Get.put(ObserveConnectivityUseCase(securityRepo), permanent: true);
    Get.put(OpenAirplaneModeSettingsUseCase(securityRepo), permanent: true);
    Get.put(OpenWifiSettingsUseCase(securityRepo), permanent: true);
    Get.put(OpenDeveloperModeSettingsUseCase(securityRepo), permanent: true);
    Get.put(
      StartSecurityWatchdogUseCase(watchdog, Get.find<ExamRunContext>()),
      permanent: true,
    );
    Get.put(StopSecurityWatchdogUseCase(watchdog), permanent: true);
    Get.put(
      UnbindDeviceUseCase(
        Get.find<StopSecurityWatchdogUseCase>(),
        Get.find<StopExamVpnLockdownUseCase>(),
        Get.find<ScreenSecurityService>(),
        Get.find<ClearExamLocalDataUseCase>(),
        Get.find<ClearSessionUseCase>(),
        onboardingRepo,
        Get.find<IdentityVerificationSession>(),
        Get.find<ExamRunContext>(),
      ),
      permanent: true,
    );
    Get.put(
      EnterExamAfterCredentialsUseCase(
        Get.find<ExamSessionController>(),
        cameraPermissionService,
        Get.find<StartSecurityWatchdogUseCase>(),
        vpnLockdownService,
      ),
      permanent: true,
    );
    Get.put(
      StartOnboardingDemoExamUseCase(
        Get.find<ExamRunContext>(),
        Get.find<EnterExamAfterCredentialsUseCase>(),
        Get.find<ClearExamLocalDataUseCase>(),
      ),
      permanent: true,
    );
    Get.put(
      CompleteSecurityPreExamUseCase(cameraPermissionService),
      permanent: true,
    );
    Get.put(GetMcqQuestionsUseCase(examRepo), permanent: true);
    Get.put(SaveMcqAnswerUseCase(examRepo), permanent: true);
    Get.put(GetCurrentMcqProgressUseCase(examRepo), permanent: true);
    Get.put(GetFillBlankQuestionsUseCase(examRepo), permanent: true);
    Get.put(SaveFillBlankAnswerUseCase(examRepo), permanent: true);
    Get.put(GetFillBlankProgressUseCase(examRepo), permanent: true);
    Get.put(AddWrittenImageUseCase(writtenRepo), permanent: true);
    Get.put(GetWrittenImagesUseCase(writtenRepo), permanent: true);
    Get.put(DeleteWrittenImageUseCase(writtenRepo), permanent: true);
    Get.put(UploadDescriptiveAnswerImageUseCase(examRepo), permanent: true);
    Get.put(SaveDescriptiveDraftUseCase(examRepo), permanent: true);
    Get.put(MarkWrittenImageUploadedUseCase(writtenRepo), permanent: true);
  }
}

class AppBinding extends Bindings {
  @override
  void dependencies() {}
}

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController(Get.find<GetOnboardingStateUseCase>()));
  }
}

class GetStartedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(GetStartedController.new);
  }
}

class CandidateLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CandidateLoginController(
        Get.find<CandidateLoginUseCase>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class CandidateDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CandidateDashboardController(
        Get.find<CandidateProfileRepository>(),
        Get.find<ExamInfoRepository>(),
        Get.find<GetOnboardingStateUseCase>(),
        Get.find<SetOnboardingFlagUseCase>(),
        Get.find<ExamRunContext>(),
        Get.find<IdentityVerificationSession>(),
        Get.find<StartOnboardingDemoExamUseCase>(),
        Get.find<UnbindDeviceUseCase>(),
        Get.find<DeviceIdService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class DashboardSecuritySettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DashboardSecuritySettingsController(
        Get.find<CheckAirplaneModeUseCase>(),
        Get.find<CheckConnectivityUseCase>(),
        Get.find<OpenAirplaneModeSettingsUseCase>(),
        Get.find<OpenWifiSettingsUseCase>(),
        Get.find<ExamVpnLockdownService>(),
        Get.find<CameraPermissionService>(),
        Get.find<SecurityWatchdogService>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class InstructionsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(InstructionsController.new);
}

class IdentityVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => IdentityVerificationController(
        Get.find<CameraPermissionService>(),
        Get.find<VerifyCandidateQrUseCase>(),
        Get.find<IdentityVerificationSession>(),
        Get.find<ExamRunContext>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class SecurityGateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SecurityGateController(
        Get.find<CheckDeviceIntegrityUseCase>(),
        Get.find<CheckAirplaneModeUseCase>(),
        Get.find<CheckConnectivityUseCase>(),
        Get.find<ExamVpnLockdownService>(),
        Get.find<CompleteSecurityPreExamUseCase>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class AirplaneModeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AirplaneModeController(
        Get.find<CheckAirplaneModeUseCase>(),
        Get.find<OpenAirplaneModeSettingsUseCase>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class WifiModeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => WifiModeController(
        Get.find<CheckConnectivityUseCase>(),
        Get.find<ObserveConnectivityUseCase>(),
        Get.find<OpenWifiSettingsUseCase>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class VpnLockdownBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => VpnLockdownController(
        Get.find<ExamVpnLockdownService>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class DeveloperModeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DeveloperModeController(
        Get.find<CheckDeviceIntegrityUseCase>(),
        Get.find<OpenDeveloperModeSettingsUseCase>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class CameraPermissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CameraPermissionController(
        Get.find<CameraPermissionService>(),
        Get.find<CompleteSecurityPreExamUseCase>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LoginController(
        Get.find<LoginUseCase>(),
        Get.find<ValidateExamEligibilityUseCase>(),
        Get.find<HasCachedExamAnswersUseCase>(),
        Get.find<RecoverCachedExamSubmissionUseCase>(),
        Get.find<ClearExamLocalDataUseCase>(),
        Get.find<GetOnboardingStateUseCase>(),
        Get.find<GetRollNumberUseCase>(),
        Get.find<SaveRollNumberUseCase>(),
        Get.find<EnterExamAfterCredentialsUseCase>(),
        Get.find<CheckAirplaneModeUseCase>(),
        Get.find<CheckConnectivityUseCase>(),
        Get.find<CheckDeviceIntegrityUseCase>(),
        Get.find<ExamVpnLockdownService>(),
        Get.find<StopSecurityWatchdogUseCase>(),
        Get.find<StopExamVpnLockdownUseCase>(),
        Get.find<AppLifecycleService>(),
        Get.find<ScreenSecurityService>(),
        Get.find<SecurityWatchdogService>(),
        Get.find<ExamRunContext>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class ExamWaitingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ExamWaitingController(
        Get.find<ExamSessionController>(),
        Get.find<StartSecurityWatchdogUseCase>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class ExamSubmitReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ExamSubmitReviewController(
        Get.find<ExamSessionController>(),
        Get.find<GetExamSubmitSummaryUseCase>(),
        Get.find<SubmitExamWithPendingUploadsUseCase>(),
        Get.find<CheckConnectivityUseCase>(),
        Get.find<ObserveConnectivityUseCase>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class McqExamBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ExamSessionController>()) {
      Get.put(
        ExamSessionController(
          startExamSessionUseCase: Get.find(),
          getCurrentExamUseCase: Get.find(),
          getExamTimerUseCase: Get.find(),
          submitSavedExamAnswersUseCase: Get.find(),
          uploadPendingWrittenImagesUseCase: Get.find(),
          finalizeExamUseCase: Get.find(),
          clearExamLocalDataUseCase: Get.find(),
          finishExamUseCase: Get.find(),
          lockExamSessionUseCase: Get.find(),
          reportSecurityViolationUseCase: Get.find(),
          examRunContext: Get.find<ExamRunContext>(),
        ),
        permanent: true,
      );
    }
    Get.lazyPut(
      () => McqExamController(
        getMcqQuestionsUseCase: Get.find(),
        saveMcqAnswerUseCase: Get.find(),
        getCurrentMcqProgressUseCase: Get.find(),
      ),
    );
  }
}

class FillBlankExamBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ExamSessionController>()) {
      Get.put(
        ExamSessionController(
          startExamSessionUseCase: Get.find(),
          getCurrentExamUseCase: Get.find(),
          getExamTimerUseCase: Get.find(),
          submitSavedExamAnswersUseCase: Get.find(),
          uploadPendingWrittenImagesUseCase: Get.find(),
          finalizeExamUseCase: Get.find(),
          clearExamLocalDataUseCase: Get.find(),
          finishExamUseCase: Get.find(),
          lockExamSessionUseCase: Get.find(),
          reportSecurityViolationUseCase: Get.find(),
          examRunContext: Get.find<ExamRunContext>(),
        ),
        permanent: true,
      );
    }
    Get.lazyPut(
      () => FillBlankExamController(
        getFillBlankQuestionsUseCase: Get.find(),
        saveFillBlankAnswerUseCase: Get.find(),
        getFillBlankProgressUseCase: Get.find(),
      ),
    );
  }
}

class WrittenExamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => WrittenExamController(
        sessionController: Get.find<ExamSessionController>(),
        addWrittenImageUseCase: Get.find(),
        deleteWrittenImageUseCase: Get.find(),
        getWrittenImagesUseCase: Get.find(),
        uploadDescriptiveAnswerImageUseCase: Get.find(),
        saveDescriptiveDraftUseCase: Get.find(),
        markWrittenImageUploadedUseCase: Get.find(),
      ),
    );
  }
}

class FinishExamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => FinishExamController(
        Get.find<StopSecurityWatchdogUseCase>(),
        Get.find<StopExamVpnLockdownUseCase>(),
        Get.find<ClearSessionUseCase>(),
        Get.find<ClearExamLocalDataUseCase>(),
        Get.find<ExamRunContext>(),
        Get.find<SetOnboardingFlagUseCase>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}

class ViolationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ViolationController(
        Get.find<SubmitExamWithPendingUploadsUseCase>(),
        Get.find<CheckConnectivityUseCase>(),
        Get.find<ObserveConnectivityUseCase>(),
        Get.find<StopExamVpnLockdownUseCase>(),
        Get.find<AppLifecycleService>(),
        Get.find<AppLogger>(),
      ),
    );
  }
}
