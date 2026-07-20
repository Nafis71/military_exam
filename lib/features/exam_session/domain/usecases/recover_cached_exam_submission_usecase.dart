import '../../../../core/utils/result.dart';
import '../entities/cached_exam_recovery_result.dart';
import 'submit_exam_with_pending_uploads_usecase.dart';

class RecoverCachedExamSubmissionUseCase {
  RecoverCachedExamSubmissionUseCase(this._submitExamWithPendingUploadsUseCase);

  final SubmitExamWithPendingUploadsUseCase _submitExamWithPendingUploadsUseCase;

  Future<Result<CachedExamRecoveryResult>> call() =>
      _submitExamWithPendingUploadsUseCase();
}
