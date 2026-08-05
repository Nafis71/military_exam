import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../features/security_gate/domain/usecases/handle_security_violation_usecase.dart';
import '../../features/security_gate/domain/usecases/observe_airplane_mode_usecase.dart';
import '../../features/security_gate/domain/usecases/observe_connectivity_usecase.dart';
import '../../features/security_gate/domain/repositories/security_repository.dart';
import '../../shared/domain/entities/exam_entities.dart';
import '../../shared/domain/enums/exam_enums.dart';
import '../config/deployment.dart';
import '../constants/app_constants.dart';
import '../logging/app_logger.dart';
import '../logging/log_event.dart';
import 'app_lifecycle_service.dart';
import 'exam_connectivity_alert_service.dart';
import 'exam_vpn_lockdown_service.dart';
import 'screen_security_service.dart';
import 'security_service.dart';

class SecurityPolicy {
  const SecurityPolicy({
    this.requireAirplaneMode = true,
    this.requireVpnLockdown = false,
    this.monitorLifecycle = true,
    this.preventScreenCapture = true,
    this.monitoredPhases = const [
      ExamPhase.mcq,
      ExamPhase.fillBlank,
      ExamPhase.written,
    ],
    this.pollInterval = AppConstants.securityPollInterval,
    this.lifecycleViolationGracePeriod =
        AppConstants.lifecycleViolationGracePeriod,
  });

  final bool requireAirplaneMode;
  final bool requireVpnLockdown;
  final bool monitorLifecycle;

  /// Uses [screen_security] to block screenshots and screen recording.
  final bool preventScreenCapture;

  final List<ExamPhase> monitoredPhases;
  final Duration pollInterval;

  /// Grace period before [AppLifecycleState.paused] or [AppLifecycleState.hidden]
  /// triggers a violation. Set to [Duration.zero] to disable.
  final Duration lifecycleViolationGracePeriod;

  bool appliesTo(ExamPhase phase) => monitoredPhases.contains(phase);

  SecurityPolicy copyWith({
    bool? requireAirplaneMode,
    bool? requireVpnLockdown,
    bool? monitorLifecycle,
    bool? preventScreenCapture,
    List<ExamPhase>? monitoredPhases,
    Duration? pollInterval,
    Duration? lifecycleViolationGracePeriod,
  }) {
    return SecurityPolicy(
      requireAirplaneMode: requireAirplaneMode ?? this.requireAirplaneMode,
      requireVpnLockdown: requireVpnLockdown ?? this.requireVpnLockdown,
      monitorLifecycle: monitorLifecycle ?? this.monitorLifecycle,
      preventScreenCapture:
          preventScreenCapture ?? this.preventScreenCapture,
      monitoredPhases: monitoredPhases ?? this.monitoredPhases,
      pollInterval: pollInterval ?? this.pollInterval,
      lifecycleViolationGracePeriod: lifecycleViolationGracePeriod ??
          this.lifecycleViolationGracePeriod,
    );
  }
}

class SecurityWatchdogService {
  SecurityWatchdogService(
    this._repository,
    this._observeAirplaneMode,
    this._observeConnectivity,
    this._connectivityAlertService,
    this._handleViolation,
    this._lifecycleService,
    this._screenSecurityService,
    this._vpnLockdownService,
    this._logger,
  );

  final SecurityRepository _repository;
  final ObserveAirplaneModeUseCase _observeAirplaneMode;
  final ObserveConnectivityUseCase _observeConnectivity;
  final ExamConnectivityAlertService _connectivityAlertService;
  final HandleSecurityViolationUseCase _handleViolation;
  final AppLifecycleService _lifecycleService;
  final ScreenSecurityService _screenSecurityService;
  final ExamVpnLockdownService _vpnLockdownService;
  final AppLogger _logger;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _pollTimer;
  Timer? _lifecycleGraceTimer;
  ViolationType? _pendingLifecycleViolation;

  SecurityPolicy? _policy;
  ExamPhase _phase = ExamPhase.securityGate;
  String? _sessionId;
  bool _running = false;
  bool _violationHandled = false;
  bool _cameraCaptureActive = false;

  bool get isRunning => _running;

  bool _shouldPreventScreenCapture(SecurityPolicy policy) =>
      Deployment.instance.preventScreenCapture && policy.preventScreenCapture;

  Future<void> _syncScreenCapture(SecurityPolicy policy) async {
    if (_shouldPreventScreenCapture(policy)) {
      await _screenSecurityService.enable();
      return;
    }
    await _screenSecurityService.applyDeploymentPolicy();
  }

  /// Ignores lifecycle violations while in-app camera capture is in progress.
  void setCameraCaptureActive(bool active) {
    _cameraCaptureActive = active;
    if (active) {
      _cancelLifecycleGraceTimer();
    }
  }

  Future<void> start({
    required SecurityPolicy policy,
    required ExamPhase phase,
    String? sessionId,
  }) async {
    if (_running) {
      _policy = policy;
      _phase = phase;
      _sessionId = sessionId;
      await _syncScreenCapture(policy);
      return;
    }

    _policy = policy;
    _phase = phase;
    _sessionId = sessionId;
    _running = true;
    _violationHandled = false;
    _cameraCaptureActive = false;
    _handleViolation.reset();
    _connectivityAlertService.reset();

    _logger.logEvent(
      LogEvent(
        category: LogCategory.security,
        type: LogEventType.lifecycleChange,
        message: 'Security watchdog started',
        data: {'phase': phase.name, 'sessionId': sessionId},
      ),
    );

    await _syncScreenCapture(policy);

    if (policy.requireAirplaneMode) {
      _listenAirplaneMode();
      _listenConnectivity();
      _startAirplaneModePolling(policy.pollInterval);
    }

    if (policy.requireVpnLockdown) {
      _listenVpnDisconnect();
    }

    if (policy.monitorLifecycle) {
      _listenLifecycle();
    }
  }

  Future<void> stop({bool releaseVpn = true}) async {
    if (!_running) {
      if (releaseVpn) {
        await _vpnLockdownService.stopLockdown();
      }
      return;
    }

    _pollTimer?.cancel();
    _pollTimer = null;
    _cancelLifecycleGraceTimer();

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    await _screenSecurityService.disable();
    if (releaseVpn) {
      await _vpnLockdownService.stopLockdown();
    }
    _connectivityAlertService.reset();

    _running = false;
    _policy = null;
    _cameraCaptureActive = false;

    _logger.logEvent(
      const LogEvent(
        category: LogCategory.security,
        type: LogEventType.lifecycleChange,
        message: 'Security watchdog stopped',
      ),
    );
  }

  void _listenAirplaneMode() {
    final subscription = _observeAirplaneMode().listen(
      (status) {
        if (!status.isEnabled) {
          unawaited(
            _onViolation(ViolationType.airplaneModeDisabled),
          );
        }
      },
      onError: (Object error) {
        _logger.error('Airplane mode stream error', error: error);
      },
    );
    _subscriptions.add(subscription);
  }

  void _listenConnectivity() {
    final subscription = _observeConnectivity().listen(
      _onConnectivityChanged,
      onError: (Object error) {
        _logger.error('Connectivity stream error', error: error);
      },
    );
    _subscriptions.add(subscription);
  }

  void _onConnectivityChanged(ConnectivityStatus status) {
    if (_isActiveExamPhase()) {
      _connectivityAlertService.onConnectivityChanged(status);
      return;
    }
  }

  void _startAirplaneModePolling(Duration interval) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) async {
      await _verifyDeviceIntegrity();

      final airplaneResult = await _repository.checkAirplaneMode();
      final airplane = airplaneResult.dataOrNull;
      if (airplane != null && !airplane.isEnabled) {
        await _onViolation(ViolationType.airplaneModeDisabled);
        return;
      }

      final connectivityResult = await _repository.checkConnectivity();
      final connectivity = connectivityResult.dataOrNull;
      if (connectivity != null) {
        _onConnectivityChanged(connectivity);
      }

      if (_policy?.requireVpnLockdown == true) {
        final vpnActive = await _vpnLockdownService.isActiveNative();
        if (!vpnActive) {
          await _onViolation(ViolationType.vpnDisconnected);
        }
      }
    });
  }

  void _listenVpnDisconnect() {
    final subscription = _vpnLockdownService.events.listen(
      (event) {
        if (event == VpnLockdownEvent.disconnected) {
          unawaited(_onViolation(ViolationType.vpnDisconnected));
        }
      },
      onError: (Object error) {
        _logger.error('VPN event stream error', error: error);
      },
    );
    _subscriptions.add(subscription);
  }

  void _listenLifecycle() {
    final subscription = _lifecycleService.lifecycleStream.listen((state) {
      if (!_shouldMonitorCurrentPhase()) return;
      if (_cameraCaptureActive) return;

      switch (state) {
        case AppLifecycleState.paused:
          _scheduleLifecycleViolation(ViolationType.appBackgrounded);
        case AppLifecycleState.hidden:
          _scheduleLifecycleViolation(ViolationType.appMinimized);
        case AppLifecycleState.resumed:
          _cancelLifecycleGraceTimer();
          unawaited(_verifyDeviceIntegrity());
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
          break;
      }
    });
    _subscriptions.add(subscription);
  }

  void _scheduleLifecycleViolation(ViolationType type) {
    final grace = _policy?.lifecycleViolationGracePeriod ?? Duration.zero;
    if (grace <= Duration.zero) {
      unawaited(_onViolation(type));
      return;
    }

    _cancelLifecycleGraceTimer();
    _pendingLifecycleViolation = type;
    _lifecycleGraceTimer = Timer(grace, () {
      _lifecycleGraceTimer = null;
      final pending = _pendingLifecycleViolation;
      _pendingLifecycleViolation = null;
      if (pending != null) {
        unawaited(_onViolation(pending));
      }
    });
  }

  void _cancelLifecycleGraceTimer() {
    _lifecycleGraceTimer?.cancel();
    _lifecycleGraceTimer = null;
    _pendingLifecycleViolation = null;
  }

  bool _shouldMonitorCurrentPhase() {
    final policy = _policy;
    if (policy == null) return false;
    return policy.appliesTo(_phase);
  }

  bool _isActiveExamPhase() =>
      _phase == ExamPhase.mcq ||
      _phase == ExamPhase.fillBlank ||
      _phase == ExamPhase.written;

  Future<void> _verifyDeviceIntegrity() async {
    if (!_shouldMonitorCurrentPhase()) return;
    if (_violationHandled) return;

    final isSafe = await SecurityService.instance.verifyBeforeSensitiveOp();
    if (!isSafe) {
      await _onViolation(ViolationType.rootedDevice);
    }
  }

  bool _shouldPenalizeViolation(ViolationType type) {
    final policy = _policy;
    if (policy == null) return false;

    switch (type) {
      case ViolationType.vpnDisconnected:
        return policy.requireVpnLockdown;
      case ViolationType.airplaneModeDisabled:
        return policy.requireAirplaneMode;
      default:
        return _shouldMonitorCurrentPhase();
    }
  }

  Future<void> _onViolation(ViolationType type) async {
    if (_violationHandled || !_shouldPenalizeViolation(type)) return;
    if (_cameraCaptureActive) return;

    _violationHandled = true;
    _cancelLifecycleGraceTimer();
    await stop(releaseVpn: false);

    final violation = _handleViolation.buildViolation(
      type: type,
      phase: _phase,
      sessionId: _sessionId,
    );

    _logger.logEvent(
      LogEvent(
        category: LogCategory.security,
        type: LogEventType.violation,
        message: type.displayMessage,
        data: {'type': type.name, 'sessionId': _sessionId},
      ),
    );

    await _handleViolation(violation);
  }
}
