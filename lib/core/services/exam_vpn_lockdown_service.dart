import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/deployment.dart';
import '../logging/app_logger.dart';

enum VpnLockdownEvent {
  disconnected,
  permissionDenied,
}

/// Wraps native sinkhole VPN (exam app bypassed, other apps blocked).
class ExamVpnLockdownService {
  ExamVpnLockdownService(this._logger);

  static const _methodChannel = MethodChannel('com.example.military_exam/vpn');
  static const _eventChannel = EventChannel('com.example.military_exam/vpn_events');

  final AppLogger _logger;
  StreamSubscription<dynamic>? _eventSubscription;
  final _eventController = StreamController<VpnLockdownEvent>.broadcast();

  Stream<VpnLockdownEvent> get events => _eventController.stream;

  bool _isActive = false;

  bool get isActive => _isActive;

  bool get _isNoOp => Deployment.instance.isDemo;

  Future<void> initialize() async {
    if (_isNoOp) return;
    await _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (Object error) {
        if (kDebugMode) {
          _logger.error('VPN event stream error', error: error);
        }
      },
    );
  }

  void _onNativeEvent(dynamic event) {
    if (event is! String) return;
    switch (event) {
      case 'disconnected':
        _isActive = false;
        _eventController.add(VpnLockdownEvent.disconnected);
      case 'permissionDenied':
        _eventController.add(VpnLockdownEvent.permissionDenied);
    }
  }

  /// Returns true when user granted VPN consent (Android prepare intent).
  Future<bool> prepare() async {
    if (_isNoOp) return true;
    try {
      final result = await _methodChannel.invokeMethod<bool>('prepare');
      return result ?? false;
    } on PlatformException catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error('VPN prepare failed', error: error, stackTrace: stackTrace);
      }
      return false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error('VPN prepare failed', error: error, stackTrace: stackTrace);
      }
      return false;
    }
  }

  Future<bool> startLockdown() async {
    if (_isNoOp) {
      _isActive = true;
      return true;
    }
    try {
      final result = await _methodChannel.invokeMethod<bool>('startVpn');
      _isActive = result ?? false;
      return _isActive;
    } on PlatformException catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error('VPN start failed', error: error, stackTrace: stackTrace);
      }
      _isActive = false;
      return false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error('VPN start failed', error: error, stackTrace: stackTrace);
      }
      _isActive = false;
      return false;
    }
  }

  Future<bool> ensureActive() async {
    if (_isNoOp) return true;
    if (_isActive) {
      final active = await isActiveNative();
      _isActive = active;
      if (active) return true;
    }
    final prepared = await prepare();
    if (!prepared) return false;
    return startLockdown();
  }

  Future<bool> isActiveNative() async {
    if (_isNoOp) return true;
    try {
      final result = await _methodChannel.invokeMethod<bool>('isActive');
      _isActive = result ?? false;
      return _isActive;
    } on PlatformException catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error('VPN isActive failed', error: error, stackTrace: stackTrace);
      }
      return false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error('VPN isActive failed', error: error, stackTrace: stackTrace);
      }
      return false;
    }
  }

  Future<void> stopLockdown() async {
    if (_isNoOp) {
      _isActive = false;
      return;
    }
    try {
      await _methodChannel.invokeMethod<void>('stopVpn');
    } on PlatformException catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error('VPN stop failed', error: error, stackTrace: stackTrace);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.error('VPN stop failed', error: error, stackTrace: stackTrace);
      }
    } finally {
      _isActive = false;
    }
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _eventController.close();
  }
}
