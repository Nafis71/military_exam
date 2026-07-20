import '../../../../shared/domain/entities/exam_entities.dart';

class ViolationScreenArgs {
  const ViolationScreenArgs({
    this.violation,
    this.answersSubmitted = false,
    this.submissionPending = false,
    this.stopAutoRetry = false,
  });

  final SecurityViolation? violation;
  final bool answersSubmitted;
  final bool submissionPending;
  final bool stopAutoRetry;

  factory ViolationScreenArgs.fromRoute(Object? args) {
    if (args is SecurityViolation) {
      return ViolationScreenArgs(violation: args);
    }
    if (args is! Map) {
      return const ViolationScreenArgs();
    }

    final violationArg = args['violation'];
    final submitted = args['answersSubmitted'];
    final pending = args['submissionPending'];
    final stopRetry = args['stopAutoRetry'];

    return ViolationScreenArgs(
      violation: violationArg is SecurityViolation ? violationArg : null,
      answersSubmitted: submitted is bool ? submitted : false,
      submissionPending: pending is bool ? pending : false,
      stopAutoRetry: stopRetry is bool ? stopRetry : false,
    );
  }
}
