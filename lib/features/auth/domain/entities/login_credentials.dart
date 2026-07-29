import 'package:equatable/equatable.dart';

class LoginCredentials extends Equatable {
  const LoginCredentials({
    required this.rollNumber,
    required this.batchPassword,
  });

  final String rollNumber;
  final String batchPassword;

  @override
  List<Object?> get props => [rollNumber, batchPassword];
}
