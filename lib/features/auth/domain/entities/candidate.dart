import 'package:equatable/equatable.dart';

class Candidate extends Equatable {
  const Candidate({
    required this.id,
    required this.fullName,
    required this.district,
    required this.rollNumber,
    required this.status,
  });

  final String id;
  final String fullName;
  final String district;
  final String rollNumber;
  final String status;

  @override
  List<Object?> get props => [id, fullName, district, rollNumber, status];
}
