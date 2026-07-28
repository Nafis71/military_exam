import '../../domain/entities/login_credentials.dart';

class LoginRequestModel extends LoginCredentials {
  const LoginRequestModel({
    required super.rollNumber,
  });

  factory LoginRequestModel.fromCredentials(LoginCredentials credentials) {
    return LoginRequestModel(
      rollNumber: credentials.rollNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'roll_number': rollNumber,
        // TODO(backend): add batch_password when endpoint supports it.
      };
}
