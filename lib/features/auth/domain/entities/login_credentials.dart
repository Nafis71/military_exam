import 'package:equatable/equatable.dart';

class LoginCredentials extends Equatable {
  const LoginCredentials({
    required this.district,
    required this.rollNumber,
  });

  final String district;
  final String rollNumber;

  @override
  List<Object?> get props => [district, rollNumber];
}
