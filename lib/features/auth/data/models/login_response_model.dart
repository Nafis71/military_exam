import '../../../../shared/domain/entities/exam_entities.dart';

class LoginResponseModel {
  const LoginResponseModel({
    required this.token,
    required this.sessionId,
    required this.examineeId,
    required this.examineeName,
    required this.expiresAt,
  });

  final String token;
  final String sessionId;
  final String examineeId;
  final String examineeName;
  final DateTime expiresAt;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'] as String,
      sessionId: json['session_id'] as String,
      examineeId: json['examinee_id'] as String,
      examineeName: json['examinee_name'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  AuthSession toEntity() {
    return AuthSession(
      token: token,
      sessionId: sessionId,
      examinee: Examinee(id: examineeId, name: examineeName),
      expiresAt: expiresAt,
    );
  }
}
