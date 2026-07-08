import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../features/security_gate/domain/usecases/handle_security_violation_usecase.dart';
import '../../features/security_gate/domain/usecases/observe_airplane_mode_usecase.dart';
import '../../features/security_gate/domain/usecases/observe_connectivity_usecase.dart';
import '../../features/security_gate/domain/repositories/security_repository.dart';
import '../../shared/domain/entities/exam_entities.dart';
import '../../shared/domain/enums/exam_enums.dart';
import '../constants/app_constants.dart';
import '../logging/app_logger.dart';
import '../logging/log_event.dart';
import 'app_lifecycle_service.dart';
import 'exam_connectivity_alert_service.dart';
import 'screen_security_service.dart';

class SecurityPolicy {
  const SecurityPolicy({
    this.requireAirplaneMode = true,
    this.monitorLifecycle = true,
    this.preventScreenCapture = true,
    this.monitoredPhases = const [ExamPhase.mcq, ExamPhase.written],
    this.pollInterval = AppConstants.securityPollInterval,
    this.lifecycleViolationGracePeriod =
        AppConstants.lifecycleViolationGracePeriod,
  });

  final bool requireAirplaneMode;
  final bool monitorLifecycle;

  /// Uses [screen_security] to block screenshots and screen recording.
  final bool preventScreenCapture;

  final List<ExamPhase> monitoredPhases;
  final Duration pollInterval;

  /// Grace period before [AppLifecycleState.paused] or [AppLifecycleState.hidden]
  /// triggers a violation. Set to [Duration.zero] to disable.
  final Duration lifecycleViolationGracePeriod;

  bool appliesTo(ExamPhase phase) => monitoredPhases.contains(phase);
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
    this._logger,
  );

  final SecurityRepository _repository;
  final ObserveAirplaneModeUseCase _observeAirplaneMode;
  final ObserveConnectivityUseCase _observeConnectivity;
  final ExamConnectivityAlertService _connectivityAlertService;
  final HandleSecurityViolationUseCase _handleViolation;
  final AppLifecycleService _lifecycleService;
  final ScreenSecurityService _screenSecurityService;
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

    if (policy.preventScreenCapture) {
      await _screenSecurityService.enable();
    }

    if (policy.requireAirplaneMode) {
      _listenAirplaneMode();
      _listenConnectivity();
      _startAirplaneModePolling(policy.pollInterval);
    }

    if (policy.monitorLifecycle) {
      _listenLifecycle();
    }
  }

  Future<void> stop() async {
    if (!_running) return;

    _pollTimer?.cancel();
    _pollTimer = null;
    _cancelLifecycleGraceTimer();

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    await _screenSecurityService.disable();
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
    });
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
      _phase == ExamPhase.mcq || _phase == ExamPhase.written;

  Future<void> _onViolation(ViolationType type) async {
    if (_violationHandled || !_shouldMonitorCurrentPhase()) return;
    if (_cameraCaptureActive) return;

    _violationHandled = true;
    _cancelLifecycleGraceTimer();
    await stop();

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
