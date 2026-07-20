import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

class ViolationSubmitOutcome {
  const ViolationSubmitOutcome({
    required this.answersSubmitted,
    required this.submissionPending,
    required this.stopAutoRetry,
  });

  final bool answersSubmitted;
  final bool submissionPending;
  final bool stopAutoRetry;

  static const none = ViolationSubmitOutcome(
    answersSubmitted: false,
    submissionPending: false,
    stopAutoRetry: false,
  );

  static const success = ViolationSubmitOutcome(
    answersSubmitted: true,
    submissionPending: false,
    stopAutoRetry: false,
  );
}

ViolationSubmitOutcome resolveViolationSubmitOutcome(
  Result<SubmissionReceipt> result,
) {
  switch (result) {
    case Success():
      return ViolationSubmitOutcome.success;
    case ErrorResult(:final failure):
      if (failure is NetworkFailure) {
        return const ViolationSubmitOutcome(
          answersSubmitted: false,
          submissionPending: true,
          stopAutoRetry: false,
        );
      }
      if (failure is UploadFailure &&
          failure.message == AppStrings.imageFileNotFound) {
        return const ViolationSubmitOutcome(
          answersSubmitted: false,
          submissionPending: false,
          stopAutoRetry: true,
        );
      }
      if (failure is UploadFailure) {
        return const ViolationSubmitOutcome(
          answersSubmitted: false,
          submissionPending: true,
          stopAutoRetry: false,
        );
      }
      return const ViolationSubmitOutcome(
        answersSubmitted: false,
        submissionPending: false,
        stopAutoRetry: true,
      );
  }
}
