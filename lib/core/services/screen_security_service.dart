import 'package:screen_security/screen_security.dart';

import '../logging/app_logger.dart';
import '../logging/log_event.dart';

/// Wraps [screen_security] to prevent screenshots and screen recording.
///
/// See: https://pub.dev/packages/screen_security
class ScreenSecurityService {
  ScreenSecurityService(this._logger) : _screenSecurity = ScreenSecurity();

  final AppLogger _logger;
  final ScreenSecurity _screenSecurity;
  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> enable() async {
    if (_enabled) return;
    await _screenSecurity.enable();
    _enabled = true;
    _logger.logEvent(
      const LogEvent(
        category: LogCategory.security,
        type: LogEventType.lifecycleChange,
        message: 'Screen capture prevention enabled',
      ),
    );
  }

  Future<void> disable() async {
    if (!_enabled) return;
    await _screenSecurity.disable();
    _enabled = false;
    _logger.logEvent(
      const LogEvent(
        category: LogCategory.security,
        type: LogEventType.lifecycleChange,
        message: 'Screen capture prevention disabled',
      ),
    );
  }
}
