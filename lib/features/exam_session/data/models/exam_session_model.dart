import '../../../../shared/domain/entities/exam_entities.dart';

class ExamSessionModel {
  const ExamSessionModel({
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

  factory ExamSessionModel.fromJson(Map<String, dynamic> json) {
    return ExamSessionModel(
      sessionId: json['session_id'] as String,
      examineeId: json['examinee_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      durationMinutes: json['duration_minutes'] as int,
      isLocked: json['is_locked'] as bool? ?? false,
      currentPhase: json['current_phase'] as String? ?? 'mcq',
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'examinee_id': examineeId,
        'started_at': startedAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'is_locked': isLocked,
        'current_phase': currentPhase,
      };

  ExamSession toEntity() {
    return ExamSession(
      sessionId: sessionId,
      examineeId: examineeId,
      startedAt: startedAt,
      durationMinutes: durationMinutes,
      isLocked: isLocked,
      currentPhase: currentPhase,
    );
  }

  factory ExamSessionModel.fromEntity(ExamSession entity) {
    return ExamSessionModel(
      sessionId: entity.sessionId,
      examineeId: entity.examineeId,
      startedAt: entity.startedAt,
      durationMinutes: entity.durationMinutes,
      isLocked: entity.isLocked,
      currentPhase: entity.currentPhase,
    );
  }
}
