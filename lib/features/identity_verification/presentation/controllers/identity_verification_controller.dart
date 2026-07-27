import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/models/camera_permission_gate_status.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/services/identity_verification_session.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_error_toast.dart';
import '../../domain/usecases/verify_candidate_qr_usecase.dart';
import '../widgets/identity_qr_scanner_page.dart';

enum IdentityVerificationFlowStatus {
  awaitingPermission,
  readyToScan,
  verifying,
  verified,
}

class IdentityVerificationController extends GetxController {
  IdentityVerificationController(
    this._cameraPermissionService,
    this._verifyCandidateQr,
    this._verificationSession,
    this._examRunContext,
    this._lifecycleService,
    this._logger,
  );

  final CameraPermissionService _cameraPermissionService;
  final VerifyCandidateQrUseCase _verifyCandidateQr;
  final IdentityVerificationSession _verificationSession;
  final ExamRunContext _examRunContext;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final Rx<CameraPermissionGateStatus> permissionStatus =
      CameraPermissionGateStatus.checking.obs;
  final Rx<IdentityVerificationFlowStatus> flowStatus =
      IdentityVerificationFlowStatus.awaitingPermission.obs;
  final RxBool isRequestingPermission = false.obs;
  final RxBool isScannerOpen = false.obs;
  final RxBool isNavigating = false.obs;

  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;
  bool _isProcessingQr = false;

  bool get showPermissionGate =>
      permissionStatus.value != CameraPermissionGateStatus.granted ||
      flowStatus.value == IdentityVerificationFlowStatus.awaitingPermission;

  @override
  void onInit() {
    super.onInit();
    if (_examRunContext.isOnboardingDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(AppRoutes.candidateDashboard);
      });
      return;
    }

    unawaited(_checkPermission());
    _listenForResume();
  }

  @override
  void onClose() {
    unawaited(_lifecycleSubscription?.cancel());
    super.onClose();
  }

  void _listenForResume() {
    _lifecycleSubscription = _lifecycleService.lifecycleStream
        .where((state) => state == AppLifecycleState.resumed)
        .listen((_) => unawaited(_checkPermission()));
  }

  Future<void> _checkPermission() async {
    if (isClosed) return;

    permissionStatus.value = CameraPermissionGateStatus.checking;

    if (await _cameraPermissionService.isGranted) {
      permissionStatus.value = CameraPermissionGateStatus.granted;
      if (flowStatus.value == IdentityVerificationFlowStatus.awaitingPermission) {
        // Stay on permission gate until user taps Continue.
      }
      return;
    }

    if (flowStatus.value == IdentityVerificationFlowStatus.verified) {
      _verificationSession.clear();
    }
    flowStatus.value = IdentityVerificationFlowStatus.awaitingPermission;

    if (await _cameraPermissionService.isPermanentlyDenied) {
      permissionStatus.value = CameraPermissionGateStatus.permanentlyDenied;
      return;
    }

    permissionStatus.value = CameraPermissionGateStatus.denied;
  }

  Future<void> requestPermission() async {
    isRequestingPermission.value = true;
    try {
      final granted = await _cameraPermissionService.ensureGranted();
      if (isClosed) return;

      if (granted) {
        permissionStatus.value = CameraPermissionGateStatus.granted;
        return;
      }

      if (await _cameraPermissionService.isPermanentlyDenied) {
        permissionStatus.value = CameraPermissionGateStatus.permanentlyDenied;
        return;
      }

      permissionStatus.value = CameraPermissionGateStatus.denied;
    } finally {
      isRequestingPermission.value = false;
    }
  }

  Future<void> openSettings() async {
    final opened = await _cameraPermissionService.openSettings();
    if (!opened && kDebugMode) {
      _logger.error(AppStrings.unableToOpenSettings);
    }
  }

  void onPermissionContinue() {
    if (permissionStatus.value != CameraPermissionGateStatus.granted) return;
    flowStatus.value = IdentityVerificationFlowStatus.readyToScan;
  }

  Future<void> refreshStatus() => _checkPermission();

  Future<void> openScanner() async {
    if (isClosed) return;
    if (flowStatus.value != IdentityVerificationFlowStatus.readyToScan) return;
    if (isScannerOpen.value || _isProcessingQr) return;
    if (!await _cameraPermissionService.isGranted) {
      await _checkPermission();
      return;
    }

    isScannerOpen.value = true;
    try {
      await Get.to<void>(
        () => IdentityQrScannerPage(onDetect: _onQrDetected),
        fullscreenDialog: true,
      );
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error('openScanner failed', error: e, stackTrace: st);
      }
      AppErrorToast.show(AppStrings.qrScannerError);
    } finally {
      if (!isClosed) {
        isScannerOpen.value = false;
      }
    }
  }

  Future<void> _onQrDetected(String rawValue) async {
    if (_isProcessingQr || isClosed) return;
    _isProcessingQr = true;

    if (!isClosed) {
      flowStatus.value = IdentityVerificationFlowStatus.verifying;
    }

    try {
      final result = await _verifyCandidateQr(rawValue);
      if (isClosed) return;

      switch (result) {
        case Success():
          if (kDebugMode) {
            final preview = rawValue.length > 32
                ? '${rawValue.substring(0, 32)}...'
                : rawValue;
            _logger.info('QR identity verified (preview: $preview)');
          }
          _verificationSession.markVerified();
          flowStatus.value = IdentityVerificationFlowStatus.verified;
          if (Get.key.currentState != null && Get.key.currentState!.canPop()) {
            Get.back<void>();
          }
        case ErrorResult():
          AppErrorToast.show(AppStrings.identityVerificationFailed);
          flowStatus.value = IdentityVerificationFlowStatus.readyToScan;
          if (Get.key.currentState != null && Get.key.currentState!.canPop()) {
            Get.back<void>();
          }
      }
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error('_onQrDetected failed', error: e, stackTrace: st);
      }
      if (!isClosed) {
        AppErrorToast.show(AppStrings.somethingWentWrong);
        flowStatus.value = IdentityVerificationFlowStatus.readyToScan;
      }
      if (Get.key.currentState != null && Get.key.currentState!.canPop()) {
        Get.back<void>();
      }
    } finally {
      _isProcessingQr = false;
    }
  }

  Future<void> continueToInstructions() async {
    if (isClosed) return;
    if (flowStatus.value != IdentityVerificationFlowStatus.verified) return;
    if (isNavigating.value) return;

    isNavigating.value = true;
    try {
      await Get.offNamed<void>(AppRoutes.instructions);
    } catch (e, st) {
      if (kDebugMode) {
        _logger.error('continueToInstructions failed', error: e, stackTrace: st);
      }
      AppErrorToast.show(AppStrings.somethingWentWrong);
    } finally {
      if (!isClosed) {
        isNavigating.value = false;
      }
    }
  }
}
