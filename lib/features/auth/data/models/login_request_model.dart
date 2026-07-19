import '../../domain/entities/login_credentials.dart';

class LoginRequestModel extends LoginCredentials {
  const LoginRequestModel({
    required super.district,
    required super.rollNumber,
  });

  factory LoginRequestModel.fromCredentials(LoginCredentials credentials) {
    return LoginRequestModel(
      district: credentials.district,
      rollNumber: credentials.rollNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'district': district,
        'roll_number': rollNumber,
      };
}
