import '../../../../core/constants/app_strings.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

abstract final class SubmissionReceiptMapper {
  static SubmissionReceipt fromJson(Map<String, dynamic> json) {
    final submissionId = json['submission_id'] as String? ??
        json['id'] as String?;
    final submittedAtRaw = json['submitted_at'] as String?;
    final submittedAt =
        submittedAtRaw != null ? DateTime.tryParse(submittedAtRaw) : null;

    return SubmissionReceipt(
      submissionId: (submissionId != null && submissionId.isNotEmpty)
          ? submissionId
          : 'sub-${DateTime.now().millisecondsSinceEpoch}',
      submittedAt: submittedAt ?? DateTime.now(),
      message: json['message'] as String? ?? AppStrings.submitted,
    );
  }
}
