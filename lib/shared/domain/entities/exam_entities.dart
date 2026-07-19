import 'package:equatable/equatable.dart';

import '../enums/exam_enums.dart';

class Examinee extends Equatable {
  const Examinee({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class AuthSession extends Equatable {
  const AuthSession({
    required this.token,
    required this.sessionId,
    required this.examinee,
    required this.expiresAt,
  });

  final String token;
  final String sessionId;
  final Examinee examinee;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [token, sessionId, examinee, expiresAt];
}

class ExamEligibility extends Equatable {
  const ExamEligibility({
    required this.isEligible,
    required this.isExamActive,
    required this.isLocked,
    this.message,
  });

  final bool isEligible;
  final bool isExamActive;
  final bool isLocked;
  final String? message;

  @override
  List<Object?> get props => [isEligible, isExamActive, isLocked, message];
}

class ExamSession extends Equatable {
  const ExamSession({
    required this.sessionId,
    required this.examineeId,
    required this.startedAt,
    required this.durationMinutes,
    required this.isLocked,
    required this.currentPhase,
  });

  final String sessionId;
  final String examineeId;
  final DateTime startedAt;
  final int durationMinutes;
  final bool isLocked;
  final String currentPhase;

  Duration get remaining =>
      startedAt.add(Duration(minutes: durationMinutes)).difference(DateTime.now());

  @override
  List<Object?> get props =>
      [sessionId, examineeId, startedAt, durationMinutes, isLocked, currentPhase];
}

class ExamTimer extends Equatable {
  const ExamTimer({required this.remainingSeconds});

  final int remainingSeconds;

  String get formatted {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [remainingSeconds];
}

class McqOption extends Equatable {
  const McqOption({required this.id, required this.label});

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}

class McqQuestion extends Equatable {
  const McqQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.index,
    required this.total,
  });

  final String id;
  final String question;
  final List<McqOption> options;
  final int index;
  final int total;

  @override
  List<Object?> get props => [id, question, options, index, total];
}

class McqAnswer extends Equatable {
  const McqAnswer({
    required this.questionId,
    required this.selectedOptionId,
    required this.isFinal,
  });

  final String questionId;
  final String selectedOptionId;
  final bool isFinal;

  @override
  List<Object?> get props => [questionId, selectedOptionId, isFinal];
}

class WrittenQuestion extends Equatable {
  const WrittenQuestion({
    required this.id,
    required this.index,
    required this.text,
  });

  final String id;
  final int index;
  final String text;

  @override
  List<Object?> get props => [id, index, text];
}

class WrittenAnswerImage extends Equatable {
  const WrittenAnswerImage({
    required this.localId,
    required this.localPath,
    required this.questionId,
    this.remoteId,
    this.uploadStatus = ImageUploadStatus.localOnly,
    this.uploadProgress = 0,
  });

  final String localId;
  final String localPath;
  final String questionId;
  final String? remoteId;
  final ImageUploadStatus uploadStatus;
  final double uploadProgress;

  WrittenAnswerImage copyWith({
    String? questionId,
    String? remoteId,
    ImageUploadStatus? uploadStatus,
    double? uploadProgress,
  }) {
    return WrittenAnswerImage(
      localId: localId,
      localPath: localPath,
      questionId: questionId ?? this.questionId,
      remoteId: remoteId ?? this.remoteId,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  @override
  List<Object?> get props =>
      [localId, localPath, questionId, remoteId, uploadStatus, uploadProgress];
}

class UploadProgress extends Equatable {
  const UploadProgress({
    required this.imageId,
    required this.progress,
    required this.status,
  });

  final String imageId;
  final double progress;
  final ImageUploadStatus status;

  @override
  List<Object?> get props => [imageId, progress, status];
}

class SubmissionReceipt extends Equatable {
  const SubmissionReceipt({
    required this.submissionId,
    required this.submittedAt,
    required this.message,
  });

  final String submissionId;
  final DateTime submittedAt;
  final String message;

  @override
  List<Object?> get props => [submissionId, submittedAt, message];
}

class DeviceIntegrityStatus extends Equatable {
  const DeviceIntegrityStatus({
    required this.isRooted,
    required this.isJailbroken,
    required this.isDeveloperModeEnabled,
    required this.isHooked,
    required this.isDebuggerAttached,
    required this.isEmulator,
    required this.hasTestKeys,
    required this.isIntegrityViolated,
    required this.isEnvironmentSpoofed,
    required this.isCustomRom,
    required this.checkFailed,
    required this.isCompromised,
  });

  final bool isRooted;
  final bool isJailbroken;
  final bool isDeveloperModeEnabled;
  final bool isHooked;
  final bool isDebuggerAttached;
  final bool isEmulator;
  final bool hasTestKeys;
  final bool isIntegrityViolated;
  final bool isEnvironmentSpoofed;
  final bool isCustomRom;
  final bool checkFailed;
  final bool isCompromised;

  bool get isRaspClean =>
      !isRooted &&
      !isJailbroken &&
      !isHooked &&
      !isDebuggerAttached &&
      !isEmulator &&
      !hasTestKeys &&
      !isIntegrityViolated &&
      !checkFailed;

  factory DeviceIntegrityStatus.checkFailed() => const DeviceIntegrityStatus(
        isRooted: true,
        isJailbroken: true,
        isDeveloperModeEnabled: true,
        isHooked: true,
        isDebuggerAttached: true,
        isEmulator: true,
        hasTestKeys: true,
        isIntegrityViolated: true,
        isEnvironmentSpoofed: true,
        isCustomRom: true,
        checkFailed: true,
        isCompromised: true,
      );

  @override
  List<Object?> get props => [
        isRooted,
        isJailbroken,
        isDeveloperModeEnabled,
        isHooked,
        isDebuggerAttached,
        isEmulator,
        hasTestKeys,
        isIntegrityViolated,
        isEnvironmentSpoofed,
        isCustomRom,
        checkFailed,
        isCompromised,
      ];
}

class AirplaneModeStatus extends Equatable {
  const AirplaneModeStatus({required this.isEnabled});

  final bool isEnabled;

  @override
  List<Object?> get props => [isEnabled];
}

class ConnectivityStatus extends Equatable {
  const ConnectivityStatus({required this.isOnline});

  final bool isOnline;

  bool get isOffline => !isOnline;

  @override
  List<Object?> get props => [isOnline];
}

class SecurityViolation extends Equatable {
  const SecurityViolation({
    required this.type,
    required this.occurredAt,
    required this.phase,
    required this.sessionId,
    required this.platform,
  });

  final ViolationType type;
  final DateTime occurredAt;
  final ExamPhase phase;
  final String? sessionId;
  final String platform;

  @override
  List<Object?> get props => [type, occurredAt, phase, sessionId, platform];
}

class PenaltyDecision extends Equatable {
  const PenaltyDecision({
    required this.isLocked,
    required this.message,
  });

  final bool isLocked;
  final String message;

  @override
  List<Object?> get props => [isLocked, message];
}

class ExamLockState extends Equatable {
  const ExamLockState({
    required this.isLocked,
    this.reason,
    this.lockedAt,
  });

  final bool isLocked;
  final String? reason;
  final DateTime? lockedAt;

  @override
  List<Object?> get props => [isLocked, reason, lockedAt];
}
