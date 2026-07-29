import '../../domain/entities/login_credentials.dart';

class LoginRequestModel extends LoginCredentials {
  const LoginRequestModel({
    required super.rollNumber,
    required super.batchPassword,
  });

  factory LoginRequestModel.fromCredentials(LoginCredentials credentials) {
    return LoginRequestModel(
      rollNumber: credentials.rollNumber,
      batchPassword: credentials.batchPassword,
    );
  }

  Map<String, dynamic> toJson() => {
        'roll_number': rollNumber,
        'batch_password': batchPassword,
      };
}
