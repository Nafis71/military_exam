import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/exam_run_context.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../repositories/exam_repository.dart';
import '../repositories/penalty_repository.dart';

class ReportSecurityViolationUseCase {
  ReportSecurityViolationUseCase(
    this._examRepository,
    this._penaltyRepository,
    this._examRunContext,
  );

  final ExamRepository _examRepository;
  final PenaltyRepository _penaltyRepository;
  final ExamRunContext _examRunContext;

  Future<Result<PenaltyDecision>> call(SecurityViolation violation) async {
    if (_examRunContext.isOnboardingDemo) {
      return Success(
        PenaltyDecision(
          isLocked: false,
          message: AppStrings.violationRecorded,
        ),
      );
    }

    final reportResult = await _examRepository.reportViolation(violation);
    if (reportResult is ErrorResult<void>) {
      return ErrorResult(reportResult.failure);
    }

    final penaltyResult =
        await _penaltyRepository.evaluateViolation(violation);
    if (penaltyResult is ErrorResult<PenaltyDecision>) {
      return penaltyResult;
    }

    final decision = (penaltyResult as Success<PenaltyDecision>).data;
    if (decision.isLocked && violation.sessionId != null) {
      final lockState = ExamLockState(
        isLocked: true,
        reason: decision.message,
        lockedAt: DateTime.now(),
      );
      await _penaltyRepository.persistLockState(lockState);
      await _examRepository.lockSession(
        violation.sessionId!,
        decision.message,
      );
    }

    return Success(decision);
  }
}
