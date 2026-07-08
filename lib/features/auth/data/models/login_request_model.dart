import '../../../../shared/domain/entities/exam_entities.dart';

class LoginRequestModel {
  const LoginRequestModel({
    required this.examineeId,
    required this.password,
  });

  final String examineeId;
  final String password;

  factory LoginRequestModel.fromCredentials(LoginCredentials credentials) {
    return LoginRequestModel(
      examineeId: credentials.examineeId,
      password: credentials.password,
    );
  }

  Map<String, dynamic> toJson() => {
        'examinee_id': examineeId,
        'password': password,
      };
}
