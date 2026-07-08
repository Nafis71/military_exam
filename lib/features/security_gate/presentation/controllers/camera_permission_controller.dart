import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../domain/usecases/complete_security_pre_exam_usecase.dart';

enum CameraPermissionGateStatus {
  checking,
  granted,
  denied,
  permanentlyDenied,
}

class CameraPermissionController extends GetxController {
  CameraPermissionController(
    this._cameraPermissionService,
    this._completePreExam,
    this._lifecycleService,
    this._logger,
  );

  final CameraPermissionService _cameraPermissionService;
  final CompleteSecurityPreExamUseCase _completePreExam;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final Rx<CameraPermissionGateStatus> status =
      CameraPermissionGateStatus.checking.obs;
  final RxBool isRequestingPermission = false.obs;

  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;

  @override
  void onInit() {
    super.onInit();
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
    status.value = CameraPermissionGateStatus.checking;

    if (await _cameraPermissionService.isGranted) {
      status.value = CameraPermissionGateStatus.granted;
      return;
    }

    if (await _cameraPermissionService.isPermanentlyDenied) {
      status.value = CameraPermissionGateStatus.permanentlyDenied;
      return;
    }

    status.value = CameraPermissionGateStatus.denied;
  }

  Future<void> requestPermission() async {
    isRequestingPermission.value = true;
    final granted = await _cameraPermissionService.ensureGranted();
    isRequestingPermission.value = false;

    if (granted) {
      status.value = CameraPermissionGateStatus.granted;
      return;
    }

    if (await _cameraPermissionService.isPermanentlyDenied) {
      status.value = CameraPermissionGateStatus.permanentlyDenied;
      return;
    }

    status.value = CameraPermissionGateStatus.denied;
  }

  Future<void> openSettings() async {
    final opened = await _cameraPermissionService.openSettings();
    if (!opened) {
      _logger.error(AppStrings.unableToOpenSettings);
    }
  }

  Future<void> continueWhenReady() async {
    if (status.value != CameraPermissionGateStatus.granted) return;
    await _completePreExam();
  }

  Future<void> refreshStatus() => _checkPermission();
}
