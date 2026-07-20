import '../../../../shared/domain/entities/exam_entities.dart';

class CachedExamRecoveryResult {
  const CachedExamRecoveryResult({
    required this.receipt,
    required this.exam,
  });

  final SubmissionReceipt receipt;
  final CurrentExam exam;
}
