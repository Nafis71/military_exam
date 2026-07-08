import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../../../shared/domain/enums/exam_enums.dart';
import '../../domain/repositories/penalty_repository.dart';
import '../datasources/exam_local_datasource.dart';

class PenaltyRepositoryImpl implements PenaltyRepository {
  PenaltyRepositoryImpl(this._localDataSource);

  final ExamLocalDataSource _localDataSource;

  static const _lockableViolations = {
    ViolationType.screenshotTaken,
    ViolationType.screenRecordingDetected,
    ViolationType.appBackgrounded,
    ViolationType.appMinimized,
    ViolationType.airplaneModeDisabled,
    ViolationType.rootedDevice,
    ViolationType.jailbreakDetected,
    ViolationType.developerModeEnabled,
  };

  @override
  Future<Result<PenaltyDecision>> evaluateViolation(
    SecurityViolation violation,
  ) async {
    final shouldLock = _lockableViolations.contains(violation.type);
    return Success(
      PenaltyDecision(
        isLocked: shouldLock,
        message: shouldLock
            ? violation.type.displayMessage
            : '${AppStrings.violationRecorded}: ${violation.type.displayMessage}',
      ),
    );
  }

  @override
  Future<Result<ExamLockState>> getLockState(String sessionId) =>
      _localDataSource.readLockState();

  @override
  Future<Result<void>> persistLockState(ExamLockState state) =>
      _localDataSource.setExamLocked(
        state.isLocked,
        reason: state.reason,
      );
}
