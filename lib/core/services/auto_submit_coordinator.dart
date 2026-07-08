import '../config/api_endpoints.dart';
import '../config/deployment.dart';
import '../logging/app_logger.dart';
import '../logging/log_event.dart';
import '../network/api_client.dart';
import '../../shared/domain/entities/exam_entities.dart';

class AutoSubmitCoordinator {
  AutoSubmitCoordinator(this._apiClient, this._logger);

  final ApiClient _apiClient;
  final AppLogger _logger;

  bool _submitting = false;

  Future<void> submitOnViolation(SecurityViolation violation) async {
    if (_submitting) return;
    _submitting = true;

    _logger.logEvent(
      LogEvent(
        category: LogCategory.security,
        type: LogEventType.violation,
        message: 'Auto-submit triggered',
        data: {
          'type': violation.type.name,
          'sessionId': violation.sessionId,
          'phase': violation.phase.name,
        },
      ),
    );

    await _reportViolation(violation);
    await _autoSubmitExam(violation);
  }

  Future<void> _reportViolation(SecurityViolation violation) async {
    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: violation stored on device only (no API call)');
      return;
    }

    final result = await _apiClient.post<void>(
      ApiEndpoints.securityViolations,
      data: {
        'type': violation.type.name,
        'occurredAt': violation.occurredAt.toIso8601String(),
        'phase': violation.phase.name,
        'sessionId': violation.sessionId,
        'platform': violation.platform,
      },
    );

    if (result.isFailure) {
      _logger.error(
        'Failed to report security violation',
        data: {'message': result.failureOrNull?.message},
      );
    }
  }

  Future<void> _autoSubmitExam(SecurityViolation violation) async {
    if (violation.sessionId == null) return;

    if (Deployment.instance.isDemo) {
      _logger.info('Demo mode: auto-submit handled on device only (no API call)');
      return;
    }

    final result = await _apiClient.post<void>(
      ApiEndpoints.examAutoSubmit,
      data: {
        'sessionId': violation.sessionId,
        'reason': violation.type.name,
        'occurredAt': violation.occurredAt.toIso8601String(),
      },
    );

    if (result.isFailure) {
      _logger.error(
        'Exam auto-submit failed',
        data: {'message': result.failureOrNull?.message},
      );
    }
  }

  void reset() => _submitting = false;
}
