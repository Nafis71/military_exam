import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/app_lifecycle_service.dart';
import '../../../../core/services/exam_vpn_lockdown_service.dart';
import '../routes/security_routes.dart';

enum VpnLockdownGateStatus {
  checking,
  enabled,
  disabled,
  error,
}

class VpnLockdownController extends GetxController {
  VpnLockdownController(
    this._vpnLockdownService,
    this._lifecycleService,
    this._logger,
  );

  final ExamVpnLockdownService _vpnLockdownService;
  final AppLifecycleService _lifecycleService;
  final AppLogger _logger;

  final Rx<VpnLockdownGateStatus> status = VpnLockdownGateStatus.checking.obs;
  final RxBool isActivating = false.obs;

  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;

  @override
  void onInit() {
    super.onInit();
    unawaited(_checkStatus());
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
        .listen((_) => unawaited(_checkStatus()));
  }

  Future<void> _checkStatus() async {
    status.value = VpnLockdownGateStatus.checking;
    try {
      final active = await _vpnLockdownService.isActiveNative();
      status.value =
          active ? VpnLockdownGateStatus.enabled : VpnLockdownGateStatus.disabled;
    } catch (error) {
      status.value = VpnLockdownGateStatus.error;
      _logger.error('${AppStrings.unableToVerifyNetworkLockdown}: $error');
    }
  }

  Future<void> activateLockdown() async {
    if (isActivating.value) return;
    isActivating.value = true;
    status.value = VpnLockdownGateStatus.checking;
    try {
      final prepared = await _vpnLockdownService.prepare();
      if (!prepared) {
        status.value = VpnLockdownGateStatus.disabled;
        return;
      }
      final started = await _vpnLockdownService.startLockdown();
      status.value = started
          ? VpnLockdownGateStatus.enabled
          : VpnLockdownGateStatus.disabled;
    } catch (error) {
      status.value = VpnLockdownGateStatus.error;
      _logger.error('activateLockdown failed', error: error);
    } finally {
      isActivating.value = false;
    }
  }

  Future<void> continueWhenReady() async {
    if (status.value != VpnLockdownGateStatus.enabled) return;
    Get.offNamed(SecurityRoutes.securityGate);
  }

  Future<void> refreshStatus() => _checkStatus();
}
