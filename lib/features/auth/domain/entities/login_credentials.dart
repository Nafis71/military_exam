import 'package:equatable/equatable.dart';

class LoginCredentials extends Equatable {
  const LoginCredentials({
    required this.rollNumber,
    // TODO(backend): add batchPassword when login endpoint supports it.
  });

  final String rollNumber;

  @override
  List<Object?> get props => [rollNumber];
}
